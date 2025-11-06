import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:typed_data';

class SleepSoundMix {
  const SleepSoundMix({
    required this.id,
    required this.title,
    required this.layers,
    required this.durationSeconds,
    required this.loopEnabled,
    required this.mixRatio,
    required this.storagePath,
    required this.downloadUrl,
    required this.createdAt,
    this.bytes,
  });

  factory SleepSoundMix.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return SleepSoundMix(
      id: doc.id,
      title: data['title'] as String? ?? 'Custom mix',
      layers: List<String>.from(data['layers'] as List<dynamic>? ?? const []),
      durationSeconds: (data['durationSeconds'] as num?)?.toDouble() ?? 0,
      loopEnabled: data['loopEnabled'] as bool? ?? false,
      mixRatio: (data['mixRatio'] as num?)?.toDouble() ?? 1.0,
      storagePath: data['storagePath'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now(),
      bytes: null,
    );
  }

  final String id;
  final String title;
  final List<String> layers;
  final double durationSeconds;
  final bool loopEnabled;
  final double mixRatio;
  final String storagePath;
  final String downloadUrl;
  final DateTime createdAt;
  final Uint8List? bytes;

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'layers': layers,
      'durationSeconds': durationSeconds,
      'loopEnabled': loopEnabled,
      'mixRatio': mixRatio,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}