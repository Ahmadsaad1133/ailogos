import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/generation_record.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  static const routeName = '/result';

  @override
  Widget build(BuildContext context) {
    final record = ModalRoute.of(context)?.settings.arguments as GenerationRecord?;
    if (record == null) {
      return const _MissingRecord();
    }

    final theme = Theme.of(context);

    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_result.svg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Creation Result'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: BrandedLogo(size: 44, variant: LogoVariant.icon),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: record.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(24),
                      minScale: 0.8,
                      maxScale: 4,
                      child: Image.memory(
                        record.imageBytes,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Prompt', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(record.prompt, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ResultActionButton(
                    icon: Icons.save_alt_rounded,
                    label: 'Save to gallery',
                    onTap: () async {
                      try {
                        final path = await context.read<AppState>().saveImage(record);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved to $path')),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                  ),
                  _ResultActionButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Share creation',
                    onTap: () async {
                      try {
                        await context.read<AppState>().shareImage(record);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                  ),
                  _ResultActionButton(
                    icon: Icons.history_edu_rounded,
                    label: 'View history',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Model: ${record.model} · ${record.createdAt.toLocal().toIso8601String()}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultActionButton extends StatelessWidget {
  const _ResultActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surface.withOpacity(0.7),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MissingRecord extends StatelessWidget {
  const _MissingRecord();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_result.svg',
      child: const Center(
        child: Text('No result to display.'),
      ),
    );
  }
}