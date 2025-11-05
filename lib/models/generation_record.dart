import 'story_record.dart';

/// Backwards-compatible type used across the app.
/// Any place that used [GenerationRecord] before will now
/// actually be using [StoryRecord] under the hood.
typedef GenerationRecord = StoryRecord;
