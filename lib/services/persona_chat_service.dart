import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'chat_clients/chat_model_client.dart';
import 'chat_clients/chat_types.dart';
import 'chat_clients/circuit_breaker.dart';
import 'service_exceptions.dart';

class PersonaStreamEvent {
  const PersonaStreamEvent({
    required this.providerId,
    required this.buffer,
    this.isComplete = false,
  });

  final String providerId;
  final String buffer;
  final bool isComplete;
}

class PersonaChatService {
  PersonaChatService({
    required List<ChatModelClient> clients,
    this.maxRetriesPerClient = 1,
    this.baseBackoff = const Duration(milliseconds: 400),
  })  : _clients = clients,
        _breakers = {
          for (final client in clients) client.id: CircuitBreaker(),
        };

  final List<ChatModelClient> _clients;
  final Map<String, CircuitBreaker> _breakers;
  final int maxRetriesPerClient;
  final Duration baseBackoff;

  Stream<PersonaStreamEvent> sendMessage({
    required PersonaPreset persona,
    required List<ChatMessageModel> history,
    required String userMessage,
  }) async* {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      throw const AppServiceException('Message cannot be empty');
    }

    final systemMessage = ChatMessage(
      role: 'system',
      content: persona.systemPrompt,
    );
    final messageHistory = history
        .map((e) => ChatMessage(role: e.role, content: e.text))
        .toList(growable: true)
      ..add(ChatMessage(role: 'user', content: trimmed));
    final messages = [systemMessage, ...messageHistory];
    final request = ChatRequest(
      messages: messages,
      temperature: 0.85,
      extraParams: {'top_p': 0.9},
    );

    final errors = <String>[];
    for (final client in _clients) {
      if (!client.isConfigured) {
        errors.add('${client.id}: not configured');
        continue;
      }
      final breaker = _breakers[client.id]!;
      if (breaker.isOpen) {
        errors.add('${client.id}: circuit open');
        continue;
      }

      for (int attempt = 0; attempt <= maxRetriesPerClient; attempt++) {
        try {
          String buffer = '';
          await for (final chunk in client.streamChatCompletion(request)) {
            if (chunk.delta.isNotEmpty) {
              buffer += chunk.delta;
              yield PersonaStreamEvent(
                providerId: client.id,
                buffer: buffer,
              );
            }
          }
          breaker.recordSuccess();
          yield PersonaStreamEvent(
            providerId: client.id,
            buffer: buffer,
            isComplete: true,
          );
          return;
        } on MissingApiKeyException catch (e) {
          errors.add('${client.id}: ${e.message}');
          breaker.recordFailure();
          break;
        } on ProviderException catch (e) {
          errors.add('${client.id}: ${e.message}');
          breaker.recordFailure();
        } on AppServiceException catch (e) {
          errors.add('${client.id}: ${e.message}');
          breaker.recordFailure();
        } catch (e) {
          errors.add('${client.id}: $e');
          breaker.recordFailure();
        }

        if (attempt < maxRetriesPerClient) {
          await breaker.waitBeforeRetry(attempt, baseDelay: baseBackoff);
        }
      }
    }

    throw AppServiceException('Persona chat failed: ${errors.join('; ')}');
  }
}