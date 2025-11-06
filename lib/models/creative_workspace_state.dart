import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/creative_content_repository.dart';
import '../services/image_generation_service.dart';
import '../services/persona_chat_service.dart';
import '../services/sleep_sound_service.dart';
import '../services/voice_narrator_service.dart';
import '../services/writing_generation_service.dart';
import '../services/cloud_media_repository.dart';
import '../services/user_data_store.dart';
import 'chat_conversation.dart';
import 'chat_message.dart';
import 'generated_image.dart';
import 'sleep_sound_mix.dart';
import 'voice_narration.dart';
import 'writing_piece.dart';

class CreativeWorkspaceState extends ChangeNotifier {
  CreativeWorkspaceState({
    required ImageGenerationService imageService,
    required VoiceNarratorService voiceService,
    required SleepSoundService sleepSoundService,
    required WritingGenerationService writingService,
    required PersonaChatService personaChatService,
    required CreativeContentRepository contentRepository,
    required CloudMediaRepository mediaRepository,
    required UserDataStore dataStore,
    required AuthService authService,
  })  : _imageService = imageService,
        _voiceService = voiceService,
        _sleepService = sleepSoundService,
        _writingService = writingService,
        _personaService = personaChatService,
        _contentRepository = contentRepository,
        _mediaRepository = mediaRepository,
        _dataStore = dataStore,
        _authService = authService {
    _userId = _dataStore.userId;
    _authSubscription = _authService.authStateChanges().listen((user) {
      _handleAuthUpdate(user);
    });
    _attachStreams();
  }

  final ImageGenerationService _imageService;
  final VoiceNarratorService _voiceService;
  final SleepSoundService _sleepService;
  final WritingGenerationService _writingService;
  final PersonaChatService _personaService;
  final CreativeContentRepository _contentRepository;
  final CloudMediaRepository _mediaRepository;
  final UserDataStore _dataStore;
  final AuthService _authService;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<GeneratedImage>>? _imagesSubscription;
  StreamSubscription<List<VoiceNarration>>? _voiceSubscription;
  StreamSubscription<List<SleepSoundMix>>? _sleepSubscription;
  StreamSubscription<List<WritingPiece>>? _writingSubscription;
  StreamSubscription<List<ChatConversation>>? _conversationSubscription;

  String _userId = 'local';
  bool _isGeneratingImages = false;
  bool _isGeneratingVoice = false;
  bool _isGeneratingSleep = false;
  bool _isGeneratingWriting = false;
  bool _isPersonaStreaming = false;

  String? _imageError;
  String? _voiceError;
  String? _sleepError;
  String? _writingError;
  String? _personaError;

  List<GeneratedImage> _recentImages = const [];
  List<GeneratedImage> _imageGallery = const [];
  VoiceNarration? _latestNarration;
  List<VoiceNarration> _narrationLibrary = const [];
  SleepSoundMix? _latestSleepMix;
  List<SleepSoundMix> _sleepLibrary = const [];
  WritingPiece? _latestWriting;
  List<WritingPiece> _writingLibrary = const [];
  List<ChatConversation> _conversationArchive = const [];

  PersonaPreset _activePreset = const PersonaPreset(
    id: 'writer',
    title: 'Writer',
    description: 'Imaginative author who builds heartfelt narratives.',
    systemPrompt:
    'You are a warm, imaginative storyteller. Reply with short paragraphs that move the story forward, staying in character.',
  );
  String? _activeConversationId;
  DateTime? _conversationCreatedAt;
  List<ChatMessageModel> _activeMessages = <ChatMessageModel>[];
  String _streamingPersonaBuffer = '';
  String? _streamingProvider;

  static const List<PersonaPreset> personaPresets = [
    PersonaPreset(
      id: 'writer',
      title: 'Writer',
      description: 'Imaginative author who builds heartfelt narratives.',
      systemPrompt:
      'You are a warm, imaginative storyteller. Reply with short paragraphs that move the story forward, staying in character.',
    ),
    PersonaPreset(
      id: 'philosopher',
      title: 'Philosopher',
      description: 'Thoughtful sage who contemplates deeper meaning.',
      systemPrompt:
      'You are a reflective philosopher. Explore ideas with curiosity, referencing history and philosophy when helpful.',
    ),
    PersonaPreset(
      id: 'comedian',
      title: 'Comedian',
      description: 'Playful humorist with witty one-liners.',
      systemPrompt:
      'You are an energetic comedian. Keep responses punchy, fun, and light-hearted while staying respectful.',
    ),
  ];

