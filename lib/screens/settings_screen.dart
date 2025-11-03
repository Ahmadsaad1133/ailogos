import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../themes/colors.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final displayName = context.read<AppState>().displayName;
    _nameController = TextEditingController(text: displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final palette = <Color>[
      AppColors.accent,
      const Color(0xFF00E0FF),
      const Color(0xFFEC4899),
      const Color(0xFFFFC857),
      const Color(0xFF22C55E),
    ];

    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_settings.svg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: BrandedLogo(size: 42, variant: LogoVariant.watermark),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            Text('Profile', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'OBSDIV voyager name',
              ),
              onSubmitted: (value) => _updateName(value.trim()),
            ),
            const SizedBox(height: 24),
            Text('Neon Accent', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in palette)
                  _AccentSwatch(
                    color: color,
                    isSelected: color.value == appState.accentColor.value,
                    onTap: () => appState.updateAccent(color),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Version', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Powered by OBSDIV · 1.0.0', style: theme.textTheme.bodySmall),
            const SizedBox(height: 48),
            Text(
              'Tip: Keep your OpenAI API key secure. Provide it to the app via a secure configuration such as flutter_dotenv or platform secrets before release builds.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateName(String value) async {
    if (value.isEmpty) return;
    await context.read<AppState>().updateDisplayName(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name updated')),
      );
    }
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0.3)],
          ),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            width: isSelected ? 3 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 24,
              ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white)
            : const SizedBox.shrink(),
      ),
    );
  }
}