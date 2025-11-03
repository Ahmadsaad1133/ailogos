import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../themes/colors.dart';

class GeneratedImageCard extends StatelessWidget {
  const GeneratedImageCard({
    super.key,
    required this.imageBytes,
    required this.prompt,
    this.onTap,
    this.footer,
    this.heroTag,
  });

  final Uint8List imageBytes;
  final String prompt;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: heroTag ?? prompt,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}