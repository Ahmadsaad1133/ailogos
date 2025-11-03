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

  Map<String, dynamic> toJson() => {
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
      model: json['model'] as String? ?? 'gpt-image-1',
      imageBase64: json['imageBase64'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
