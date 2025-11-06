import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const routeName = '/auth/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final theme = Theme.of(context);

    if (appState.isAuthenticated) {
      final user = appState.authUser;
      final email = user?.email ?? 'Signed in';
      final name = user?.displayName ?? appState.displayName;
      return GradientBackground(
          asset: 'lib/assets/backgrounds/obsdiv_settings.svg',
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Sign in'),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BrandedLogo(size: 120, variant: LogoVariant.icon),
                    const SizedBox(height: 16),
                    Text(
                      "You're already signed in",
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${name}\n$email',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(HomeScreen.routeName),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Continue to home'),
                    ),
                  ],
              ),
              ),
          ),
        ),
      );
    }

    return GradientBackground(
        asset: 'lib/assets/backgrounds/obsdiv_settings.svg',
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        title: const Text('Sign in'),
    centerTitle: true,
        ),
    body: SafeArea(
    child: Form(
    key: _formKey,
    child: ListView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    children: [
    const SizedBox(height: 12),
    const BrandedLogo(size: 120, variant: LogoVariant.watermark),
    const SizedBox(height: 16),
    Text(
    'Welcome back',
    style: theme.textTheme.headlineSmall,
    textAlign: TextAlign.center,
    ),
    const SizedBox(height: 12),
    Text(
    'Sign in with your email and password to sync stories across devices.',
    style: theme.textTheme.bodyMedium,
    textAlign: TextAlign.center,
    ),
    const SizedBox(height: 32),
    TextFormField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    enabled: !_isProcessing,
    decoration: const InputDecoration(
    labelText: 'Email',
    prefixIcon: Icon(Icons.email_outlined),
    ),
    validator: _validateEmail,
    ),
    const SizedBox(height: 16),
    TextFormField(
    controller: _passwordController,
    obscureText: true,
    enabled: !_isProcessing,
    decoration: const InputDecoration(
    labelText: 'Password',
    prefixIcon: Icon(Icons.lock_outline),
    ),
    validator: _validatePassword,
    ),
    const SizedBox(height: 20),
    FilledButton.icon(
    onPressed: _isProcessing ? null : _signIn,
    icon: _isProcessing
    ? const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
    )
        : const Icon(Icons.login_rounded),
    label:
    Text(_isProcessing ? 'Signing in…' : 'Sign in with email'),
    ),
    const SizedBox(height: 16),
    Align(
    alignment: Alignment.centerRight,
    child: TextButton(
    onPressed: _isProcessing ? null : _resetPassword,
    child: const Text('Forgot password?'),
    ),
    ),
    const SizedBox(height: 12),
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    const Text('Need an account?'),
    TextButton(
    onPressed: _isProcessing
    ? null
        : () => Navigator.of(context)
        .pushReplacementNamed(SignUpScreen.routeName),
    child: const Text('Create one'),
    ),
    ],
    ),
    ],
            ),
    ),
        ),
        ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email address.';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password.';
    }
    if (value.length < 6) {
      return 'Passwords are at least 6 characters.';
    }
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isProcessing = true);
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome back!')),
      );
    } on FirebaseAuthException catch (error) {
      _showError(_mapFirebaseError(error));
    } catch (_) {
      _showError('Unable to sign in. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      } else {
        _isProcessing = false;
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email above to reset the password.');
      return;
    }
    try {
      final authService = context.read<AuthService>();
      await authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      _showError(_mapFirebaseError(error));
    } catch (_) {
      _showError('Unable to send password reset email.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication failed. (${error.message ?? error.code})';
    }
  }
}