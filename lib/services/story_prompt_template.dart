class StoryPromptTemplate {
  StoryPromptTemplate({this.userName});

  static const int version = 1;
  static const String versionTag = '[story_prompt:v$version]';

  static const String personaLine =
      'You are a creative Lebanese-friendly storyteller named OBSDIV Story Engine.';
  static const String styleLine =
      'You write cozy, engaging bedtime stories with clear paragraphs and good pacing.';
  static const String languageLine =
      'Use simple, modern language that is easy and pleasant to read. Keep paragraphs short.';
  static const String introRuleLine =
      'Do NOT add introductions like "Here is your story". Start directly with the story.';
  static const String disclaimerRuleLine = 'Avoid disclaimers and meta comments.';
  static const String lengthHeading = 'LENGTH PROFILE (very important):';
  static const String outputRuleLine = 'The output must be pure story text, ready for reading.';

  final String? userName;

  String buildSystemPrompt({
    required String lengthInstruction,
  }) {
    final buffer = StringBuffer()
      ..writeln(versionTag)
      ..writeln(personaLine)
      ..writeln(styleLine)
      ..writeln(languageLine)
      ..writeln(introRuleLine)
      ..writeln(disclaimerRuleLine)
      ..writeln()
      ..writeln(lengthHeading)
      ..writeln(lengthInstruction)
      ..writeln(
          'Very important: strictly respect the requested length profile (paragraph count and approximate length).')
      ..writeln(outputRuleLine);

    if (userName != null && userName!.isNotEmpty) {
      buffer.writeln(
          'The user is called "${userName!}". You may occasionally personalize the story using their name.');
    }

    return buffer.toString().trim();
  }

  String buildUserPrompt({
    required String prompt,
    String? genre,
    bool continueStory = false,
    String? previousStory,
  }) {
    final buffer = StringBuffer();

    if (continueStory && (previousStory?.isNotEmpty ?? false)) {
      buffer.writeln(
          'Continue the following story in a smooth, natural way, without repeating the existing text:');
      buffer.writeln(previousStory!.trim());
      buffer.writeln();
      buffer.writeln('Now continue the story based on this user request:');
      buffer.writeln(prompt);
    } else {
      buffer.writeln('Write a bedtime story based on this request:');
      buffer.writeln(prompt);
    }

    if (genre != null && genre.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Genre: $genre');
    }

    return buffer.toString().trim();
  }
}