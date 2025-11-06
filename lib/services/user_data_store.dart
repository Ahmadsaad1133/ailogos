import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/story_record.dart';
import '../models/user_profile.dart';

/// Centralised data store that keeps history and profile state in sync with
/// Cloud Firestore while maintaining a lightweight offline cache using
/// [SharedPreferences].
class UserDataStore {
  UserDataStore({
    required SharedPreferences preferences,
    FirebaseFirestore? firestore,
  })  : _preferences = preferences,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _schemaVersion = 2;
  static const _schemaKey = 'sync.schema_version';
  static const _historyCacheKey = 'sync.cache.history.v1';
  static const _profileCacheKey = 'sync.cache.profile.v1';
  static const _activeUserIdKey = 'sync.user_id.active';
  static const _localUserIdKey = 'sync.user_id.local';

  final FirebaseFirestore _firestore;
  final SharedPreferences _preferences;
  final _historyController =
  StreamController<List<StoryRecord>>.broadcast();
  final _profileController = StreamController<UserProfile>.broadcast();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _historySubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  late String _userId;
  String? _localUserId;
  bool _initialised = false;
  List<StoryRecord> _history = [];
  UserProfile _profile = UserProfile.anonymous('local');

  bool get initialised => _initialised;

  Stream<List<StoryRecord>> get historyStream => _historyController.stream;

  Stream<UserProfile> get profileStream => _profileController.stream;

  Future<void> initialise() async {
    if (_initialised) return;

    await _ensureSchema();
    await _loadStateForUser(_userId);


    _initialised = true;
  }


  String get userId => _userId;

  Future<void> useUser(String userId, {bool persist = true}) async {
    if (_userId == userId) return;
    await _detachRemoteListeners();
    _userId = userId;
    if (persist) {
      await _preferences.setString(_activeUserIdKey, userId);
    }
    await _loadStateForUser(userId);
  }

  Future<void> useLocalUser() async {
    final localId = _localUserId ??
        _preferences.getString(_localUserIdKey) ??
        const Uuid().v4();
    _localUserId = localId;
    await useUser(localId, persist: true);
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
    return _profile;
  }

  Future<void> upsertHistoryRecord(StoryRecord record) async {
    final normalized = record.copyWith(updatedAt: DateTime.now().toUtc());
    final index = _history.indexWhere((element) => element.id == normalized.id);
    if (index >= 0) {
      _history[index] = normalized;
    } else {
      _history.insert(0, normalized);
    }
    await _cacheHistory();
    _historyController.add(List.unmodifiable(_history));
    if (_isRemoteUser) {
      await _writeHistoryRecord(normalized);
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _cacheHistory();
    _historyController.add(const <StoryRecord>[]);

    if (_isRemoteUser) {
      await _clearRemoteHistory();
    }
  }

  Future<void> updateProfile({
    String? displayName,
    int? accentHex,
    bool? onboardingComplete,
  }) async {
    final nextProfile = _profile.copyWith(
      displayName: displayName ?? _profile.displayName,
      accentHex: accentHex ?? _profile.accentHex,
      onboardingComplete: onboardingComplete ?? _profile.onboardingComplete,
      updatedAt: DateTime.now().toUtc(),
    );
    _profile = nextProfile;
    await _cacheProfile();
    _profileController.add(nextProfile);

    if (_isRemoteUser) {
      await _writeProfile(nextProfile);
    }
  }

  Future<void> dispose() async {
    await _detachRemoteListeners();
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

    _historyController.add(List.unmodifiable(_history));
    _profileController.add(_profile);

    if (_isRemoteUser) {
      await _attachRemoteListeners();
      await _pullRemoteState();
    }
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
      if (profile.userId != userId) {
        return profile.copyWith(userId: userId);
      }
      return profile;
    } catch (_) {
      return UserProfile.anonymous(userId);
    }
  }

  Future<void> _cacheHistory() async {
    final key = _keyForUser(_historyCacheKey, _userId);
    if (_history.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, StoryRecord.encodeList(_history));
    }
  }

  Future<void> _cacheProfile() async {
    final key = _keyForUser(_profileCacheKey, _userId);
    await _preferences.setString(key, UserProfile.encode(_profile));
  }

  bool get _isRemoteUser =>
      _localUserId != null && _userId.isNotEmpty && _userId != _localUserId;

  Future<void> _attachRemoteListeners() async {
    await _detachRemoteListeners();
    final historyQuery = _firestore
        .collection('users')
        .doc(_userId)
        .collection('history')
        .orderBy('createdAt', descending: true);
    _historySubscription = historyQuery.snapshots().listen((snapshot) {
      final records = snapshot.docs
          .map((doc) => StoryRecord.fromFirestore(doc.data(), doc.id))
          .toList();
      _history = records;
      _historyController.add(List.unmodifiable(_history));
      unawaited(_cacheHistory());
    });

    final profileDoc = _firestore.collection('users').doc(_userId);
    _profileSubscription = profileDoc.snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        return;
      }
      final data = snapshot.data();
      if (data == null) return;
      _profile = UserProfile.fromFirestore(data, userId: _userId);
      _profileController.add(_profile);
      unawaited(_cacheProfile());
    });
  }

  Future<void> _detachRemoteListeners() async {
    await _historySubscription?.cancel();
    await _profileSubscription?.cancel();
    _historySubscription = null;
    _profileSubscription = null;
  }

  Future<void> _pullRemoteState() async {
    final userDoc = await _firestore.collection('users').doc(_userId).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        _profile = UserProfile.fromFirestore(data, userId: _userId);
        await _cacheProfile();
        _profileController.add(_profile);
      }
    }


    final historySnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('history')
        .orderBy('createdAt', descending: true)
        .get();
    final records = historySnapshot.docs
        .map((doc) => StoryRecord.fromFirestore(doc.data(), doc.id))
        .toList();
    _history = records;
    await _cacheHistory();
    _historyController.add(List.unmodifiable(_history));
  }

  Future<void> _writeHistoryRecord(StoryRecord record) async {
    final historyDoc = _firestore
        .collection('users')
        .doc(_userId)
        .collection('history')
        .doc(record.id);
    await historyDoc.set(
      record.toFirestoreJson(_userId),
      SetOptions(merge: true),
    );
  }

  Future<void> _clearRemoteHistory() async {
    final historyCollection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('history');
    final snapshot = await historyCollection.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _writeProfile(UserProfile profile) async {
    final doc = _firestore.collection('users').doc(_userId);
    await doc.set(
      profile.toFirestoreJson(),
      SetOptions(merge: true),
    );
  }
}
