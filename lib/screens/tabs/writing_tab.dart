import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creative_workspace_state.dart';
import '../../models/writing_piece.dart';
import '../../widgets/animated_glow_button.dart';

class WritingTab extends StatefulWidget {
  const WritingTab({super.key});

  @override
  State<WritingTab> createState() => _WritingTabState();
}

class _WritingTabState extends State<WritingTab> {
  final TextEditingController _promptController = TextEditingController();
  WritingCategory _category = WritingCategory.story;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate(CreativeWorkspaceState state) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await state.generateWriting(category: _category, prompt: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<CreativeWorkspaceState>();
    final theme = Theme.of(context);

    final latest = workspace.latestWriting;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a format and let OBSDIV craft your content.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: WritingCategory.values
                .map(
                  (category) => ChoiceChip(
                label: Text(category.label),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'What should we write?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedGlowButton(
            label: 'Generate ${_category.label.toLowerCase()}',
            icon: Icons.auto_fix_high_rounded,
            isBusy: workspace.isGeneratingWriting,
            onPressed: () => _generate(workspace),
          ),
          if (workspace.writingError != null) ...[
            const SizedBox(height: 8),
            Text(
              workspace.writingError!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          if (latest != null)
            _WritingPreviewCard(
              piece: latest,
              title: 'Latest ${latest.category.label}',
            ),
          const SizedBox(height: 24),
          if (workspace.writingLibrary.isNotEmpty) ...[
            Text('Saved pieces', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...workspace.writingLibrary.take(5).map(
                  (piece) => _WritingPreviewCard(
                piece: piece,
                title: piece.title,
                compact: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WritingPreviewCard extends StatelessWidget {
  const _WritingPreviewCard({
    required this.piece,
    required this.title,
    this.compact = false,
  });

  final WritingPiece piece;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = piece.content.trim();
    final snippet =
    content.length > 320 ? '${content.substring(0, 320)}…' : content;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface.withOpacity(0.94),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            snippet,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            maxLines: compact ? 6 : null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Saved ${piece.category.label}',
              style:
              theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
            ),
          ),
        ],
      ),
    );
  }
}