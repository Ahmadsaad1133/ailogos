import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/generation_record.dart';
import 'service_exceptions.dart';

class ImageGenerationService {
  /// Hugging Face Inference API key.
  final String apiKey;

  /// Model id, e.g. "stabilityai/stable-diffusion-3.5-large".
  final String modelId;

  const ImageGenerationService({
    required this.apiKey,
    required this.modelId,
  });

  String get _endpoint =>
      'https://api-inference.huggingface.co/models/$modelId';

  Future<GenerationRecord> generateImage({required String prompt}) async {
    if (apiKey.isEmpty) {
      // لاحظ إننا ما منمرر message هون → بيستعمل الافتراضي من الكلاس
      throw const MissingApiKeyException(message: '');
    }

    try {
      print('🧠 Sending prompt to Hugging Face: $prompt');
      print('📦 Using model: $modelId');

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: <String, String>{
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'inputs': prompt,
        }),
      );

      print('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final String base64 = base64Encode(bytes);

        return GenerationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          prompt: prompt,
          model: modelId,
          imageBase64: base64,
          createdAt: DateTime.now(),
        );
      } else {
        // ❗ هون منمرر message بشكل صريح عشان ما يطلع Error
        print('❌ HF error body: ${response.body}');
        throw ProviderException(
          message:
          'Hugging Face error ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('⚠️ Exception while calling HF: $e');
      throw AppServiceException('Failed to generate image: $e');
    }
  }
}
