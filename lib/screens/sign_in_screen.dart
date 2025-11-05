import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';
import 'sign_out_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const routeName = '/auth/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isProcessing = false;
  bool _hasNavigatedAfterAuth = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    _handleAuthenticatedNavigation(appState);

    final theme = Theme.of(context);

    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_settings.svg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Sign in'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: appState.authAvailable
              ? _buildContent(context, appState, theme)
              : _buildUnavailableState(context, theme),
        ),
      ),
    );
  }

  Widget _buildUnavailableState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandedLogo(size: 120, variant: LogoVariant.icon),
            const SizedBox(height: 24),
            Text(
              'Cloud sync is turned off',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add your Supabase credentials to enable email, Google, and Apple sign in.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(HomeScreen.routeName),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue offline'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, AppState appState, ThemeData theme) {
    if (appState.isAuthenticated) {
      final user = appState.authUser;
      final email = user?.email ?? 'Signed in';
      final name = user?.displayName ?? appState.displayName;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandedLogo(size: 120, variant: LogoVariant.icon),
              const SizedBox(height: 16),
              Text('You\'re signed in',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                '$name\n$email',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(HomeScreen.routeName),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Back to the app'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(SignOutScreen.routeName),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out instead'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        const SizedBox(height: 12),
        const BrandedLogo(size: 120, variant: LogoVariant.watermark),
        const SizedBox(height: 16),
        Text(
          'Sync your neon stories',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Use email or Google to sync history, favorites, and preferences across devices.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isProcessing,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          enabled: !_isProcessing,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed:
          _isProcessing ? null : () => _signInWithEmail(context, appState),
          icon: _isProcessing
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.mail_outline_rounded),
          label: Text(_isProcessing ? 'Signing in…' : 'Sign in with email'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child:
              Divider(color: theme.dividerColor.withOpacity(0.3), height: 1),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('or'),
            ),
            Expanded(
              child:
              Divider(color: theme.dividerColor.withOpacity(0.3), height: 1),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed:
              _isProcessing ? null : () => _signInWithGoogle(context, appState),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: const Text('Sign in with Google'),
            ),
            OutlinedButton.icon(
              onPressed:
              _isProcessing ? null : () => _signInWithApple(context, appState),
              icon: const Icon(Icons.apple_rounded),
              label: const Text('Sign in with Apple'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'New accounts are created automatically the first time you sign in. Confirm the email link if prompted.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () => Navigator.of(context)
              .pushReplacementNamed(HomeScreen.routeName),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Skip for now'),
        ),
      ],
    );
  }

  Future<void> _signInWithEmail(
      BuildContext context, AppState appState) async {
    FocusScope.of(context).unfocus();
    await _runAuthFlow(
          () async {
        await appState.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your inbox if this is a new sign in.'),
            ),
          );
        }
      },
    );
  }

  Future<void> _signInWithGoogle(
      BuildContext context, AppState appState) async {
    FocusScope.of(context).unfocus();
    await _runAuthFlow(() => appState.signInWithGoogle());
  }

  Future<void> _signInWithApple(
      BuildContext context, AppState appState) async {
    FocusScope.of(context).unfocus();
    await _runAuthFlow(() => appState.signInWithApple());
  }

  Future<void> _runAuthFlow(Future<void> Function() action) async {
    setState(() => _isProcessing = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
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

  void _handleAuthenticatedNavigation(AppState appState) {
    if (!mounted) return;
    if (!appState.isAuthenticated || _hasNavigatedAfterAuth) {
      return;
    }
    _hasNavigatedAfterAuth = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    });
  }
}