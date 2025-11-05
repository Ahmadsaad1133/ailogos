import 'package:flutter/material.dart';

import '../services/history_service.dart';
import '../services/preferences_service.dart';
import '../services/service_exceptions.dart';
import '../services/story_generation_service.dart';
import '../themes/colors.dart';
import 'generation_record.dart';

class AppState extends ChangeNotifier {
  AppState({
    required StoryGenerationService storyService,
    required HistoryService historyService,
    required PreferencesService preferencesService,
  })  : _storyService = storyService,
        _historyService = historyService,
        _preferencesService = preferencesService;

  final StoryGenerationService _storyService;
  final HistoryService _historyService;
  final PreferencesService _preferencesService;

  bool _initialised = false;
  bool _isGenerating = false;
  String? _errorMessage;
  final List<GenerationRecord> _history = <GenerationRecord>[];
  Color _accent = AppColors.accent;
  String? _displayName;

  // 🔐 Premium & quota
  static const int _freeStoryQuota = 300;
  bool _isPremium = false;
  int _freeStoriesRemaining = _freeStoryQuota;

  bool get initialised => _initialised;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  List<GenerationRecord> get history => List.unmodifiable(_history);
  Color get accentColor => _accent;
  String get displayName => _displayName ?? 'Creator';
  bool get onboardingComplete => _preferencesService.onboardingComplete;

  bool get isPremium => _isPremium;
  int get freeStoriesRemaining => _freeStoriesRemaining.clamp(0, _freeStoryQuota);
  int get freeStoryQuota => _freeStoryQuota;

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  Future<void> initialise() async {
    if (_initialised) return;

    // Load history from disk.
    _history
      ..clear()
      ..addAll(_historyService.loadHistory());

    // Load profile / preferences if available.
    _displayName = _preferencesService.displayName;

    final accentHex = _preferencesService.accentHex;
    if (accentHex != null) {
      _accent = Color(accentHex);
    }

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
    notifyListeners();

    try {
      final storyRecord = await _storyService.craftStory(
        prompt: trimmed,
        genre: genre,
        lengthLabel: lengthLabel,
        continueStory: continueFromPrevious,
        previousStory: previousStory,
        userName: _displayName,
      );
      final GenerationRecord record = storyRecord;

      _history.insert(0, record);
      await _historyService.saveHistory(_history);

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
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _historyService.saveHistory(_history);
    notifyListeners();
  }

  Future<void> markOnboardingComplete() async {
    await _preferencesService.setOnboardingComplete(true);
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    _displayName = name;
    await _preferencesService.setDisplayName(name);
    notifyListeners();
  }

  Future<void> updateAccent(Color color) async {
    _accent = color;
    await _preferencesService.setAccentHex(color.value);
    notifyListeners();
  }

  /// Debug helper: reset free stories (e.g. for testing).
  void resetFreeStoriesForDebug() {
    _freeStoriesRemaining = _freeStoryQuota;
    notifyListeners();
  }
  // TEMP: stub to satisfy HistoryScreen / tiles.
  // Currently does nothing. We can wire real favorites later.
  void toggleFavorite(GenerationRecord record) {
    // If you later add an `isFavorite` field to GenerationRecord,
    // you can update the record here and save history.
    notifyListeners();
  }
}
