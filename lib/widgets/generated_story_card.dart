import 'package:flutter/material.dart';

import '../themes/colors.dart';

class GeneratedStoryCard extends StatelessWidget {
  const GeneratedStoryCard({
    super.key,
    required this.title,
    required this.story,
    this.onTap,
    this.footer,
    this.heroTag,
  });

  final String title;
  final String story;
  final VoidCallback? onTap;
  final Widget? footer;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            width: 1.4,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.36),
              blurRadius: 32,
              spreadRadius: -12,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withOpacity(0.7),
                  AppColors.surfaceElevated.withOpacity(0.95),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: heroTag ?? title,
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    story,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 12),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}