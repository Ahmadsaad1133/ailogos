import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
/// Service wrapper that centralises Firebase Authentication access for the app.
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// Emits authentication changes as the user signs in or out.
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  /// Returns the currently authenticated Firebase user, if any.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs in an existing user using an email and password.
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password,
      ) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a new user with Firebase Authentication.
  ///
  /// If [displayName] is provided, the user's Firebase profile and Firestore
  /// document are updated accordingly.
  Future<UserCredential> signUpWithEmailAndPassword(
      String email,
      String password, {
        String? displayName,
      }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      await _createOrUpdateUserDocument(
        user: user,
        displayName: displayName,
      );
    }
    return credential;
  }

  /// Sends a password reset email to the provided address.
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Signs the current user out of Firebase Authentication.
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<void> _createOrUpdateUserDocument({
    required User user,
    String? displayName,
  }) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final payload = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'displayName':
      displayName?.trim().isNotEmpty == true ? displayName!.trim() : user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'subscriptionPlan': 'free',
    };

    final snapshot = await doc.get();
    if (snapshot.exists) {
      await doc.update({
        ...payload,
        'createdAt': snapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
    } else {
      await doc.set(payload);
    }
  }
}
