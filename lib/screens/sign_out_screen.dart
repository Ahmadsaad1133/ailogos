import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class SignOutScreen extends StatefulWidget {
  const SignOutScreen({super.key});

  static const routeName = '/auth/sign-out';

  @override
  State<SignOutScreen> createState() => _SignOutScreenState();
}

class _SignOutScreenState extends State<SignOutScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final user = appState.authUser;
    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_settings.svg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Sign out'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _buildContent(context, theme, user, appState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      ThemeData theme,
      User? user,
      AppState appState,
      ) {
    if (user == null) {
      return _InfoMessage(
        icon: Icons.logout_rounded,
        title: 'You are already signed out',
        message:
        'Sign in again to keep your neon history and preferences in sync across devices.',
        primaryAction: FilledButton.icon(
          onPressed: () => Navigator.of(context)
              .pushReplacementNamed(SignInScreen.routeName),
          icon: const Icon(Icons.login_rounded),
          label: const Text('Go to sign in'),
        ),
        secondaryAction: TextButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(HomeScreen.routeName),
          child: const Text('Return home'),
        ),
      );
    }

    final email = user.email ?? 'Signed in';
    final name = user.displayName ?? appState.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        const BrandedLogo(size: 120, variant: LogoVariant.watermark),
        const SizedBox(height: 16),
        Text('Sign out of your account',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'You are currently signed in as $name\n$email',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_done_rounded,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your stories, favorites, and profile settings are linked to this account.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Signing out keeps your data safe. You can sign in again anytime to continue where you left off.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _isProcessing ? null : () => _confirmSignOut(context),
          icon: _isProcessing
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.logout_rounded),
          label: Text(_isProcessing ? 'Signing out…' : 'Sign out'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(HomeScreen.routeName),
          child: const Text('Stay signed in'),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    setState(() => _isProcessing = true);
    try {
      final authService = context.read<AuthService>();
      await authService.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully.')),
      );
      Navigator.of(context)
          .pushReplacementNamed(SignInScreen.routeName);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      } else {
        _isProcessing = false;
      }
    }
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryAction,
    this.secondaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget primaryAction;
  final Widget? secondaryAction;

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
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(icon, size: 48, color: theme.colorScheme.primary),
    const SizedBox(height: 16),
    Text(title, style: theme.textTheme.titleMedium,
    textAlign: TextAlign.center),
          const SizedBox(height: 12),
    Text(message,
    style: theme.textTheme.bodyMedium,
    textAlign: TextAlign.center),
    const SizedBox(height: 20),
    primaryAction,
    if (secondaryAction != null) ...[
    const SizedBox(height: 12),
    secondaryAction!,
    ],
        ],
    ),
    );
  }
}