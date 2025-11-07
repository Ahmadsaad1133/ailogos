

class VoiceNarration {
  const VoiceNarration({
    required this.id,
    required this.text,
    required this.voiceStyle,
    required this.pitch,
    required this.rate,
    required this.filePath,
    required this.createdAt,
    required this.durationSeconds,
  });

  factory VoiceNarration.fromJson(Map<String, dynamic> json) {
    return VoiceNarration(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      voiceStyle: json['voiceStyle'] as String? ?? 'default',
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
      filePath: json['filePath'] as String? ?? '',
      createdAt:
      DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String text;
  final String voiceStyle;
  final double pitch;
  final double rate;
  final String filePath;
  final DateTime createdAt;
  final double durationSeconds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'voiceStyle': voiceStyle,
      'pitch': pitch,
      'rate': rate,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }
}