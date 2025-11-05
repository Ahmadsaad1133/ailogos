import 'dart:async';
import 'package:powered_by_obsdiv/services/story_prompt_template.dart';

import '../models/story_progress.dart';
import '../models/story_record.dart';
import 'chat_clients/anthropic_chat_client.dart';
import 'chat_clients/chat_model_client.dart';
import 'chat_clients/chat_types.dart';
import 'chat_clients/circuit_breaker.dart';
import 'chat_clients/groq_chat_client.dart';
import 'chat_clients/openai_chat_client.dart';
import 'service_exceptions.dart';

/// Service responsible for crafting stories using one of the configured
/// provider clients.
class StoryGenerationService {

  StoryGenerationService({
    required List<ChatModelClient> clients,
    this.maxRetriesPerClient = 2,
    this.baseBackoff = const Duration(milliseconds: 400),
  })  : _clients = clients,
        _breakers = {
          for (final client in clients) client.id: CircuitBreaker(),
        };

  /// Convenience factory that wires up Groq/OpenAI/Anthropic clients.
  factory StoryGenerationService.fromEnvironment({
    String groqApiKey = '',
    String groqModel = '',
    String openAiKey = '',
    String openAiModel = '',
    String anthropicKey = '',
    String anthropicModel = '',
  }) {
    return StoryGenerationService(
      clients: [
        GroqChatClient(apiKey: groqApiKey, model: groqModel),
        OpenAIChatClient(apiKey: openAiKey, model: openAiModel),
        AnthropicChatClient(apiKey: anthropicKey, model: anthropicModel),
      ],
    );
  }

  final List<ChatModelClient> _clients;
  final Map<String, CircuitBreaker> _breakers;
  final int maxRetriesPerClient;
  final Duration baseBackoff;

  /// Generate a story and yield streaming progress updates. The final
  /// [StoryProgress] will contain a populated [StoryRecord].
  Stream<StoryProgress> craftStoryStream({
    required String prompt,
    String? genre,
    String? lengthLabel,
    bool continueStory = false,
    String? previousStory,
    String? userName,
  }) async* {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw const AppServiceException('Prompt cannot be empty.');
    }

    final _LengthConfig lengthConfig = _resolveLengthConfig(lengthLabel);
    final template = StoryPromptTemplate(userName: userName);

    final messages = [
      ChatMessage(
        role: 'system',
        content: template.buildSystemPrompt(
          lengthInstruction: lengthConfig.instruction,
        ),
      ),
      ChatMessage(
        role: 'user',
        content: template.buildUserPrompt(
          prompt: trimmed,
          genre: genre,
          continueStory: continueStory,
          previousStory: previousStory,
        ),
      ),
    ];

    final request = ChatRequest(
      messages: messages,
      maxTokens: lengthConfig.maxTokens,
      temperature: 0.95,
    );
    final List<String> errors = [];
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
              yield StoryProgress(providerId: client.id, buffer: buffer);
            }
          }

          final storyText = _normalizeStoryText(trimmed, buffer);
          final now = DateTime.now();
          final record = StoryRecord(
            id: now.microsecondsSinceEpoch.toString(),
            prompt: trimmed,
            model: client.id,
            story: storyText,
            createdAt: now,
            genre: genre,
            lengthLabel: lengthLabel,
          );
          breaker.recordSuccess();
          yield StoryProgress(
            providerId: client.id,
            buffer: storyText,
            record: record,
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

    final errorMessage =
    errors.isEmpty ? 'All providers unavailable.' : errors.join('; ');
    throw AppServiceException('Story generation failed: $errorMessage');
  }

  /// Blocking helper that consumes [craftStoryStream] and returns the final
  /// [StoryRecord]. This is kept for backwards compatibility.
  Future<StoryRecord> craftStory({
    required String prompt,
    String? genre,
    String? lengthLabel,
    bool continueStory = false,
    String? previousStory,
    String? userName,
  }) async {
    StoryRecord? record;
    await for (final progress in craftStoryStream(
    prompt: prompt,
      genre: genre,
      lengthLabel: lengthLabel,
      continueStory: continueStory,
      previousStory: previousStory,
      userName: userName,
    )) {
      if (progress.isComplete && progress.record != null) {
        record = progress.record;
      }
    }

    if (record == null) {
      throw const AppServiceException('Story generation did not complete.');
    }
    return record!;
  }

  /// Cleans model output (removes echoed prompt or labels if present).
  String _normalizeStoryText(String prompt, String raw) {
    var text = raw.trim();

    final lowerPrompt = prompt.toLowerCase();
    final lowerText = text.toLowerCase();
    if (lowerText.startsWith(lowerPrompt)) {
      text = text.substring(prompt.length).trimLeft();
    }

    const labels = [
      'story:',
      'bedtime story:',
      'chapter:',
    ];

    for (final label in labels) {
      final l = label.toLowerCase();
      if (text.toLowerCase().startsWith(l)) {
        text = text.substring(label.length).trimLeft();
        break;
      }
    }

    return text;
  }

  _LengthConfig _resolveLengthConfig(String? label) {
    final normalized = label?.toLowerCase().trim();
    if (normalized == 'short') {
      return const _LengthConfig(
        instruction:
        '- Very short bedtime story.\n- About 3–5 short paragraphs.\n- Roughly 250–400 words.\n- End the story clearly within this range.',
        maxTokens: 450,
      );
    }
    if (normalized == 'long') {
      return const _LengthConfig(
        instruction:
        '- Long, detailed bedtime story.\n- Around 12–20 paragraphs.\n- Roughly 1500–2200 words.\n- Develop characters and events but still finish the story.',
        maxTokens: 2000,
      );
    }
    return const _LengthConfig(
      instruction:
      '- Medium-length bedtime story.\n- About 6–10 paragraphs.\n- Roughly 700–1200 words.\n- The story must have a clear beginning, middle, and end.',
      maxTokens: 1200,
    );
  }
}

class _LengthConfig {
  final String instruction;
  final int maxTokens;

  const _LengthConfig({
    required this.instruction,
    required this.maxTokens,
  });
}
