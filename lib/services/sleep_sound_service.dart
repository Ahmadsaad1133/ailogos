import 'dart:math';
import 'dart:typed_data';

import '../models/sleep_sound_mix.dart';
import 'cloud_media_repository.dart';

class SleepSoundService {
  SleepSoundService({required CloudMediaRepository mediaRepository})
      : _mediaRepository = mediaRepository;

  final CloudMediaRepository _mediaRepository;

  static const int _sampleRate = 16000;

  Future<SleepSoundMix> createMix({
    required String userId,
    required List<String> layers,
    required Duration duration,
    required bool loop,
    double mixRatio = 0.7,
  }) async {
    final totalSamples = (_sampleRate * duration.inSeconds).clamp(1, 6000000);
    final buffer = Float64List(totalSamples);
    final random = Random();

    if (layers.contains('rain')) {
      _applyRain(buffer, random, intensity: mixRatio);
    }
    if (layers.contains('wind')) {
      _applyWind(buffer, random, intensity: mixRatio * 0.8);
    }
    if (layers.contains('waves')) {
      _applyWaves(buffer, intensity: mixRatio * 0.6);
    }

    final bytes = _encodeWav(buffer);
    final mixId = DateTime.now().microsecondsSinceEpoch.toString();
    final storagePath = 'users/$userId/sleep_sounds/$mixId.wav';
    final downloadUrl = await _mediaRepository.uploadBytes(
      data: bytes,
      path: storagePath,
      contentType: 'audio/wav',
    );

    return SleepSoundMix(
      id: mixId,
      title: 'Custom Mix',
      layers: layers,
      durationSeconds: duration.inSeconds.toDouble(),
      loopEnabled: loop,
      mixRatio: mixRatio,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      createdAt: DateTime.now(),
      bytes: bytes,
    );
  }

  void _applyRain(Float64List buffer, Random random, {double intensity = 0.5}) {
    for (var i = 0; i < buffer.length; i++) {
      final noise = (random.nextDouble() * 2 - 1) * intensity * 0.4;
      buffer[i] += noise;
    }
  }

  void _applyWind(Float64List buffer, Random random, {double intensity = 0.5}) {
    double current = 0;
    for (var i = 0; i < buffer.length; i++) {
      current += (random.nextDouble() - 0.5) * 0.02;
      current = current.clamp(-1.0, 1.0);
      buffer[i] += current * intensity * 0.3;
    }
  }

  void _applyWaves(Float64List buffer, {double intensity = 0.5}) {
    final double baseFrequency = 0.8;
    final double secondaryFrequency = 1.3;
    for (var i = 0; i < buffer.length; i++) {
      final t = i / _sampleRate;
      final wave = (sin(2 * pi * baseFrequency * t) +
          0.5 * sin(2 * pi * secondaryFrequency * t)) /
          1.5;
      buffer[i] += wave * intensity * 0.6;
    }
  }

  Uint8List _encodeWav(Float64List buffer) {
    final scaled = Int16List(buffer.length);
    for (var i = 0; i < buffer.length; i++) {
      final sample = (buffer[i] * 32767).clamp(-32767.0, 32767.0).toInt();
      scaled[i] = sample;
    }

    final byteCount = scaled.length * 2;
    final totalDataLen = byteCount + 36;
    final bytes = BytesBuilder();

    void writeString(String value) {
      bytes.add(value.codeUnits);
    }

    void writeInt32(int value) {
      bytes.add(Uint8List(4)
        ..buffer.asByteData().setInt32(0, value, Endian.little));
    }

    void writeInt16(int value) {
      bytes.add(Uint8List(2)
        ..buffer.asByteData().setInt16(0, value, Endian.little));
    }

    writeString('RIFF');
    writeInt32(totalDataLen);
    writeString('WAVE');
    writeString('fmt ');
    writeInt32(16);
    writeInt16(1);
    writeInt16(1);
    writeInt32(_sampleRate);
    writeInt32(_sampleRate * 2);
    writeInt16(2);
    writeInt16(16);
    writeString('data');
    writeInt32(byteCount);
    bytes.add(scaled.buffer.asUint8List());
    return bytes.toBytes();
  }
}