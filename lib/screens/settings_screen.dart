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
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isAuthenticating = false;
  @override
  void initState() {
    super.initState();
    final displayName = context.read<AppState>().displayName;
    _nameController = TextEditingController(text: displayName);
    final authUser = context.read<AppState>().authUser;
    _emailController = TextEditingController(text: authUser?.email ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    if (!appState.authAvailable) {
      return _InfoCard(
        icon: Icons.cloud_off_rounded,
        message:
        'Cloud sync is disabled because no Supabase project is configured. Stories stay on this device only.',
      );
    }

    if (appState.isAuthenticated) {
      final user = appState.authUser;
      final email = user?.email ?? 'Signed in';
      final name = user?.displayName ?? appState.displayName;
      return _InfoCard(
        icon: Icons.verified_user_rounded,
        trailing: FilledButton.icon(
          onPressed: _isAuthenticating ? null : () => _signOut(appState),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
        title: name,
        message: '$email\nStories & favorites sync automatically.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign in to sync your stories & favorites across devices.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          enabled: !_isAuthenticating,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: !_isAuthenticating,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed:
          _isAuthenticating ? null : () => _signInWithEmail(appState),
          icon: _isAuthenticating
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.mail_outline_rounded),
          label: Text(_isAuthenticating ? 'Signing in…' : 'Sign in with email'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.3))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('or'),
            ),
            Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed:
              _isAuthenticating ? null : () => _signInWithGoogle(appState),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: const Text('Google'),
            ),
            OutlinedButton.icon(
              onPressed:
              _isAuthenticating ? null : () => _signInWithApple(appState),
              icon: const Icon(Icons.apple_rounded),
              label: const Text('Apple'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _signInWithEmail(AppState appState) async {
    FocusScope.of(context).unfocus();
    setState(() => _isAuthenticating = true);
    try {
      await appState.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your inbox if this is a new sign in.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      } else {
        _isAuthenticating = false;
      }
    }
  }

  Future<void> _signInWithGoogle(AppState appState) async {
    FocusScope.of(context).unfocus();
    setState(() => _isAuthenticating = true);
    try {
      await appState.signInWithGoogle();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      } else {
        _isAuthenticating = false;
      }
    }
  }

  Future<void> _signInWithApple(AppState appState) async {
    FocusScope.of(context).unfocus();
    setState(() => _isAuthenticating = true);
    try {
      await appState.signInWithApple();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      } else {
        _isAuthenticating = false;
      }
    }
  }

  Future<void> _signOut(AppState appState) async {
    FocusScope.of(context).unfocus();
    setState(() => _isAuthenticating = true);
    try {
      await appState.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      } else {
        _isAuthenticating = false;
      }
    }
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