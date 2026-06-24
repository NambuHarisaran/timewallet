import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Wraps FirebaseAuth. Email/password + Google.
class AuthService {
  final FirebaseAuth _auth;
  AuthService(this._auth);

  Stream<User?> authState() => _auth.authStateChanges();
  User? get current => _auth.currentUser;

  Future<UserCredential> signInEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates the account and immediately fires a verification email.
  Future<UserCredential> signUpEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      await cred.user?.sendEmailVerification();
    } catch (_) {
      // Non-fatal: account exists; verification mail can be re-sent later.
    }
    return cred;
  }

  /// Google sign-in.
  /// - Web: popup (reliable, no redirect round-trip).
  /// - Mobile/desktop: Firebase federated provider flow (no google_sign_in
  ///   package). Requires the Google provider enabled in the Firebase console
  ///   and, on Android, the app's SHA-1/SHA-256 fingerprints registered.
  Future<UserCredential> signInGoogle() {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }
    return _auth.signInWithProvider(provider);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerification() => _auth.currentUser?.sendEmailVerification() ?? Future.value();

  Future<void> reloadUser() => _auth.currentUser?.reload() ?? Future.value();

  Future<void> signOut() => _auth.signOut();

  /// Human-readable message for a FirebaseAuthException code.
  static String describeError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Password is too weak (min 6 characters).';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'account-exists-with-different-credential':
          return 'This email is already linked to a different sign-in method.';
        case 'popup-blocked':
          return 'Your browser blocked the Google popup. Allow popups and retry.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
        case 'web-context-canceled':
          return 'Google sign-in was cancelled.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is disabled. Enable it in '
              'Firebase Console → Authentication → Sign-in method.';
        case 'configuration-not-found':
        case 'admin-restricted-operation':
          return 'Auth provider not configured. Enable a sign-in method in '
              'Firebase Console → Authentication.';
        default:
          return e.message ?? 'Authentication failed (${e.code}).';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
