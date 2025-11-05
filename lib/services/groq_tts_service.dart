import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service responsible for converting text to speech using Groq TTS.
///
/// Important:
/// - You CANNOT download or embed the Groq model in the app.
/// - But you CAN fetch the generated audio and play/cache it locally.
class GroqTTSService {
  GroqTTSService();

  /// Reads GROQ_API_KEY from .env
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// TTS model.
  ///
  /// For English:
  ///   playai-tts
  ///
  /// For Arabic:
  ///   playai-tts-arabic
  String get _model => 'playai-tts';

  /// Hard limit to keep requests small enough for free / on_demand tiers.
  ///
  /// Your current tier only allows ~1200 tokens per request.
  /// To stay safe, we'll only send ~800 characters of text.
  static const int _maxCharsForTts = 800;

  /// Take only the beginning of the story for audio playback.
  ///
  /// The audio becomes a "preview" instead of full story on low tiers.
  String _truncateForTts(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= _maxCharsForTts) return trimmed;

    final cut = trimmed.substring(0, _maxCharsForTts);

    // Try to end on a sentence boundary if possible.
    final lastDot = cut.lastIndexOf('.');
    final safeEnd = lastDot > 100 ? lastDot + 1 : cut.length;

    final preview = cut.substring(0, safeEnd).trim();
    return '$preview\n\n[Audio preview only – story is longer in text.]';
  }

  /// Generate speech audio from [text] and return a local File (MP3).
  ///
  /// [voice] is a model-specific voice name. For example:
  ///   "Fritz-PlayAI" (English)
  ///   "Salma-PlayAI" (Arabic, if using the Arabic model)
  Future<File> generateSpeech(
      String text, {
        String voice = 'Fritz-PlayAI',
      }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Missing GROQ_API_KEY in .env');
    }

    final uri = Uri.parse('https://api.groq.com/openai/v1/audio/speech');

    final safeText = _truncateForTts(text);

    final body = jsonEncode({
      'model': _model,
      'voice': voice,
      'input': safeText,
      'response_format': 'mp3',
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      // Try to parse common errors nicely.
      try {
        final decoded = jsonDecode(response.body);
        final error = decoded['error'];
        final code = error?['code'] as String?;
        final message = error?['message'] as String?;

        if (code == 'rate_limit_exceeded') {
          throw Exception(
            'Groq TTS limit reached for now.\n'
                'You can still use the device voice, or try the AI voice later.',
          );
        }

        if (code == 'model_terms_required') {
          throw Exception(
            'Groq TTS model terms not accepted.\n'
                'Open the Groq console and accept the terms for $_model.',
          );
        }

        if (message != null) {
          throw Exception('Groq TTS error: $message');
        }
      } catch (_) {
        // ignore parse failure and fall through
      }

      throw Exception(
        'Groq TTS failed: ${response.statusCode} ${response.body}',
      );
    }

    final bytes = response.bodyBytes;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/obsdiv_story_audio.mp3');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }
}
