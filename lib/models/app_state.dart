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

  final List<GenerationRecord> _history = [];
  bool _initialised = false;
  bool _isGenerating = false;
  String? _errorMessage;
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

    _history.clear();
    _history.addAll(_historyService.loadHistory());
    _displayName = _preferencesService.displayName;
    final accentHex = _preferencesService.accentHex;
    if (accentHex != null) {
      _accent = Color(accentHex);
    }

    _initialised = true;
    notifyListeners();
  }

  /// Generate an image and return the full GenerationRecord.
  Future<GenerationRecord?> generateImage(String prompt) async {
    if (_isGenerating) return null;
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 👈 هون لازم نستعمل named parameter
      final record = await _imageService.generateImage(prompt: prompt);

      _history.insert(0, record);
      await _historyService.saveHistory(_history);

      return record;
    } on AppServiceException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (error) {
      _errorMessage = 'Something went wrong. Please try again.\n$error';
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
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
    // imageBytes جاي من الـ getter داخل GenerationRecord
    return _storageService.saveToGallery(record.imageBytes, record.id);
  }

  Future<void> shareImage(GenerationRecord record) async {
    await _storageService.shareImage(record.imageBytes, record.id);
  }
}
