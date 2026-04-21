import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pou wè si moun nan konekte
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Konekte ak email/modpas
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Kreye kont ak email/modpas
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Dekonekte
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Itilizatè ki konekte kounye a
  User? get currentUser => _auth.currentUser;

  // Jere erè Firebase
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Pa gen kont ak email sa a.';
      case 'wrong-password':
        return 'Modpas la pa kòrèk.';
      case 'email-already-in-use':
        return 'Email sa a deja itilize.';
      case 'weak-password':
        return 'Modpas la twò fèb — minimòm 6 karaktè.';
      case 'invalid-email':
        return 'Adrès email la pa valid.';
      case 'too-many-requests':
        return 'Twòp eseye — tann yon ti moman.';
      default:
        return 'Erè: ${e.message}';
    }
  }
}