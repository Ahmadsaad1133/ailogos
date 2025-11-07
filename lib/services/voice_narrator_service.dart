import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/voice_narration.dart';

class VoiceNarratorService {
  static const _channel = MethodChannel('chaquopy');

  // Only one local voice for now
  static const List<String> availableVoices = ['Default narrator'];

  Future<VoiceNarration> narrate({
    required String userId,
    required String text,
    required String voiceStyle,
    required double pitch,
    required double rate,
  }) async {
    final dir = await getApplicationDocumentsDirectory();

    // Use MP3 because gTTS writes MP3 audio
    final outputPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.mp3';

    try {
      final result = await _channel.invokeMethod<String>(
        'runPythonTTS',
        {
          'text': text,
          'path': outputPath,
        },
      );

      if (result == null || result.startsWith('error:')) {
        throw Exception('Python error: $result');
      }

      return VoiceNarration(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        voiceStyle: voiceStyle,
        pitch: pitch,
        rate: rate,
        filePath: outputPath,
        createdAt: DateTime.now(),
        durationSeconds: 0,
      );
    } on PlatformException catch (e) {
      throw Exception('Local TTS failed: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Local TTS failed: $e');
    }
  }
}
