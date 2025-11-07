import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service responsible for converting text to speech using Groq + PlayAI TTS.
///
/// Important:
/// - This calls Groq's OpenAI-compatible TTS endpoint:
///   https://api.groq.com/openai/v1/audio/speech
/// - Model used: `playai-tts`
/// - Voices must be one of the allowed PlayAI voices (see [supportedVoices]).
class GroqTTSService {
  GroqTTSService();

  /// Reads GROQ_API_KEY from .env
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  bool get isConfigured => _apiKey.isNotEmpty;

  static const String _ttsModel = 'playai-tts';

  /// Default voice if the caller doesn't specify one.
  static const String _defaultVoice = 'Fritz-PlayAI';

  /// All allowed voices as returned in the Groq error message.
  static const List<String> supportedVoices = [
    'Aaliyah-PlayAI',
    'Adelaide-PlayAI',
    'Angelo-PlayAI',
    'Arista-PlayAI',
    'Atlas-PlayAI',
    'Basil-PlayAI',
    'Briggs-PlayAI',
    'Calum-PlayAI',
    'Celeste-PlayAI',
    'Cheyenne-PlayAI',
    'Chip-PlayAI',
    'Cillian-PlayAI',
    'Deedee-PlayAI',
    'Eleanor-PlayAI',
    'Fritz-PlayAI',
    'Gail-PlayAI',
    'Indigo-PlayAI',
    'Jennifer-PlayAI',
    'Judy-PlayAI',
    'Mamaw-PlayAI',
    'Mason-PlayAI',
    'Mikail-PlayAI',
    'Mitch-PlayAI',
    'Nia-PlayAI',
    'Quinn-PlayAI',
    'Ruby-PlayAI',
    'Thunder-PlayAI',
  ];

  /// Generate speech from [text].
  ///
  /// [voice] must be one of [supportedVoices]. If null, [_defaultVoice] is used.
  /// [speed] must be between 0.25 and 4.0 (Groq constraint).
  /// [responseFormat] can be "mp3", "opus", "aac", "flac".
  Future<File> generateSpeech({
    required String text,
    String? voice,
    double speed = 1.0,
    String responseFormat = 'mp3',
  }) async {
    if (!isConfigured) {
      throw StateError(
        'Groq TTS API key is not configured. '
            'Set GROQ_API_KEY in your .env file.',
      );
    }

    if (text.trim().isEmpty) {
      throw ArgumentError('Text for TTS cannot be empty.');
    }

    // Clamp speed into valid range.
    final clampedSpeed = speed.clamp(0.25, 4.0);

    final selectedVoice = voice ?? _defaultVoice;

    if (!supportedVoices.contains(selectedVoice)) {
      throw ArgumentError(
        'Invalid TTS voice "$selectedVoice". '
            'It must be one of: ${supportedVoices.join(', ')}',
      );
    }

    final uri =
    Uri.parse('https://api.groq.com/openai/v1/audio/speech');

    final headers = <String, String>{
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final payload = <String, dynamic>{
      'model': _ttsModel,
      'input': text,
      'voice': selectedVoice,
      'speed': clampedSpeed,
      'response_format': responseFormat,
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Groq TTS failed: ${response.statusCode} ${response.body}',
      );
    }

    final bytes = response.bodyBytes;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/obsdiv_story_audio.$responseFormat');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }
}
