import 'dart:convert';

import 'package:http/http.dart' as http;

import '../service_exceptions.dart';
import 'chat_model_client.dart';
import 'chat_types.dart';
import 'sse_stream_decoder.dart';

/// Streaming chat client for OpenAI's Chat Completions API.
class OpenAIChatClient implements ChatModelClient {
  OpenAIChatClient({
    required this.apiKey,
    required this.model,
    this.organization,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String apiKey;
  final String model;
  final String? organization;
  final http.Client _client;

  @override
  String get id => 'openai';

  @override
  bool get isConfigured => apiKey.isNotEmpty && model.isNotEmpty;

  @override
  Stream<ChatCompletionChunk> streamChatCompletion(ChatRequest request) async* {
    if (!isConfigured) {
      throw const MissingApiKeyException(
        message: 'Missing OpenAI API key. Configure OPENAI_API_KEY.',
      );
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final payload = <String, dynamic>{
      'model': model,
      'messages': request.messages.map((m) => m.toMap()).toList(),
      'stream': true,
      if (request.maxTokens != null) 'max_tokens': request.maxTokens,
      if (request.temperature != null) 'temperature': request.temperature,
      ...request.extraParams,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    if (organization != null && organization!.isNotEmpty) {
      headers['OpenAI-Organization'] = organization!;
    }

    final http.Request httpRequest = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..body = jsonEncode(payload);

    final http.StreamedResponse response;
    try {
      response = await _client.send(httpRequest);
    } catch (e) {
      throw AppServiceException('OpenAI request failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw ProviderException(
        message: 'OpenAI error ${response.statusCode}: $body',
        statusCode: response.statusCode,
      );
    }

    yield* decodeSseStream(response.stream);
  }
}