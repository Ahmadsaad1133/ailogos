import 'dart:convert';
import 'chat_types.dart';

/// Utility that converts a Server-Sent Events (SSE) HTTP response body into
/// [ChatCompletionChunk] objects. This works for OpenAI/Groq style streaming
/// payloads where each event is encoded as a JSON line prefixed with `data:`.
Stream<ChatCompletionChunk> decodeSseStream(Stream<List<int>> byteStream) async* {
  // Decode bytes to text
  final textStream = byteStream.transform(utf8.decoder);
  // Split text into individual lines
  final lineStream = textStream.transform(const LineSplitter());

  await for (final line in lineStream) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed == 'data:') {
      continue;
    }

    if (trimmed == 'data: [DONE]' || trimmed == '[DONE]') {
      yield const ChatCompletionChunk(delta: '', done: true);
      break;
    }

    // Remove the 'data:' prefix if present
    final jsonPayload = trimmed.startsWith('data:')
        ? trimmed.substring('data:'.length).trim()
        : trimmed;

    if (jsonPayload.isEmpty) continue;

    try {
      final dynamic decoded = jsonDecode(jsonPayload);
      if (decoded is Map<String, dynamic>) {
        final delta = _extractDelta(decoded);
        yield ChatCompletionChunk(delta: delta, raw: decoded);
      }
    } catch (_) {
      // Skip invalid or non-JSON lines (heartbeats, etc.)
      continue;
    }
  }
}

String _extractDelta(Map<String, dynamic> payload) {
  if (payload.containsKey('delta')) {
    final delta = payload['delta'];
    if (delta is Map<String, dynamic>) {
      final content = delta['content'];
      if (content is String) return content;
      if (content is List) return content.whereType<String>().join();
    }
  }

  final choices = payload['choices'];
  if (choices is List && choices.isNotEmpty) {
    final choice = choices.first;
    if (choice is Map<String, dynamic>) {
      final delta = choice['delta'] ?? choice['message'];
      if (delta is Map<String, dynamic>) {
        final content = delta['content'];
        if (content is String) return content;
        if (content is List) return content.whereType<String>().join();
      }
    }
  }

  // Anthropic-style: {"type":"content_block_delta","delta":{"text":"..."}}
  final type = payload['type'];
  if (type is String && type == 'content_block_delta') {
    final delta = payload['delta'];
    if (delta is Map<String, dynamic>) {
      final text = delta['text'];
      if (text is String) return text;
    }
  }

  return '';
}
