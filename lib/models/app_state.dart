import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/preferences_service.dart';
import '../services/service_exceptions.dart';
import '../services/story_generation_service.dart';
import '../services/user_data_store.dart';
import '../themes/colors.dart';
import 'generation_record.dart';
import 'user_profile.dart';

class AppState extends ChangeNotifier {
  AppState({
    required StoryGenerationService storyService,
    required HistoryService historyService,
    required PreferencesService preferencesService,
    required UserDataStore dataStore,
    AuthService? authService,
  })  : _storyService = storyService,
        _historyService = historyService,
        _preferencesService = preferencesService,
        _dataStore = dataStore,
        _authService = authService;

  final StoryGenerationService _storyService;
  final HistoryService _historyService;
  final PreferencesService _preferencesService;
  final UserDataStore _dataStore;
  final AuthService? _authService;

  bool _initialised = false;
  bool _isGenerating = false;
  String? _errorMessage;
  final List<GenerationRecord> _history = <GenerationRecord>[];
  Color _accent = AppColors.accent;
  String? _displayName;
  String _streamingStory = '';
  String? _activeProviderId;
  StreamSubscription<dynamic>? _activeSubscription;
  StreamSubscription<List<GenerationRecord>>? _historySubscription;
  StreamSubscription<UserProfile>? _profileSubscription;
  StreamSubscription<AuthUser?>? _authSubscription;
  static const int _freeStoryQuota = 300;
  bool _isPremium = false;
  int _freeStoriesRemaining = _freeStoryQuota;
  UserProfile _profile = UserProfile(userId: 'local');
  AuthUser? _authUser;
  bool get initialised => _initialised;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  List<GenerationRecord> get history => List.unmodifiable(_history);
  Color get accentColor => _accent;
  String get displayName => _displayName ?? 'Creator';
  bool get onboardingComplete => _profile.onboardingComplete;
  String get streamingStory => _streamingStory;
  String? get activeProviderId => _activeProviderId;
  bool get hasStreamingStory => _streamingStory.isNotEmpty && _isGenerating;
  bool get isPremium => _isPremium;
  int get freeStoriesRemaining => _freeStoriesRemaining.clamp(0, _freeStoryQuota);
  int get freeStoryQuota => _freeStoryQuota;
  bool get authAvailable => _authService?.isAvailable ?? false;
  bool get isAuthenticated => _authUser != null;
  AuthUser? get authUser => _authUser;

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }
  Future<void> _prepareUserSession({bool initial = false}) async {
    if (_authService == null || !_authService!.isAvailable) {
      await _dataStore.useLocalUser();
      _authUser = null;
      return;
    }
    final user = _authService!.currentUser;
    _authUser = user;
    if (user != null) {
      await _dataStore.useUser(user.id);
    } else {
      await _dataStore.useLocalUser();
    }
    if (initial && user != null && _displayName == null) {
      _displayName = user.displayName ?? user.email?.split('@').first;
    }
  }
  Future<void> initialise() async {
    if (_initialised) return;
    await _prepareUserSession(initial: true);
    final history = await _historyService.loadHistory();
    _history
      ..clear()
      ..addAll(history);

    // Load profile / preferences if available.
    final profile = await _preferencesService.loadProfile();
    _applyProfile(profile, notify: false);

    _historySubscription = _historyService.historyStream.listen((records) {
      _history
        ..clear()
        ..addAll(records);
      notifyListeners();
    });

    _profileSubscription = _preferencesService.profileStream.listen((profile) {
      _applyProfile(profile);
    });
    _authSubscription = _authService?.onAuthStateChanged.listen((user) {
      unawaited(_handleAuthUserChanged(user));
    });
    // NOTE: For now, premium & free story budget are in-memory only.
    // You can persist these later via PreferencesService if you like.

    _initialised = true;
    notifyListeners();
  }

  /// Activates premium mode (called after a real purchase in the future).
  void activatePremium() {
    if (_isPremium) return;
    _isPremium = true;
    notifyListeners();
  }

  /// Generates a story.
  ///
  /// [genre] and [lengthLabel] are optional UI hints (e.g. "Horror", "Short").
  /// [continueFromPrevious]: if true, [previousStory] is used as base.
  Future<GenerationRecord?> generateImage(
      String prompt, {
        String? genre,
        String? lengthLabel,
        bool continueFromPrevious = false,
        String? previousStory,
      }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Please enter a prompt first.';
      notifyListeners();
      return null;
    }

    // 🔐 Free tier limit: 300 stories (in-memory).
    if (!_isPremium && _freeStoriesRemaining <= 0) {
      _errorMessage =
      'You have used all your 300 free stories.\nUnlock OBSDIV Premium to keep generating stories with real voices and long lengths.';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _errorMessage = null;
    _streamingStory = '';
    _activeProviderId = null;
    await _activeSubscription?.cancel();
    _activeSubscription = null;
    notifyListeners();

    try {
      GenerationRecord? storyRecord;
      final stream = _storyService.craftStoryStream(
        prompt: trimmed,
        genre: genre,
        lengthLabel: lengthLabel,
        continueStory: continueFromPrevious,
        previousStory: previousStory,
        userName: _displayName,
      );
      final completer = Completer<GenerationRecord?>();
      _activeSubscription = stream.listen(
            (progress) {
          _activeProviderId ??= progress.providerId;
          _streamingStory = progress.buffer;
          if (progress.record != null) {
            storyRecord = progress.record;
          }
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(storyRecord);
          }
        },
        cancelOnError: true,
      );

      final record = await completer.future;
      await _activeSubscription?.cancel();
      _activeSubscription = null;
      if (record == null) {
        throw const AppServiceException('Story generation did not complete.');
      }
      _history.insert(0, record);
      await _historyService.addRecord(record);

      // Decrease free quota only for free users.
      if (!_isPremium && _freeStoriesRemaining > 0) {
        _freeStoriesRemaining--;
      }

      return record;
    } on MissingApiKeyException catch (e) {
      _errorMessage = e.message;
      return null;
    } on ProviderException catch (e) {
      _errorMessage = e.message;
      return null;
    } on AppServiceException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return null;
    } finally {
      await _activeSubscription?.cancel();
      _activeSubscription = null;
      _isGenerating = false;
      _streamingStory = '';
      _activeProviderId = null;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _historyService.clearHistory();
    notifyListeners();
  }

  Future<void> markOnboardingComplete() async {
    _profile = _profile.copyWith(onboardingComplete: true);
    await _preferencesService.setOnboardingComplete(true);
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    _displayName = name;
    _profile = _profile.copyWith(displayName: name);
    await _preferencesService.setDisplayName(name);
    notifyListeners();
  }

  Future<void> updateAccent(Color color) async {
    _accent = color;
    _profile = _profile.copyWith(accentHex: color.value);
    await _preferencesService.setAccentHex(color.value);
    notifyListeners();
  }

  /// Debug helper: reset free stories (e.g. for testing).
  void resetFreeStoriesForDebug() {
    _freeStoriesRemaining = _freeStoryQuota;
    notifyListeners();
  }

  void toggleFavorite(GenerationRecord record) {
    final index = _history.indexWhere((element) => element.id == record.id);
    if (index == -1) return;
    final updated = record.copyWith(
      isFavorite: !record.isFavorite,
      updatedAt: DateTime.now().toUtc(),
    );
    _history[index] = updated;
    notifyListeners();
    unawaited(_historyService.addRecord(updated));
  }

  Future<void> signInWithEmail(String email, String password) async {
    final service = _authService;
    if (service == null || !service.isAvailable) {
      throw const AuthFlowException('Cloud sync is not configured.');
    }
    await service.signInWithEmail(email, password);
  }

  Future<void> signInWithGoogle() async {
    final service = _authService;
    if (service == null || !service.isAvailable) {
      throw const AuthFlowException('Cloud sync is not configured.');
    }
    await service.signInWithGoogle();
  }

  Future<void> signInWithApple() async {
    final service = _authService;
    if (service == null || !service.isAvailable) {
      throw const AuthFlowException('Cloud sync is not configured.');
    }
    await service.signInWithApple();
  }

  Future<void> signOut() async {
    final service = _authService;
    if (service == null || !service.isAvailable) {
      _authUser = null;
      await _dataStore.useLocalUser();
      await _reloadUserState();
      return;
    }
    await service.signOut();
    _authUser = null;
    await _dataStore.useLocalUser();
    await _reloadUserState();
  }

  Future<void> _handleAuthUserChanged(AuthUser? user) async {
    _authUser = user;
    if (user != null) {
      await _dataStore.useUser(user.id);
    } else {
      await _dataStore.useLocalUser();
    }
    await _reloadUserState();
    if (_displayName == null && user != null) {
      _displayName = user.displayName ?? user.email?.split('@').first;
    }
    notifyListeners();
  }

  Future<void> _reloadUserState() async {
    final history = await _historyService.loadHistory();
    _history
      ..clear()
      ..addAll(history);
    final profile = await _preferencesService.loadProfile();
    _applyProfile(profile, notify: false);
  }
  void _applyProfile(UserProfile profile, {bool notify = true}) {
    _profile = profile;
    _displayName = profile.displayName;
    if (profile.accentHex != null) {
      _accent = Color(profile.accentHex!);
    }
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _activeSubscription?.cancel();
    _historySubscription?.cancel();
    _profileSubscription?.cancel();
    _authSubscription?.cancel();
    unawaited(_authService?.dispose());
    super.dispose();
  }
}
