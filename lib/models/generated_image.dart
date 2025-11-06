import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class GeneratedImage {
  const GeneratedImage({
    required this.id,
    required this.prompt,
    required this.provider,
    required this.storagePath,
    required this.downloadUrl,
    required this.createdAt,
    required this.index,
    this.width,
    this.height,
    this.bytes,
  });

  factory GeneratedImage.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return GeneratedImage(
      id: doc.id,
      prompt: data['prompt'] as String? ?? '',
      provider: data['provider'] as String? ?? 'unknown',
      storagePath: data['storagePath'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now(),
      index: (data['index'] as num?)?.toInt() ?? 0,
      width: (data['width'] as num?)?.toInt(),
      height: (data['height'] as num?)?.toInt(),
    );
  }

  final String id;
  final String prompt;
  final String provider;
  final String storagePath;
  final String downloadUrl;
  final DateTime createdAt;
  final int index;
  final int? width;
  final int? height;

  final Uint8List? bytes;

  GeneratedImage copyWith({
    String? id,
    String? prompt,
    String? provider,
    String? storagePath,
    String? downloadUrl,
    DateTime? createdAt,
    int? index,
    int? width,
    int? height,
    Uint8List? bytes,
  }) {
    return GeneratedImage(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      provider: provider ?? this.provider,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      createdAt: createdAt ?? this.createdAt,
      index: index ?? this.index,
      width: width ?? this.width,
      height: height ?? this.height,
      bytes: bytes ?? this.bytes,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'prompt': prompt,
      'provider': provider,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'index': index,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }
}