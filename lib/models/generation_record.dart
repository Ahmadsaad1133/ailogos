import 'dart:convert';
import 'dart:typed_data';

/// Represents a single generated image entry in history.
class GenerationRecord {
  final String id;
  final String prompt;
  final String model;
  final String imageBase64;
  final DateTime createdAt;

  const GenerationRecord({
    required this.id,
    required this.prompt,
    required this.model,
    required this.imageBase64,
    required this.createdAt,
  });

  /// Convenience getter to get raw image bytes.
  Uint8List get imageBytes => base64Decode(imageBase64);

  GenerationRecord copyWith({
    String? id,
    String? prompt,
    String? model,
    String? imageBase64,
    DateTime? createdAt,
  }) {
    return GenerationRecord(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      model: model ?? this.model,
      imageBase64: imageBase64 ?? this.imageBase64,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'prompt': prompt,
    'model': model,
    'imageBase64': imageBase64,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GenerationRecord.fromJson(Map<String, dynamic> json) {
    return GenerationRecord(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      model: json['model'] as String? ?? 'unknown',
      imageBase64: json['imageBase64'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Helper to build a record directly from raw HF image bytes.
  factory GenerationRecord.fromBytes({
    required String id,
    required String prompt,
    required String model,
    required List<int> bytes,
    DateTime? createdAt,
  }) {
    return GenerationRecord(
      id: id,
      prompt: prompt,
      model: model,
      imageBase64: base64Encode(bytes),
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
