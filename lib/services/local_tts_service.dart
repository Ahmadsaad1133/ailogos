import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class LocalTTSService {
  final String baseUrl;
  final AudioPlayer _player = AudioPlayer();

  LocalTTSService({required this.baseUrl});

  Future<void> speak(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/tts.wav');
        await file.writeAsBytes(bytes);
        await _player.play(DeviceFileSource(file.path));
      } else {
        print('TTS error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling local TTS: $e');
    }
  }

  void stop() {
    _player.stop();
  }
}
