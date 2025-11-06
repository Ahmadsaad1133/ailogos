import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
/// Represents a single generated story entry in history.
class StoryRecord {
  final String id;
  final String prompt;
  final String model;
  final String story;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Whether the user marked this story as a favorite.
  final bool isFavorite;

  /// Optional genre label, e.g. "Fantasy", "Romance", etc.
  final String? genre;

  /// Optional length label, e.g. "Short", "Medium", "Long".
  final String? lengthLabel;

  StoryRecord({
    required this.id,
    required this.prompt,
    required this.model,
    required this.story,
    required this.createdAt,
    DateTime? updatedAt,
    this.isFavorite = false,
    this.genre,
    this.lengthLabel,
  }) : updatedAt = (updatedAt ?? createdAt).toUtc();


  StoryRecord copyWith({
    String? id,
    String? prompt,
    String? model,
    String? story,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
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
      'updatedAt': updatedAt.toIso8601String(),
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
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: parseDate(json['updatedAt']) ??
          DateTime.parse(json['createdAt'] as String).toUtc(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      genre: json['genre'] as String?,
      lengthLabel: json['lengthLabel'] as String?,
    );
  }
  Map<String, dynamic> toFirestoreJson(String userId) {
    return {
      'prompt': prompt,
      'model': model,
      'story': story,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
      'genre': genre,
      'lengthLabel': lengthLabel,
    };
  }

  factory StoryRecord.fromFirestore(
      Map<String, dynamic> json,
      String id,
      ) {
    return StoryRecord(
      id: id,
      prompt: json['prompt'] as String? ?? '',
      model: json['model'] as String? ?? 'unknown',
      story: json['story'] as String? ?? '',
      createdAt: parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: parseDate(json['updatedAt']) ??
          parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
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
        .map<StoryRecord>(
          (e) => StoryRecord.fromJson(e as Map<String, dynamic>),
    )
        .toList();
  }
  static DateTime? parseDate(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
