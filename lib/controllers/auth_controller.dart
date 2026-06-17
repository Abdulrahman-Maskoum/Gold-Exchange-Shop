import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestore;

  User? firebaseUser;
  UserModel? profile;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _profileSub;

  bool get isLoggedIn => firebaseUser != null;
  bool get isEmailVerified => firebaseUser?.emailVerified ?? false;

  AuthController(this._authService, this._firestore) {
    _authSub = _authService.authChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  void _onAuthChanged(User? user) {
    firebaseUser = user;
    _profileSub?.cancel();
    profile = null;

    if (user == null) {
      notifyListeners();
      return;
    }

    // Hard block access for non-verified accounts.
    // BUT: Don't sign out during registration - let register() complete first
    // The register() function will handle sending verification email and signing out
    if (!user.emailVerified) {
      // Don't send verification email here - register() will handle it
      // Don't sign out here - register() will handle it after batch commit
      // This prevents signOut during registration which breaks batch commit
      notifyListeners();
      return;
    }

    _profileSub = _firestore.watchUser(user.uid).listen((p) {
      profile = p;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> login({required String username, required String password}) {
    return _authService.loginWithUsernamePassword(
        username: username, password: password);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String shopName,
    required String shopAddress,
  }) {
    return _authService.register(
      username: username,
      email: email,
      password: password,
      shopName: shopName,
      shopAddress: shopAddress,
    );
  }

  Future<void> sendVerificationEmail() => _authService.sendVerificationEmail();

  Future<void> sendPasswordResetEmail({
    required String username,
    required String oldPassword,
  }) {
    return _authService.sendPasswordResetEmail(
      username: username,
      oldPassword: oldPassword,
    );
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> updateProfile(
      {required String shopName, required String shopAddress}) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    await _firestore.updateProfile(
        uid: uid, shopName: shopName, shopAddress: shopAddress);
  }
}
