import 'package:flutter/material.dart';

import '../models/generation_record.dart';
import 'branded_logo.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.record,
    required this.onTap,
  });

  final GenerationRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Hero(
          tag: record.id,
          child: Image.memory(
            record.imageBytes,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(record.prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${record.model.toUpperCase()} · ${_formatTimestamp(record.createdAt)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: const BrandedLogo(size: 36, variant: LogoVariant.icon),
    );
  }

  String _formatTimestamp(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }
}