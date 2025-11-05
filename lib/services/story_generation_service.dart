import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/story_record.dart';
import 'service_exceptions.dart';

/// Service responsible for talking to Groq and crafting stories.
class StoryGenerationService {
  final String apiKey;
  final String modelId;
  final http.Client _client;

  StoryGenerationService({
    required this.apiKey,
    required this.modelId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Generate a story from a prompt.
  ///
  /// [genre]: optional label like "Fantasy", "Horror"...
  /// [lengthLabel]: "Short", "Medium", "Long" (from UI).
  /// [continueStory]: if true, the model continues [previousStory].
  Future<StoryRecord> craftStory({
    required String prompt,
    String? genre,
    String? lengthLabel,
    bool continueStory = false,
    String? previousStory,
    String? userName,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw const AppServiceException('Prompt cannot be empty.');
    }
    if (apiKey.isEmpty) {
      throw const AppServiceException('Missing Groq API key.');
    }

    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    // Map "Short / Medium / Long" to explicit length instructions + token limits.
    final _LengthConfig lengthConfig = _resolveLengthConfig(lengthLabel);

    final buffer = StringBuffer();

    if (continueStory && (previousStory?.isNotEmpty ?? false)) {
      buffer.writeln(
          'Continue the following story in a smooth, natural way, without repeating the existing text:');
      buffer.writeln(previousStory!.trim());
      buffer.writeln();
      buffer.writeln('Now continue the story based on this user request:');
      buffer.writeln(trimmed);
    } else {
      buffer.writeln('Write a bedtime story based on this request:');
      buffer.writeln(trimmed);
    }

    if (genre != null && genre.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Genre: $genre');
    }

    final userContent = buffer.toString().trim();

    final systemContent = StringBuffer()
      ..writeln(
          'You are a creative Lebanese-friendly storyteller named OBSDIV Story Engine.')
      ..writeln(
          'You write cozy, engaging bedtime stories with clear paragraphs and good pacing.')
      ..writeln(
          'Use simple, modern language that is easy and pleasant to read. Keep paragraphs short.')
      ..writeln(
          'Do NOT add introductions like "Here is your story". Start directly with the story.')
      ..writeln('Avoid disclaimers and meta comments.')
      ..writeln()
      ..writeln('LENGTH PROFILE (very important):')
      ..writeln(lengthConfig.instruction)
      ..writeln(
          'Very important: strictly respect the requested length profile (paragraph count and approximate length).')
      ..writeln('The output must be pure story text, ready for reading.');

    if (userName != null && userName.isNotEmpty) {
      systemContent.writeln(
          'The user is called "$userName". You may occasionally personalize the story using their name.');
    }

    final body = <String, dynamic>{
      'model': modelId,
      'messages': [
        {
          'role': 'system',
          'content': systemContent.toString(),
        },
        {
          'role': 'user',
          'content': userContent,
        },
      ],
      // Shorter stories get fewer tokens, longer stories get more.
      'temperature': 0.95,
      'max_tokens': lengthConfig.maxTokens,
    };

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.body.isEmpty
          ? 'Groq error ${response.statusCode}'
          : 'Groq error ${response.statusCode}: ${response.body}';
      throw AppServiceException(message);
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AppServiceException('Unexpected Groq response format.');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const AppServiceException('Groq did not return any choices.');
    }

    final choice = choices.first;
    final content = choice['message']?['content'] as String? ?? '';
    final storyText = _normalizeStoryText(trimmed, content);

    final now = DateTime.now();
    return StoryRecord(
      id: now.microsecondsSinceEpoch.toString(),
      prompt: trimmed,
      model: modelId,
      story: storyText,
      createdAt: now,
      genre: genre,
      lengthLabel: lengthLabel,
    );
  }

  /// Cleans model output (removes echoed prompt or labels if present).
  String _normalizeStoryText(String prompt, String raw) {
    var text = raw.trim();

    // If the model starts by echoing the prompt, remove it.
    final lowerPrompt = prompt.toLowerCase();
    final lowerText = text.toLowerCase();
    if (lowerText.startsWith(lowerPrompt)) {
      text = text.substring(prompt.length).trimLeft();
    }

    // Remove obvious labels like "Story:", "Bedtime story:", etc.
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
        '- Very short bedtime story.\n'
            '- About 3–5 short paragraphs.\n'
            '- Roughly 250–400 words.\n'
            '- End the story clearly within this range.',
        maxTokens: 450,
      );
    }
    if (normalized == 'long') {
      return const _LengthConfig(
        instruction:
        '- Long, detailed bedtime story.\n'
            '- Around 12–20 paragraphs.\n'
            '- Roughly 1500–2200 words.\n'
            '- Develop characters and events but still finish the story.',
        maxTokens: 2000,
      );
    }
    // Default: Medium
    return const _LengthConfig(
      instruction:
      '- Medium-length bedtime story.\n'
          '- About 6–10 paragraphs.\n'
          '- Roughly 700–1200 words.\n'
          '- The story must have a clear beginning, middle, and end.',
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
