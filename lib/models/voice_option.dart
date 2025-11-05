class TtsVoiceOption {
  const TtsVoiceOption({
    required this.id,
    required this.label,
    required this.modelId,
    required this.locale,
    this.description,
  });

  final String id;
  final String label;
  final String modelId;
  final String locale;
  final String? description;
}

class VoicePreference {
  const VoicePreference({
    required this.voiceId,
    required this.modelId,
  });

  final String voiceId;
  final String modelId;

  Map<String, dynamic> toJson() => {
    'voiceId': voiceId,
    'modelId': modelId,
  };

  static VoicePreference fromJson(Map<String, dynamic> json) {
    return VoicePreference(
      voiceId: json['voiceId'] as String? ?? 'Fritz-PlayAI',
      modelId: json['modelId'] as String? ?? 'playai-tts',
    );
  }
}