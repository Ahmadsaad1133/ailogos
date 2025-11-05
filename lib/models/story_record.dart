import 'dart:convert';

/// Represents a single generated story entry in history.
class StoryRecord {
  final String id;
  final String prompt;
  final String model;
  final String story;
  final DateTime createdAt;

  /// Whether the user marked this story as a favorite.
  final bool isFavorite;

  /// Optional genre label, e.g. "Fantasy", "Romance", etc.
  final String? genre;

  /// Optional length label, e.g. "Short", "Medium", "Long".
  final String? lengthLabel;

  const StoryRecord({
    required this.id,
    required this.prompt,
    required this.model,
    required this.story,
    required this.createdAt,
    this.isFavorite = false,
    this.genre,
    this.lengthLabel,
  });

  StoryRecord copyWith({
    String? id,
    String? prompt,
    String? model,
    String? story,
    DateTime? createdAt,
    bool? isFavorite,
    String? genre,
    String? lengthLabel,
  }) {
    return StoryRecord(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      model: model ?? this.model,
      story: story ?? this.story,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      genre: genre ?? this.genre,
      lengthLabel: lengthLabel ?? this.lengthLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'model': model,
      'story': story,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'genre': genre,
      'lengthLabel': lengthLabel,
    };
  }

  factory StoryRecord.fromJson(Map<String, dynamic> json) {
    return StoryRecord(
      id: json['id'] as String,
      prompt: json['prompt'] as String? ?? '',
      model: json['model'] as String? ?? 'unknown',
      story: json['story'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      genre: json['genre'] as String?,
      lengthLabel: json['lengthLabel'] as String?,
    );
  }

  static String encodeList(List<StoryRecord> records) {
    final list = records.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  static List<StoryRecord> decodeList(String source) {
    if (source.isEmpty) return const [];
    final dynamic data = jsonDecode(source);
    if (data is! List) return const [];
    return data
        .where((e) => e is Map<String, dynamic>)
        .map<StoryRecord>((e) => StoryRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
