import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';

/// Thin wrapper over Firebase Authentication. All methods translate Firebase
/// errors into user-safe [AuthException]s and never log credentials.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserChange> get userStateChanges => _auth.userStateChanges();

  /// Registers a new account. Returns the created Firebase user.
  Future<User> register({required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e.code, e.message), detail: e.code);
    }
  }

  Future<User> login({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e.code, e.message), detail: e.code);
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e.code, e.message), detail: e.code);
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to update your profile.');
    }
    try {
      await user.updateDisplayName(name.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e.code, e.message), detail: e.code);
    }
  }

  /// Ensures the Firestore profile document exists for the signed-in user.
  /// Creates it with the ordinary `user` role if missing (handles partial
  /// registration failure where auth succeeded but profile creation did not).
  Future<AppUser> ensureProfile(User user) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snap = await ref.get();
    if (snap.exists && snap.data() != null) {
      return AppUser.fromDoc(snap);
    }
    final fresh = AppUser(
      uid: user.uid,
      displayName: user.displayName ?? 'Namibia resident',
      email: user.email ?? '',
      notificationEnabled: true,
      role: UserRole.user,
    );
    await ref.set(fresh.toCreateDocument());
    return fresh;
  }

  Future<AppUser?> fetchProfile(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return AppUser.fromDoc(snap);
  }

  Stream<AppUser?> profileStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((s) => s.exists ? AppUser.fromDoc(s) : null);
  }

  Future<void> saveProfile(AppUser user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update(user.toWritableClientFields());
  }
}
