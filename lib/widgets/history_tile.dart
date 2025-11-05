import 'package:flutter/material.dart';

import '../models/generation_record.dart';
import 'branded_logo.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.record,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final GenerationRecord record;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rawStory = record.story.trim().replaceAll('\n', ' ');
    final snippet = rawStory.isEmpty
        ? 'Tap to read this story'
        : (rawStory.length > 90
        ? '${rawStory.substring(0, 90)}…'
        : rawStory);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface.withOpacity(0.9),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
              theme.colorScheme.primary.withOpacity(0.18),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 22,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatTimestamp(record.createdAt)} • ${record.model.toUpperCase()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                record.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: record.isFavorite
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
              ),
            ),
            const BrandedLogo(
              size: 32,
              variant: LogoVariant.icon,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }
}
