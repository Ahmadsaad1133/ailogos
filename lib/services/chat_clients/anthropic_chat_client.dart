import 'dart:convert';

import 'package:http/http.dart' as http;

import '../service_exceptions.dart';
import 'chat_model_client.dart';
import 'chat_types.dart';
import 'sse_stream_decoder.dart';

/// Streaming chat client for Anthropic's Messages API.
class AnthropicChatClient implements ChatModelClient {
  AnthropicChatClient({
    required this.apiKey,
    required this.model,
    this.version = '2023-06-01',
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String apiKey;
  final String model;
  final String version;
  final http.Client _client;

  @override
  String get id => 'anthropic';

  @override
  bool get isConfigured => apiKey.isNotEmpty && model.isNotEmpty;

  @override
  Stream<ChatCompletionChunk> streamChatCompletion(ChatRequest request) async* {
    if (!isConfigured) {
      throw const MissingApiKeyException(
        message: 'Missing Anthropic API key. Configure ANTHROPIC_API_KEY.',
      );
    }

    final uri = Uri.parse('https://api.anthropic.com/v1/messages');
    final messages = request.messages
        .map((m) => {
      'role': m.role == 'assistant' ? 'assistant' : 'user',
      'content': m.content,
    })
        .toList();

    final payload = <String, dynamic>{
      'model': model,
      'messages': messages,
      'stream': true,
      if (request.maxTokens != null) 'max_tokens': request.maxTokens,
      if (request.temperature != null) 'temperature': request.temperature,
      ...request.extraParams,
    };

    final http.Request httpRequest = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': version,
      })
      ..body = jsonEncode(payload);

    final http.StreamedResponse response;
    try {
      response = await _client.send(httpRequest);
    } catch (e) {
      throw AppServiceException('Anthropic request failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw ProviderException(
        message: 'Anthropic error ${response.statusCode}: $body',
        statusCode: response.statusCode,
      );
    }

    yield* decodeSseStream(response.stream);
  }
}