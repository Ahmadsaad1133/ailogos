import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/generation_record.dart';
import 'service_exceptions.dart';

/// Communicates with the OpenAI Images API to generate pictures from prompts.
class ImageGenerationService {
  ImageGenerationService({http.Client? client, String? endpoint, String? model})
      : _client = client ?? http.Client(),
        _endpoint = endpoint ?? 'https://api.openai.com/v1/images/generations',
        _model = model ?? 'gpt-image-1';

  final http.Client _client;
  final String _endpoint;
  final String _model;

  String? _readApiKey() {
    final keyFromEnv = dotenv.env['OPENAI_API_KEY'];
    if (keyFromEnv != null && keyFromEnv.isNotEmpty) {
      return keyFromEnv;
    }
    const buildTimeKey = String.fromEnvironment('OPENAI_API_KEY');
    if (buildTimeKey.isNotEmpty) {
      return buildTimeKey;
    }
    return null;
  }

  Future<GenerationRecord> generateImage({
    required String prompt,
    String size = '1024x1024',
    String? user,
  }) async {
    final apiKey = _readApiKey();
    if (apiKey == null) {
      throw const MissingApiKeyException();
    }

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'prompt': prompt,
        'size': size,
        if (user != null) 'user': user,
        'n': 1,
        'response_format': 'b64_json',
      }),
    );

    if (response.statusCode >= 400) {
      throw ProviderException(
        statusCode: response.statusCode,
        message: _extractError(response.body),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>;
    if (data.isEmpty || data.first['b64_json'] == null) {
      throw const AppServiceException('Unexpected response from the AI provider.');
    }

    final imageBase64 = data.first['b64_json'] as String;
    final now = DateTime.now();

    return GenerationRecord(
      id: now.microsecondsSinceEpoch.toString(),
      prompt: prompt,
      model: _model,
      imageBase64: imageBase64,
      createdAt: now,
    );
  }

  String _extractError(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        return error['message']?.toString() ?? 'Unknown error occurred.';
      }
      return decoded['message']?.toString() ?? 'Unknown error occurred.';
    } catch (_) {
      return 'Unknown error occurred.';
    }
  }

  void dispose() {
    _client.close();
  }
}