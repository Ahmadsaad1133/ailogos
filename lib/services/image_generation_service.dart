import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/generation_record.dart';
import 'service_exceptions.dart';

class ImageGenerationService {
  /// Hugging Face Inference API key.
  final String apiKey;

  /// Model id, e.g. "stable-diffusion-v1-5/stable-diffusion-v1-5".
  final String modelId;

  const ImageGenerationService({
    required this.apiKey,
    required this.modelId,
  });

  /// ✅ HF Router base URL (serverless inference)
  ///
  /// full URL = https://router.huggingface.co/hf-inference/models/{modelId}
  static const String _baseUrl =
      'https://router.huggingface.co/hf-inference/models/';

  Map<String, String> get _headers => <String, String>{
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _buildPayload(String prompt) => <String, dynamic>{
    'inputs': prompt,
    'options': <String, dynamic>{
      'wait_for_model': true,
    },
  };

  String _parseErrorMessage(http.Response response) {
    final bodyBytes = response.bodyBytes;
    if (bodyBytes.isEmpty) {
      return 'Hugging Face returned status ${response.statusCode} with an empty body.';
    }

    final body = utf8.decode(bodyBytes);

    // جرّب تقرا JSON { "error": "..."}
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final dynamic raw =
            decoded['error'] ?? decoded['message'] ?? decoded['detail'];
        if (raw is String && raw.isNotEmpty) {
          return raw;
        }
      }
    } catch (_) {
      // مش JSON، منكمّل
    }

    if (response.statusCode == 404) {
      return 'Model not found or not supported by HF Inference. '
          'تأكّد من اسم الموديل، ومن إنّو عنده HF Inference API على صفحة الموديل.';
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html')) {
      return 'Received HTML error page from Hugging Face. '
          'Check API key permissions and model accessibility.';
    }

    return body;
  }

  Future<GenerationRecord> generateImage({required String prompt}) async {
    if (apiKey.isEmpty) {
      throw const MissingApiKeyException(
        message: 'API key is missing or empty.',
      );
    }

    try {
      print('🧠 Sending prompt to Hugging Face: $prompt');
      print('📦 Using model: $modelId');

      final uri = Uri.parse('$_baseUrl$modelId');
      print('🌐 HF URL: $uri');

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(_buildPayload(prompt)),
      );

      print('📥 HF status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          throw const AppServiceException(
            'Hugging Face returned an empty image.',
          );
        }

        final record = GenerationRecord.fromBytes(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          prompt: prompt,
          model: modelId,
          bytes: bytes,
        );

        return record;
      }

      final errorMessage = _parseErrorMessage(response);
      print('❌ HF error body: $errorMessage');
      throw ProviderException(
        message: 'Hugging Face error ${response.statusCode}: $errorMessage',
        statusCode: response.statusCode,
      );
    } on ProviderException {
      rethrow;
    } catch (e) {
      print('⚠️ Exception while calling HF: $e');
      throw AppServiceException('Failed to generate image: $e');
    }
  }
}
