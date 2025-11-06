import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceNarration {
  const VoiceNarration({
    required this.id,
    required this.text,
    required this.voiceStyle,
    required this.pitch,
    required this.rate,
    required this.storagePath,
    required this.downloadUrl,
    required this.createdAt,
    required this.durationSeconds,
  });

  factory VoiceNarration.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return VoiceNarration(
      id: doc.id,
      text: data['text'] as String? ?? '',
      voiceStyle: data['voiceStyle'] as String? ?? 'default',
      pitch: (data['pitch'] as num?)?.toDouble() ?? 1.0,
      rate: (data['rate'] as num?)?.toDouble() ?? 1.0,
      storagePath: data['storagePath'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now(),
      durationSeconds: (data['durationSeconds'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String text;
  final String voiceStyle;
  final double pitch;
  final double rate;
  final String storagePath;
  final String downloadUrl;
  final DateTime createdAt;
  final double durationSeconds;

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'voiceStyle': voiceStyle,
      'pitch': pitch,
      'rate': rate,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'durationSeconds': durationSeconds,
    };
  }
}