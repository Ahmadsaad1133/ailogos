import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/story_record.dart';
import '../models/user_profile.dart';

/// Centralized data store that keeps history and profile state in sync with a
/// remote backend (Supabase/Firestore/Appwrite) while retaining an offline
/// cache and queued writes for eventual consistency.
class UserDataStore {
  UserDataStore({
    required SharedPreferences preferences,
    SupabaseClient? client,
    Connectivity? connectivity,
  })  : _preferences = preferences,
        _client = client,
        _connectivity = connectivity ?? Connectivity();

  static const _schemaVersion = 1;
  static const _schemaKey = 'sync.schema_version';
  static const _historyCacheKey = 'sync.cache.history.v1';
  static const _profileCacheKey = 'sync.cache.profile.v1';
  static const _pendingHistoryKey = 'sync.queue.history.v1';
  static const _pendingProfileKey = 'sync.queue.profile.v1';
  static const _activeUserIdKey = 'sync.user_id.active';
  static const _localUserIdKey = 'sync.user_id.local';

  final SupabaseClient? _client;
  final SharedPreferences _preferences;
  final Connectivity _connectivity;
  late String _userId;
  String? _localUserId;
  List<StoryRecord> _history = [];
  UserProfile? _profile;
  bool _initialised = false;
  bool _isOnline = true;
  StreamSubscription<dynamic>? _connectivitySubscription;

  final _historyController = StreamController<List<StoryRecord>>.broadcast();
  final _profileController = StreamController<UserProfile>.broadcast();

  final List<_PendingHistoryAction> _pendingHistoryQueue = [];
  final List<_PendingProfileUpdate> _pendingProfileQueue = [];

  Future<void> initialise() async {
    if (_initialised) return;

    await _ensureSchema();
    await _loadStateForUser(_userId);

    await _refreshConnectivityStatus();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);

    await _pullRemoteState();
    await _flushPendingQueues();

