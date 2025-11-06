import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const routeName = '/auth/sign-up';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_settings.svg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Create account'),
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
                  'Join the neon story studio',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create an account to sync stories, preferences, and onboarding progress across devices.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _displayNameController,
                  enabled: !_isProcessing,
                  decoration: const InputDecoration(
                    labelText: 'Display name (optional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  enabled: !_isProcessing,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: _validateConfirmation,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isProcessing ? null : _createAccount,
                  icon: _isProcessing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_isProcessing ? 'Creating account…' : 'Create account'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.of(context)
                          .pushReplacementNamed(SignInScreen.routeName),
                      child: const Text('Sign in'),
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
      return 'Enter a password.';
    }
    if (value.length < 6) {
      return 'Passwords must be at least 6 characters.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isProcessing = true);
    try {
      final authService = context.read<AuthService>();
      await authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      _navigateNext();
    } on FirebaseAuthException catch (error) {
      _showError(_mapFirebaseError(error));
    } catch (_) {
      _showError('Unable to create account. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      } else {
        _isProcessing = false;
      }
    }
  }

  void _navigateNext() {
    final appState = context.read<AppState>();
    final onboardingComplete = appState.onboardingComplete;
    final destination = onboardingComplete
        ? HomeScreen.routeName
        : OnboardingScreen.routeName;
    Navigator.of(context).pushReplacementNamed(destination);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists with that email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Choose a stronger password.';
      default:
        return 'Registration failed. (${error.message ?? error.code})';
    }
  }
}