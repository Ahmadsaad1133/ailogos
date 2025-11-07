import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/generated_image.dart';

/// Image generation service:
/// - يحاول أولاً Hugging Face
/// - إذا فشل (410 أو HTML) بيروح على OpenAI أو Groq تلقائياً.
class ImageGenerationService {
  ImageGenerationService({
    String? apiKey,
    String? model,
    http.Client? httpClient,
  })  : _hfApiKey = apiKey ?? dotenv.env['HUGGINGFACE_API_KEY'] ?? '',
        _hfModel =
            model ?? dotenv.env['HUGGINGFACE_MODEL_ID'] ?? 'stabilityai/sdxl-turbo',
        _client = httpClient ?? http.Client(),
        _hfEndpoint = Uri.parse(
          'https://api-inference.huggingface.co/models/${dotenv.env['HUGGINGFACE_MODEL_ID'] ?? 'stabilityai/sdxl-turbo'}',
        );

  final String _hfApiKey;
  final String _hfModel;
  final http.Client _client;
  final Uri _hfEndpoint;

  bool get isConfigured => _hfApiKey.isNotEmpty;

  /// ✅ هيدي هي الـ method اللي بيشتكي عليها الكود:
  Future<List<GeneratedImage>> generateImages({
    required String prompt,
    int count = 1,
    String size = '1024x1024',
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Prompt cannot be empty.');
    }

    // إذا ما في HuggingFace key من الأساس → روح مباشرة للفولباك
    if (!isConfigured) {
      return _fallbackToOpenAiOrGroq(
        prompt: trimmed,
        count: count,
        size: size,
      );
    }

    // 🔹 1. جرّب Hugging Face
    final response = await _client.post(
      _hfEndpoint,
      headers: {
        'Authorization': 'Bearer $_hfApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': trimmed,
        'options': {'wait_for_model': true},
      }),
    );

    final contentType = response.headers['content-type'] ?? '';

    // إذا رجّع HTML أو 410 → غالباً صفحة الموقع أو model gone
    if (contentType.contains('text/html') || response.statusCode == 410) {
      return _fallbackToOpenAiOrGroq(
        prompt: trimmed,
        count: count,
        size: size,
      );
    }

    if (response.statusCode >= 400) {
      String? message;
      try {
        final decoded = jsonDecode(response.body);
        message =
            decoded['error']?.toString() ?? decoded['message']?.toString();
      } catch (_) {}
      throw Exception(
        'Hugging Face error: ${response.statusCode} ${message ?? response.body}',
      );
    }

    // 🔹 2. فك الـ bytes
    Uint8List bytes;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['b64_json'] != null) {
        bytes = base64Decode(decoded['b64_json'] as String);
      } else if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map &&
          decoded.first['b64_json'] != null) {
        bytes = base64Decode(decoded.first['b64_json'] as String);
      } else {
        bytes = base64Decode(response.body);
      }
    } catch (_) {
      // بعض الموديلات بترجع PNG raw
      bytes = response.bodyBytes;
    }

    return _buildGeneratedImages(
      provider: _hfModel,
      prompt: trimmed,
      bytes: bytes,
      count: count,
    );
  }

  /// يبني لستة GeneratedImage من bytes واحدة (أو أكتر لو حابب تعدّل لاحقاً)
  List<GeneratedImage> _buildGeneratedImages({
    required String provider,
    required String prompt,
    required Uint8List bytes,
    required int count,
  }) {
    final now = DateTime.now();
    return List.generate(
      count,
          (i) => GeneratedImage(
        id: '${now.microsecondsSinceEpoch}_$i',
        prompt: prompt,
        provider: provider,
        storagePath: '',
        downloadUrl: '',
        createdAt: now,
        index: i,
        bytes: bytes,
      ),
    );
  }

  /// 🔁 فولباك: أولاً OpenAI، ولو مش موجود الكي → Groq
  Future<List<GeneratedImage>> _fallbackToOpenAiOrGroq({
    required String prompt,
    required int count,
    required String size,
  }) async {
    final openaiKey = dotenv.env['OPENAI_API_KEY'];
    final groqKey = dotenv.env['GROQ_API_KEY'];

    late Uri endpoint;
    late String apiKey;
    late String provider;
    late String modelName;

    if (openaiKey != null && openaiKey.isNotEmpty) {
      endpoint = Uri.parse('https://api.openai.com/v1/images/generations');
      apiKey = openaiKey;
      modelName = dotenv.env['OPENAI_IMAGE_MODEL'] ?? 'gpt-image-1';
      provider = 'openai/$modelName';
    } else if (groqKey != null && groqKey.isNotEmpty) {
      endpoint =
          Uri.parse('https://api.groq.com/openai/v1/images/generations');
      apiKey = groqKey;
      modelName = 'gpt-image-1';
      provider = 'groq/$modelName';
    } else {
      throw Exception(
        'No image API key configured (Hugging Face, OpenAI, or Groq).',
      );
    }

    final response = await _client.post(
      endpoint,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': modelName,
        'prompt': prompt,
        'size': size,
        'n': count,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'Fallback image generation failed: '
            '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>;
    final now = DateTime.now();
    final images = <GeneratedImage>[];

    for (var i = 0; i < data.length; i++) {
      final b64 = data[i]['b64_json'] as String;
      images.add(
        GeneratedImage(
          id: '${now.microsecondsSinceEpoch}_$i',
          prompt: prompt,
          provider: provider,
          storagePath: '',
          downloadUrl: '',
          createdAt: now,
          index: i,
          bytes: base64Decode(b64),
        ),
      );
    }

    return images;
  }
}
