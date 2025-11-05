class PersonaPreset {
  final String key;
  final String label;
  final String instruction;

  const PersonaPreset({
    required this.key,
    required this.label,
    required this.instruction,
  });
}

/// ثابت: كل الـ personas المتاحة بالواجهة
const List<PersonaPreset> personaPresets = [
  PersonaPreset(
    key: 'default_soft',
    label: 'Soft narrator',
    instruction:
    'Write in a calm, soft bedtime tone. Simple sentences, warm and relaxing.',
  ),
  PersonaPreset(
    key: 'leb_dialect',
    label: 'Lebanese Arabic',
    instruction:
    'Write the story using Lebanese Arabic dialect (Arabizi not required) in a friendly, cozy style.',
  ),
  PersonaPreset(
    key: 'fantasy_mentor',
    label: 'Fantasy mentor',
    instruction:
    'Narrate like a wise mentor in a fantasy world. Add gentle magic and wonder, but keep it relaxing.',
  ),
  PersonaPreset(
    key: 'light_horror',
    label: 'Light horror',
    instruction:
    'Tell a slightly spooky story with suspense, but avoid anything too disturbing or graphic.',
  ),
];
