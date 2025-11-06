import 'dart:io';
import 'dart:typed_data';

import '../models/voice_narration.dart';
import 'cloud_media_repository.dart';
import 'groq_tts_service.dart';

class VoiceNarratorService {
  VoiceNarratorService({
    required GroqTTSService ttsService,
    required CloudMediaRepository mediaRepository,
  })  : _ttsService = ttsService,
        _mediaRepository = mediaRepository;

  final GroqTTSService _ttsService;
  final CloudMediaRepository _mediaRepository;

  static const Map<String, String> _voiceMapping = {
    'Warm Female': 'Salma-PlayAI',
    'Deep Male': 'Fritz-PlayAI',
    'Soft Whisper': 'Sandi-PlayAI',
    'Storyteller': 'Emily-PlayAI',
  };

  static List<String> get availableVoices =>
      List<String>.unmodifiable(_voiceMapping.keys);

  Future<VoiceNarration> narrate({
    required String userId,
    required String text,
    required String voiceStyle,
    required double pitch,
    required double rate,
  }) async {
    final voiceId = _voiceMapping[voiceStyle] ?? _voiceMapping.values.first;
    final file = await _ttsService.generateSpeech(text, voice: voiceId);
    final bytes = await file.readAsBytes();
    final narrationId = DateTime.now().microsecondsSinceEpoch.toString();
    final storagePath = 'users/$userId/voice/$narrationId.mp3';
    final downloadUrl = await _mediaRepository.uploadBytes(
      data: Uint8List.fromList(bytes),
      path: storagePath,
      contentType: 'audio/mpeg',
    );

    return VoiceNarration(
      id: narrationId,
      text: text,
      voiceStyle: voiceStyle,
      pitch: pitch,
      rate: rate,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      createdAt: DateTime.now(),
      durationSeconds: 0,
    );
  }
}