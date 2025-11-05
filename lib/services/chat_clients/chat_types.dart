import 'package:meta/meta.dart';

/// A chat message sent to the language model.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;

  Map<String, String> toMap() => {
    'role': role,
    'content': content,
  };
}

/// A chunk of streamed completion text.
@immutable
class ChatCompletionChunk {
  const ChatCompletionChunk({
    required this.delta,
    this.done = false,
    this.raw,
  });

  final String delta;
  final bool done;
  final Map<String, dynamic>? raw;
}

/// Encapsulates a chat completion request that can be sent to
/// multiple providers.
@immutable
class ChatRequest {
  const ChatRequest({
    required this.messages,
    this.maxTokens,
    this.temperature,
    this.extraParams = const <String, dynamic>{},
  });

  final List<ChatMessage> messages;
  final int? maxTokens;
  final double? temperature;
  final Map<String, dynamic> extraParams;
}