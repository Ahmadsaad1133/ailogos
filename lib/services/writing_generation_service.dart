import 'dart:math';

import '../models/writing_piece.dart';
import 'chat_clients/chat_model_client.dart';
import 'chat_clients/chat_types.dart';
import 'chat_clients/circuit_breaker.dart';
import 'service_exceptions.dart';

class WritingGenerationService {
  WritingGenerationService({
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

  Future<WritingPiece> generatePiece({
    required WritingCategory category,
    required String prompt,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw const AppServiceException('Please provide a prompt.');
    }

    final messages = [
      ChatMessage(role: 'system', content: _buildSystemPrompt(category)),
      ChatMessage(role: 'user', content: _buildUserPrompt(category, trimmed)),
    ];

    final request = ChatRequest(
      messages: messages,
      temperature: 0.9,
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
            }
          }
          breaker.recordSuccess();
          final now = DateTime.now();
          final content = _normalizeContent(buffer);
          final title = _deriveTitle(category, trimmed, content);
          return WritingPiece(
            id: now.microsecondsSinceEpoch.toString(),
            prompt: trimmed,
            category: category,
            title: title,
            content: content,
            createdAt: now,
          );
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

    throw AppServiceException(
        'Content generation failed: ${errors.join('; ')}');
  }

  String _buildSystemPrompt(WritingCategory category) {
    switch (category) {
      case WritingCategory.story:
        return 'You craft immersive, heartfelt short stories with vivid sensory details and emotional depth. Keep paragraphs short and engaging.';
      case WritingCategory.poem:
        return 'You are a lyrical poet. Compose evocative poetry with intentional line breaks and consistent rhythm. Avoid rhyming if the user does not request it.';
      case WritingCategory.blog:
        return 'You are a friendly blogging assistant. Write clear, structured blog posts with helpful subheadings, concise paragraphs, and actionable takeaways.';
      case WritingCategory.script:
        return 'You are a screenwriter. Produce screenplay-style dialogue with character labels, brief stage directions, and cinematic pacing.';
    }
  }

  String _buildUserPrompt(WritingCategory category, String prompt) {
    switch (category) {
      case WritingCategory.story:
        return 'Write a short story based on: $prompt';
      case WritingCategory.poem:
        return 'Write a poem inspired by: $prompt';
      case WritingCategory.blog:
        return 'Draft a blog post covering: $prompt';
      case WritingCategory.script:
        return 'Draft a short scene script about: $prompt';
    }
  }

  String _normalizeContent(String raw) {
    return raw.trim();
  }

  String _deriveTitle(
      WritingCategory category, String prompt, String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final firstNonEmpty =
    lines.firstWhere((element) => element.trim().isNotEmpty, orElse: () => prompt);
    final clean = firstNonEmpty.trim();
    if (clean.length <= 64) {
      return clean;
    }
    return clean.substring(0, min(clean.length, 64));
  }
}