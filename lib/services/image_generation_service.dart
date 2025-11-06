import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/generated_image.dart';

/// Image generation service using Hugging Face Inference API.
/// Configure `.env` with:
/// HUGGINGFACE_API_KEY=hf_xxxxxxxxxxxxxxxxxxxxx
/// HUGGINGFACE_MODEL_ID=stabilityai/stable-diffusion-xl-base-1.0
class ImageGenerationService {
  ImageGenerationService({
    String? apiKey,
    String? model,
    http.Client? httpClient,
  })  : _apiKey = apiKey ?? dotenv.env['HUGGINGFACE_API_KEY'] ?? '',
        _model = model ?? dotenv.env['HUGGINGFACE_MODEL_ID'] ?? 'stabilityai/stable-diffusion-xl-base-1.0',
        _client = httpClient ?? http.Client(),
        _endpoint = Uri.parse(
          'https://api-inference.huggingface.co/models/${dotenv.env['HUGGINGFACE_MODEL_ID'] ?? 'stabilityai/stable-diffusion-xl-base-1.0'}',
        );

  final String _apiKey;
  final String _model;
  final http.Client _client;
  final Uri _endpoint;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Generates images from a text [prompt].
  /// Returns a list of [GeneratedImage] containing decoded bytes.
  Future<List<GeneratedImage>> generateImages({
    required String prompt,
    int count = 1,
    String size = '1024x1024',
  }) async {
    if (!isConfigured) {
      throw StateError('Hugging Face API key is not configured.');
    }

    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Prompt cannot be empty.');
    }

    final response = await _client.post(
      _endpoint,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': trimmed,
        'options': {'wait_for_model': true},
      }),
    );

    if (response.statusCode >= 400) {
      String? message;
      try {
        final decoded = jsonDecode(response.body);
        message = decoded['error']?.toString() ?? decoded['message']?.toString();
      } catch (_) {
        message = null;
      }
      throw Exception(
        'Image generation failed: ${response.statusCode} ${message ?? response.body}',
      );
    }

    // Hugging Face may return either binary image bytes or base64 JSON
    Uint8List bytes;
    try {
      // If the response is JSON with base64
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('b64_json')) {
        bytes = base64Decode(decoded['b64_json']);
      } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        bytes = base64Decode(decoded.first['b64_json']);
      } else {
        // fallback: treat whole body as base64
        bytes = base64Decode(response.body);
      }
    } catch (_) {
      // Some models return raw PNG bytes directly
      bytes = response.bodyBytes;
    }

    final now = DateTime.now();
    final images = <GeneratedImage>[];
    for (var i = 0; i < count; i++) {
      images.add(
        GeneratedImage(
          id: '${now.microsecondsSinceEpoch}_$i',
          prompt: trimmed,
          provider: _model,
          storagePath: '',
          downloadUrl: '',
          createdAt: now,
          index: i,
          bytes: bytes,
        ),
      );
    }

    return images;
  }
}
