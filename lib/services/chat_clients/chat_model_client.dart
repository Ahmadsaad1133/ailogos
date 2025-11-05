import '../../services/service_exceptions.dart';
import 'chat_types.dart';

/// A streaming chat completion client that can talk to a specific provider.
abstract class ChatModelClient {
  /// A short identifier that is used for logging and circuit breaking.
  String get id;

  /// Whether this client is currently able to send requests (e.g. API key available).
  bool get isConfigured;

  /// Sends a chat completion request and returns a stream of chunks.
  ///
  /// Implementations must throw [MissingApiKeyException] if the client is not
  /// properly configured and [ProviderException] for HTTP/API failures.
  Stream<ChatCompletionChunk> streamChatCompletion(ChatRequest request);
}