  bool get isGeneratingImages => _isGeneratingImages;
  bool get isGeneratingVoice => _isGeneratingVoice;
  bool get isGeneratingSleep => _isGeneratingSleep;
  bool get isGeneratingWriting => _isGeneratingWriting;
  bool get isPersonaStreaming => _isPersonaStreaming;
  String? get imageError => _imageError;
  String? get voiceError => _voiceError;
  String? get sleepError => _sleepError;
  String? get writingError => _writingError;
  String? get personaError => _personaError;
  List<GeneratedImage> get recentImages => _recentImages;
  List<GeneratedImage> get imageGallery => _imageGallery;
  VoiceNarration? get latestNarration => _latestNarration;
  List<VoiceNarration> get narrationLibrary => _narrationLibrary;
  SleepSoundMix? get latestSleepMix => _latestSleepMix;
  List<SleepSoundMix> get sleepLibrary => _sleepLibrary;
  WritingPiece? get latestWriting => _latestWriting;
  List<WritingPiece> get writingLibrary => _writingLibrary;
  List<ChatConversation> get conversationArchive => _conversationArchive;
  List<ChatMessageModel> get activeMessages => List.unmodifiable(_activeMessages);
  PersonaPreset get activePreset => _activePreset;
  String get streamingPersonaBuffer => _streamingPersonaBuffer;
  String? get streamingProvider => _streamingProvider;

  Future<void> generateImages(String prompt, {int count = 1}) async {
    _imageError = null;
    _isGeneratingImages = true;
    notifyListeners();
    try {
      final results = await _imageService.generateImages(prompt: prompt, count: count);
      final userId = _userId;
      final uploads = <GeneratedImage>[];
      for (final image in results) {
        final data = image.bytes;
        if (data == null) continue;
        final path = 'users/$userId/images/${image.id}.png';
        final url = await _mediaRepository.uploadBytes(
          data: data,
          path: path,
          contentType: 'image/png',
        );
        uploads.add(image.copyWith(
          storagePath: path,
          downloadUrl: url,
        ));
      }
      if (uploads.isNotEmpty) {
        await _contentRepository.saveGeneratedImages(
          userId: userId,
          images: uploads,
        );
        _recentImages = uploads;
      }
    } catch (e) {
      _imageError = e.toString();
    } finally {
      _isGeneratingImages = false;
      notifyListeners();
    }
  }

  Future<void> generateNarration({
    required String text,
    required String voiceStyle,
    required double pitch,
    required double rate,
  }) async {
    _voiceError = null;
    _isGeneratingVoice = true;
    notifyListeners();
    try {
      final narration = await _voiceService.narrate(
        userId: _userId,
        text: text,
        voiceStyle: voiceStyle,
        pitch: pitch,
        rate: rate,
      );
      await _contentRepository.saveVoiceNarration(
        userId: _userId,
        narration: narration,
      );
      _latestNarration = narration;
    } catch (e) {
      _voiceError = e.toString();
    } finally {
      _isGeneratingVoice = false;
      notifyListeners();
    }
  }

  Future<void> generateSleepMix({
    required List<String> layers,
    required Duration duration,
    required bool loop,
    required double mixRatio,
  }) async {
    _sleepError = null;
    _isGeneratingSleep = true;
    notifyListeners();
    try {
      final mix = await _sleepService.createMix(
        userId: _userId,
        layers: layers,
        duration: duration,
        loop: loop,
        mixRatio: mixRatio,
      );
      await _contentRepository.saveSleepMix(
        userId: _userId,
        mix: mix,
      );
      _latestSleepMix = mix;
    } catch (e) {
      _sleepError = e.toString();
    } finally {
      _isGeneratingSleep = false;
      notifyListeners();
    }
  }

