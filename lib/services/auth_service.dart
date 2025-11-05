import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple abstraction around Supabase authentication that exposes a unified
/// stream of the current user and helper methods for multiple sign-in flows.
class AuthService {
  AuthService({
    SupabaseClient? client,
    String? redirectUrl,
  })  : _client = client,
        _redirectUrl = redirectUrl,
        _controller = StreamController<AuthUser?>.broadcast() {
    _authSubscription = _client?.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      _controller.add(_mapUser(session?.user));
    });
    final current = _client?.auth.currentUser;
    if (current != null) {
      _controller.add(_mapUser(current));
    }
  }

  final SupabaseClient? _client;
  final String? _redirectUrl;
  final StreamController<AuthUser?> _controller;
  StreamSubscription<AuthState>? _authSubscription;

  bool get isAvailable => _client != null;

  AuthUser? get currentUser => _mapUser(_client?.auth.currentUser);

  Stream<AuthUser?> get onAuthStateChanged => _controller.stream;

  Future<void> signInWithEmail(String email, String password) async {
    final client = _requireClient();
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const AuthFlowException('Email and password are required.');
    }
    try {
      await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
    } on AuthException catch (error) {
      if (error.message.toLowerCase().contains('invalid login credentials')) {
        final response = await client.auth.signUp(
          email: normalizedEmail,
          password: password,
        );
        if (response.session == null) {
          throw const AuthFlowException(
            'Check your inbox to confirm the login link before signing in.',
          );
        }
      } else {
        throw AuthFlowException(error.message);
      }
    } catch (error) {
      throw AuthFlowException(error.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    final client = _requireClient();
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
        queryParams: const {'prompt': 'select_account'},
      );
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } catch (error) {
      throw AuthFlowException(error.toString());
    }
  }

  Future<void> signInWithApple() async {
    final client = _requireClient();
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _redirectUrl,
      );
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } catch (error) {
      throw AuthFlowException(error.toString());
    }
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const AuthFlowException('Authentication is not configured.');
    }
    return client;
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['full_name'] as String?,
    );
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _controller.close();
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
  });

  final String id;
  final String? email;
  final String? displayName;
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}