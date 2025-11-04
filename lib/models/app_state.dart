import 'package:flutter/material.dart';

import '../services/history_service.dart';
import '../services/image_generation_service.dart';
import '../services/preferences_service.dart';
import '../services/service_exceptions.dart';
import '../services/storage_service.dart';
import '../themes/colors.dart';
import 'generation_record.dart';

class AppState extends ChangeNotifier {
  AppState({
    required ImageGenerationService imageService,
    required HistoryService historyService,
    required PreferencesService preferencesService,
    StorageService? storageService,
  })  : _imageService = imageService,
        _historyService = historyService,
        _preferencesService = preferencesService,
        _storageService = storageService ?? const StorageService();

  final ImageGenerationService _imageService;
  final HistoryService _historyService;
  final PreferencesService _preferencesService;
  final StorageService _storageService;

  bool _initialised = false;
  bool _isGenerating = false;
  String? _errorMessage;
  final List<GenerationRecord> _history = <GenerationRecord>[];
  Color _accent = AppColors.accent;
  String? _displayName;

  bool get initialised => _initialised;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  List<GenerationRecord> get history => List.unmodifiable(_history);
  Color get accentColor => _accent;
  String? get displayName => _displayName;
  bool get onboardingComplete => _preferencesService.onboardingComplete;

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  Future<void> initialise() async {
    if (_initialised) return;

    _history
      ..clear()
      ..addAll(_historyService.loadHistory());

    _displayName = _preferencesService.displayName;

    final accentHex = _preferencesService.accentHex;
    if (accentHex != null) {
      _accent = Color(accentHex);
    }

    _initialised = true;
    notifyListeners();
  }

  /// هيدي الفنكشن اللي بيناديها الـ HomeScreen:
  /// state.generateImage(prompt)
  Future<GenerationRecord?> generateImage(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Please enter a prompt first.';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final record = await _imageService.generateImage(prompt: trimmed);

      // حطّ الصورة الجديدة بأول الـ history
      _history.insert(0, record);
      await _historyService.saveHistory(_history);

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

  Future<String> saveImage(GenerationRecord record) async {
    return _storageService.saveToGallery(record.imageBytes, record.id);
  }

  Future<void> shareImage(GenerationRecord record) async {
    await _storageService.shareImage(record.imageBytes, record.id);
  }
}