  Future<void> generateWriting({
    required WritingCategory category,
    required String prompt,
  }) async {
    _writingError = null;
    _isGeneratingWriting = true;
    notifyListeners();
    try {
      final piece = await _writingService.generatePiece(
        category: category,
        prompt: prompt,
      );
      await _contentRepository.saveWritingPiece(
        userId: _userId,
        piece: piece,
      );
      _latestWriting = piece;
    } catch (e) {
      _writingError = e.toString();
    } finally {
      _isGeneratingWriting = false;
      notifyListeners();
    }
  }

  void selectPersona(PersonaPreset preset) {
    _activePreset = preset;
    resetConversation();
    notifyListeners();
  }

  Future<void> sendPersonaMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isPersonaStreaming) {
      return;
    }
    _personaError = null;
    final now = DateTime.now();
    final conversationId = _ensureConversationId();
    _isPersonaStreaming = true;
    _streamingPersonaBuffer = '';
    _streamingProvider = null;
    notifyListeners();

    final previousHistory = List<ChatMessageModel>.from(_activeMessages);
    final userMessage = ChatMessageModel(
      role: 'user',
      text: trimmed,
      createdAt: now,
    );
    _activeMessages = [..._activeMessages, userMessage];
    await _persistConversation(conversationId);
    notifyListeners();

    try {
      await for (final event in _personaService.sendMessage(
        persona: _activePreset,
        history: previousHistory,
        userMessage: trimmed,
      )) {
        _streamingPersonaBuffer = event.buffer;
        _streamingProvider = event.providerId;
        notifyListeners();
      }
      final assistant = ChatMessageModel(
        role: 'assistant',
        text: _streamingPersonaBuffer,
        createdAt: DateTime.now(),
      );
      _activeMessages = [..._activeMessages, assistant];
      await _persistConversation(conversationId);
    } catch (e) {
      _personaError = e.toString();
    } finally {
      _isPersonaStreaming = false;
      _streamingPersonaBuffer = '';
      _streamingProvider = null;
      notifyListeners();
    }
  }

  void resetConversation() {
    _activeConversationId = null;
    _conversationCreatedAt = null;
    _activeMessages = <ChatMessageModel>[];
    _streamingPersonaBuffer = '';
    _streamingProvider = null;
    _personaError = null;
    notifyListeners();
  }

  Future<void> _persistConversation(String conversationId) async {
    final createdAt = _conversationCreatedAt ?? DateTime.now();
    _conversationCreatedAt ??= createdAt;
    final conversation = ChatConversation(
      id: conversationId,
      personaId: _activePreset.id,
      messages: _activeMessages,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
    await _contentRepository.saveConversation(
      userId: _userId,
      conversation: conversation,
    );
  }

  String _ensureConversationId() {
    if (_activeConversationId != null) {
      return _activeConversationId!;
    }
    _activeConversationId = DateTime.now().microsecondsSinceEpoch.toString();
    return _activeConversationId!;
  }

  void _handleAuthUpdate(User? user) {
    final nextId = user?.uid ?? _dataStore.userId;
    if (nextId == _userId) return;
    _userId = nextId;
    _detachStreams();
    _attachStreams();
    notifyListeners();
  }

  void _attachStreams() {
    _imagesSubscription = _contentRepository.watchImages(_userId).listen((items) {
      _imageGallery = items;
      notifyListeners();
    });
    _voiceSubscription =
        _contentRepository.watchVoiceNarrations(_userId).listen((items) {
          _narrationLibrary = items;
          notifyListeners();
        });
    _sleepSubscription =
        _contentRepository.watchSleepMixes(_userId).listen((items) {
          _sleepLibrary = items;
          notifyListeners();
        });
    _writingSubscription =
        _contentRepository.watchWritingPieces(_userId).listen((items) {
          _writingLibrary = items;
          notifyListeners();
        });
    _conversationSubscription =
        _contentRepository.watchConversations(_userId).listen((items) {
          _conversationArchive = items;
          notifyListeners();
        });
  }

  void _detachStreams() {
    _imagesSubscription?.cancel();
    _voiceSubscription?.cancel();
    _sleepSubscription?.cancel();
    _writingSubscription?.cancel();
    _conversationSubscription?.cancel();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _detachStreams();
    super.dispose();
  }
}