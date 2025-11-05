import 'dart:convert';

import 'package:http/http.dart' as http;

import '../service_exceptions.dart';
import 'chat_model_client.dart';
import 'chat_types.dart';
import 'sse_stream_decoder.dart';

/// Streaming chat client for Groq's OpenAI-compatible API surface.
class GroqChatClient implements ChatModelClient {
  GroqChatClient({
    required this.apiKey,
    required this.model,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  @override
  String get id => 'groq';

  @override
  bool get isConfigured => apiKey.isNotEmpty && model.isNotEmpty;

  @override
  Stream<ChatCompletionChunk> streamChatCompletion(ChatRequest request) async* {
    if (!isConfigured) {
      throw const MissingApiKeyException(
        message: 'Missing Groq API key. Configure GROQ_API_KEY.',
      );
    }

    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final payload = <String, dynamic>{
      'model': model,
      'messages': request.messages.map((m) => m.toMap()).toList(),
      'stream': true,
      if (request.maxTokens != null) 'max_tokens': request.maxTokens,
      if (request.temperature != null) 'temperature': request.temperature,
      ...request.extraParams,
    };

    final http.Request httpRequest = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      })
      ..body = jsonEncode(payload);

    final http.StreamedResponse response;
    try {
      response = await _client.send(httpRequest);
    } catch (e) {
      throw AppServiceException('Groq request failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw ProviderException(
        message: 'Groq error ${response.statusCode}: $body',
        statusCode: response.statusCode,
      );
    }

    yield* decodeSseStream(response.stream);
  }
}