    _initialised = true;
  }

  Stream<List<StoryRecord>> get historyStream => _historyController.stream;

  Stream<UserProfile> get profileStream => _profileController.stream;

  String get userId => _userId;
  String? get localUserId => _localUserId;

  Future<void> useUser(String userId, {bool persist = true}) async {
    if (!_initialised) {
      await initialise();
    }
    if (userId.isEmpty) return;
    if (_userId == userId) return;
    _userId = userId;
    if (persist) {
      await _preferences.setString(_activeUserIdKey, userId);
    }
    await _loadStateForUser(userId);
    await _pullRemoteState();
    await _flushPendingQueues();
  }

  Future<void> useLocalUser() async {
    if (!_initialised) {
      await initialise();
      return;
    }
    final localId = _localUserId ?? _preferences.getString(_localUserIdKey);
    if (localId == null || localId.isEmpty) {
      return;
    }
    await useUser(localId);
  }
  Future<List<StoryRecord>> fetchHistory() async {
    if (!_initialised) {
      await initialise();
    }
    return List.unmodifiable(_history);
  }

  Future<UserProfile> fetchProfile() async {
    if (!_initialised) {
      await initialise();
    }
    return _profile!;
  }

  Future<void> upsertHistoryRecord(StoryRecord record) async {
    final now = DateTime.now().toUtc();
    final normalized = record.copyWith(updatedAt: now);

    final existingIndex = _history.indexWhere((element) => element.id == normalized.id);
    if (existingIndex >= 0) {
      _history[existingIndex] = normalized;
    } else {
      _history.add(normalized);
    }
    _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _cacheHistory();
    _historyController.add(List.unmodifiable(_history));

    _pendingHistoryQueue.add(_PendingHistoryAction.upsert(normalized));
    await _savePendingHistoryQueue();
    await _flushPendingHistoryQueue();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _cacheHistory();
    _historyController.add(const <StoryRecord>[]);

    _pendingHistoryQueue
      ..clear()
      ..add(_PendingHistoryAction.clear());
    await _savePendingHistoryQueue();
    await _flushPendingHistoryQueue();
  }

  Future<void> updateProfile({
    String? displayName,
    int? accentHex,
    bool? onboardingComplete,
  }) async {
    final now = DateTime.now().toUtc();
    final nextProfile = _profile!.copyWith(
      displayName: displayName,
      accentHex: accentHex,
      onboardingComplete: onboardingComplete,
      updatedAt: now,
    );
    _profile = nextProfile;
    await _cacheProfile();
    _profileController.add(nextProfile);

    final payload = nextProfile.toRemoteJson();
    _pendingProfileQueue.add(_PendingProfileUpdate(payload: payload));
    await _savePendingProfileQueue();
    await _flushPendingProfileQueue();
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _historyController.close();
    await _profileController.close();
  }

  Future<void> _ensureSchema() async {
    final schemaVersion = _preferences.getInt(_schemaKey);
    if (schemaVersion != _schemaVersion) {
      await _clearAllCacheData();
      await _preferences.setInt(_schemaKey, _schemaVersion);
    }

    final storedLocalId = _preferences.getString(_localUserIdKey);
    if (storedLocalId == null || storedLocalId.isEmpty) {
      _localUserId = const Uuid().v4();
      await _preferences.setString(_localUserIdKey, _localUserId!);
    } else {
      _localUserId = storedLocalId;
    }

    final storedActiveId = _preferences.getString(_activeUserIdKey);
    if (storedActiveId == null || storedActiveId.isEmpty) {
      _userId = _localUserId!;
      await _preferences.setString(_activeUserIdKey, _userId);
    } else {
      _userId = storedActiveId;
    }
  }

  Future<void> _clearAllCacheData() async {
    final keys = _preferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_historyCacheKey) ||
          key.startsWith(_profileCacheKey) ||
          key.startsWith(_pendingHistoryKey) ||
          key.startsWith(_pendingProfileKey) ||
          key == _activeUserIdKey ||
          key == _localUserIdKey) {
        await _preferences.remove(key);
      }
    }
  }

  String _keyForUser(String base, String userId) => '$base.$userId';

  Future<void> _loadStateForUser(String userId) async {
    _history = _loadHistoryCache(userId);
    _profile = _loadProfileCache(userId);
    _pendingHistoryQueue
      ..clear()
      ..addAll(_loadPendingHistoryQueue(userId));
    _pendingProfileQueue
      ..clear()
      ..addAll(_loadPendingProfileQueue(userId));

    _historyController.add(List.unmodifiable(_history));
    _profileController.add(_profile!);
  }

  List<StoryRecord> _loadHistoryCache(String userId) {
    final raw = _preferences.getString(_keyForUser(_historyCacheKey, userId));
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final records = StoryRecord.decodeList(raw);
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  UserProfile _loadProfileCache(String userId) {
    final raw = _preferences.getString(_keyForUser(_profileCacheKey, userId));
    if (raw == null || raw.isEmpty) {
      return UserProfile.anonymous(userId);
    }
    try {
      final profile = UserProfile.decode(raw);
      if (profile.userId.isEmpty || profile.userId != userId) {
        return profile.copyWith(userId: userId);
      }
      return profile;
    } catch (_) {
      return UserProfile.anonymous(userId);
    }
  }

  List<_PendingHistoryAction> _loadPendingHistoryQueue(String userId) {
    final raw =
    _preferences.getString(_keyForUser(_pendingHistoryKey, userId));
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_PendingHistoryAction.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<_PendingProfileUpdate> _loadPendingProfileQueue(String userId) {
    final raw =
    _preferences.getString(_keyForUser(_pendingProfileKey, userId));
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_PendingProfileUpdate.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _cacheHistory() async {
    final key = _keyForUser(_historyCacheKey, _userId);
    if (_history.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(
        key,
        StoryRecord.encodeList(_history),
      );
    }
  }

  Future<void> _cacheProfile() async {
    final key = _keyForUser(_profileCacheKey, _userId);
    await _preferences.setString(
      key,
      UserProfile.encode(_profile!),
    );
  }

  Future<void> _savePendingHistoryQueue() async {
    final key = _keyForUser(_pendingHistoryKey, _userId);
    if (_pendingHistoryQueue.isEmpty) {
      await _preferences.remove(key);
      return;
    }
    final payload = jsonEncode(
      _pendingHistoryQueue.map((e) => e.toJson()).toList(),
    );
    await _preferences.setString(key, payload);
  }

  Future<void> _savePendingProfileQueue() async {

    final key = _keyForUser(_pendingHistoryKey, _userId);
    if (_pendingProfileQueue.isEmpty) {
      await _preferences.remove(key);
      return;
    }
    final payload = jsonEncode(
      _pendingProfileQueue.map((e) => e.toJson()).toList(),
    );
    await _preferences.setString(key, payload);
  }

  Future<void> _refreshConnectivityStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _isOnlineFromResult(result);
    } catch (_) {
      _isOnline = true;
    }
  }

  Future<void> _handleConnectivityChange(dynamic result) async {
    final nextOnline = _isOnlineFromResult(result);
    if (nextOnline && !_isOnline) {
      _isOnline = true;
      await _pullRemoteState();
      await _flushPendingQueues();
    } else if (!nextOnline) {
      _isOnline = false;
    }
  }

  bool _isOnlineFromResult(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is Iterable<ConnectivityResult>) {
      return result.any((element) => element != ConnectivityResult.none);
    }
    return true;
  }

  Future<void> _pullRemoteState() async {
    if (_client == null) {
      return;
    }
    await _pullRemoteHistory();
    await _pullRemoteProfile();
  }

  Future<void> _pullRemoteHistory() async {
    if (_client == null) return;
    try {
      final response = await _client!
          .from('history')
          .select()
          .eq('user_id', _userId)
          .order('updated_at', ascending: false);
      final remoteRecords = (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(StoryRecord.fromRemoteJson)
          .toList();
      _mergeHistory(remoteRecords);
    } catch (_) {
      // Ignore remote fetch failures; cached data will continue to be used.
    }
  }

  Future<void> _pullRemoteProfile() async {
    if (_client == null) return;
    try {
      final response = await _client!
          .from('profiles')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();
      if (response == null || response is! Map<String, dynamic>) {
        return;
      }
      final remoteProfile = UserProfile.fromRemoteJson(response as Map<String, dynamic>);
      if (remoteProfile.updatedAt.isAfter(_profile!.updatedAt)) {
        _profile = remoteProfile;
        await _cacheProfile();
        _profileController.add(remoteProfile);
      }
    } catch (_) {
      // Ignore remote fetch failures.
    }
  }

  void _mergeHistory(List<StoryRecord> remoteRecords) {
    final Map<String, StoryRecord> merged = {
      for (final record in _history) record.id: record,
    };
    for (final remote in remoteRecords) {
      final existing = merged[remote.id];
      if (existing == null || remote.updatedAt.isAfter(existing.updatedAt)) {
        merged[remote.id] = remote;
      }
    }

    final remoteIds = remoteRecords.map((e) => e.id).toSet();
    final pendingIds = _pendingHistoryQueue
        .where((action) => action.type == _HistoryActionType.upsert && action.record != null)
        .map((action) => action.record!.id)
        .toSet();

    merged.removeWhere((key, value) => !remoteIds.contains(key) && !pendingIds.contains(key));

    _history = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _historyController.add(List.unmodifiable(_history));
    unawaited(_cacheHistory());
  }

  Future<void> _flushPendingQueues() async {
    await _flushPendingHistoryQueue();
    await _flushPendingProfileQueue();
  }

  Future<void> _flushPendingHistoryQueue() async {
    if (_client == null || !_isOnline || _pendingHistoryQueue.isEmpty) {
      return;
    }
    var didChange = false;
    while (_pendingHistoryQueue.isNotEmpty) {
      final action = _pendingHistoryQueue.first;
      final success = await _performHistoryAction(action);
      if (!success) {
        break;
      }
      _pendingHistoryQueue.removeAt(0);
      didChange = true;
    }
    if (didChange) {
      await _savePendingHistoryQueue();
    }
  }

  Future<void> _flushPendingProfileQueue() async {
    if (_client == null || !_isOnline || _pendingProfileQueue.isEmpty) {
      return;
    }
    var didChange = false;
    while (_pendingProfileQueue.isNotEmpty) {
      final update = _pendingProfileQueue.first;
      final success = await _performProfileUpdate(update);
      if (!success) {
        break;
      }
      _pendingProfileQueue.removeAt(0);
      didChange = true;
    }
    if (didChange) {
      await _savePendingProfileQueue();
    }
  }

  Future<bool> _performHistoryAction(_PendingHistoryAction action) async {
    if (_client == null) return false;
    try {
      switch (action.type) {
        case _HistoryActionType.upsert:
          final record = action.record;
          if (record == null) return true;
          await _client!
              .from('history')
              .upsert([record.toRemoteJson(_userId)], onConflict: 'id');
          return true;
        case _HistoryActionType.clear:
          await _client!.from('history').delete().eq('user_id', _userId);
          return true;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> _performProfileUpdate(_PendingProfileUpdate update) async {
    if (_client == null) return false;
    try {
      await _client!.from('profiles').upsert(update.payload, onConflict: 'user_id');
      return true;
    } catch (_) {
      return false;
    }
  }
}

enum _HistoryActionType { upsert, clear }

class _PendingHistoryAction {
  _PendingHistoryAction._(this.type, this.record, DateTime? createdAt)
      : createdAt = (createdAt ?? DateTime.now()).toUtc();

  factory _PendingHistoryAction.upsert(StoryRecord record) =>
      _PendingHistoryAction._(_HistoryActionType.upsert, record, DateTime.now());

  factory _PendingHistoryAction.clear() =>
      _PendingHistoryAction._(_HistoryActionType.clear, null, DateTime.now());

  final _HistoryActionType type;
  final StoryRecord? record;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'record': record?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _PendingHistoryAction.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String?;
    final createdAt = StoryRecord.parseDate(json['createdAt']) ?? DateTime.now().toUtc();
    final recordJson = json['record'];

    switch (typeString) {
      case 'upsert':
        if (recordJson is Map<String, dynamic>) {
          return _PendingHistoryAction._(
            _HistoryActionType.upsert,
            StoryRecord.fromJson(recordJson),
            createdAt,
          );
        }
        break;
      case 'clear':
        return _PendingHistoryAction._(_HistoryActionType.clear, null, createdAt);
    }

    return _PendingHistoryAction._(_HistoryActionType.clear, null, createdAt);
  }
}

class _PendingProfileUpdate {
  _PendingProfileUpdate({required this.payload, DateTime? createdAt})
      : createdAt = (createdAt ?? DateTime.now()).toUtc();

  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _PendingProfileUpdate.fromJson(Map<String, dynamic> json) {
    final createdAt = StoryRecord.parseDate(json['createdAt']) ?? DateTime.now().toUtc();
    final payload = (json['payload'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return _PendingProfileUpdate(payload: payload, createdAt: createdAt);
  }
}