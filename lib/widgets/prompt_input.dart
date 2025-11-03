import 'package:flutter/material.dart';

class PromptInput extends StatelessWidget {
  const PromptInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Describe your vision', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 5,
          minLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted(),
          decoration: const InputDecoration(
            hintText: 'E.g. Neon-lit city skyline with holographic billboards and rain...',
          ),
        ),
      ],
    );
  }
}