import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/generation_record.dart';
import 'service_exceptions.dart';

/// Communicates with Hugging Face Inference API
class ImageGenerationService {
  ImageGenerationService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;//

  static const _modelUrl =
      'https://api-inference.huggingface.co/models/gsdf/Counterfeit-V2.5';

  static const _apiKey = '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';

  Future<GenerationRecord> generateImage({
    required String prompt,
  }) async {
    print('🧠 Sending prompt to Hugging Face: $prompt');

    final response = await _client.post(
      Uri.parse(_modelUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inputs': prompt}),
    );

    print('📡 Response: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw AppServiceException(
        'Generation failed: ${response.statusCode} - ${response.body}',
      );
    }

    final imageBytes = response.bodyBytes;
    final imageBase64 = base64Encode(imageBytes);

    final now = DateTime.now();
    return GenerationRecord(
      id: now.microsecondsSinceEpoch.toString(),
      prompt: prompt,
      model: 'Stable Diffusion v1-5',
      imageBase64: imageBase64,
      createdAt: now,
    );
  }

  void dispose() {
    _client.close();
  }
}
