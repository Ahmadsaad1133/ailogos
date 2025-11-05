import 'story_record.dart';

/// Represents streaming progress when generating a story.
class StoryProgress {
  StoryProgress({
    required this.providerId,
    required this.buffer,
    this.record,
    this.isComplete = false,
  });

  final String providerId;
  final String buffer;
  final StoryRecord? record;
  final bool isComplete;

  StoryProgress copyWith({
    String? providerId,
    String? buffer,
    StoryRecord? record,
    bool? isComplete,
  }) {
    return StoryProgress(
      providerId: providerId ?? this.providerId,
      buffer: buffer ?? this.buffer,
      record: record ?? this.record,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}