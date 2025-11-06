import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../themes/colors.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';
import 'sign_in_screen.dart';
import 'sign_out_screen.dart';
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
            Text('Account', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildAccountSection(appState, theme),
            const SizedBox(height: 32),
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
  Widget _buildAccountSection(AppState appState, ThemeData theme) {

    if (appState.isAuthenticated) {
      final user = appState.authUser;
      final email = user?.email ?? 'Signed in';
      final name = user?.displayName ?? appState.displayName;
      return _InfoCard(
        icon: Icons.verified_user_rounded,
        trailing: FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pushNamed(SignOutScreen.routeName),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
        title: name,
        message: '$email\nYour stories and settings stay synced securely.',
      );
    }

    return _InfoCard(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Sign in to sync',
      message:
      'Use your email and password to back up history, favorites, and preferences.',
      trailing: FilledButton.icon(
        onPressed: () =>
            Navigator.of(context).pushNamed(SignInScreen.routeName),
        icon: const Icon(Icons.login_rounded),
        label: const Text('Sign in'),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.message,
    this.title,
    this.trailing,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface.withOpacity(0.9),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
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