import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/constants.dart';

class UsernameTakenException implements Exception {}

class UsernameNotFoundException implements Exception {}

class EmailNotVerifiedException implements Exception {}

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> authChanges() => _auth.userChanges();

  Future<String> _emailFromUsername(String username) async {
    final usernameLower = normalizeUsername(username);
    final doc = await _db.collection('usernames').doc(usernameLower).get();
    if (!doc.exists) throw UsernameNotFoundException();
    final data = doc.data()!;
    return (data['email'] ?? '') as String;
  }

  Future<void> loginWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    final email = await _emailFromUsername(username);
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.reload();
    final u = _auth.currentUser;
    if (u == null) return;

    if (!u.emailVerified) {
      await u.sendEmailVerification();
      throw EmailNotVerifiedException();
    }
  }

  Future<UserCredential> register({
    required String username,
    required String email,
    required String password,
    required String shopName,
    required String shopAddress,
  }) async {
    final usernameLower = normalizeUsername(username);
    final emailTrimmed = email.trim();

    final unameRef = _db.collection('usernames').doc(usernameLower);
    final unameSnap = await unameRef.get();
    if (unameSnap.exists) {
      throw UsernameTakenException();
    }

    String authEmail = emailTrimmed;
    if (authEmail.contains('@')) {
      final parts = authEmail.split('@');
      final localPart = parts[0];
      final domain = parts[1];
      final randomSuffix = DateTime.now().millisecondsSinceEpoch.toString();
      authEmail = '$localPart+$randomSuffix@$domain';
    }

    UserCredential? cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
          email: authEmail, password: password);
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        final randomSuffix2 = DateTime.now().microsecondsSinceEpoch.toString();
        final parts = emailTrimmed.split('@');
        authEmail = '${parts[0]}+$randomSuffix2@${parts[1]}';
        cred = await _auth.createUserWithEmailAndPassword(
            email: authEmail, password: password);
      } else {
        rethrow;
      }
    }
    
    final uid = cred.user!.uid;
    
    await cred.user?.reload();
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      await cred.user?.delete();
      await _auth.signOut();
      throw Exception('Failed to authenticate user after registration');
    }

    try {
      final batch = _db.batch();

      batch.set(unameRef, {
        'uid': uid,
        'email': authEmail,
        'originalEmail': emailTrimmed,
        'usernameLower': usernameLower,
      });

      final shopRef = _db.collection('shops').doc(uid);
      batch.set(shopRef, {
        'uid': uid,
        'username': username.trim(),
        'email': emailTrimmed,
        'authEmail': authEmail,
        'shopName': shopName,
        'shopAddress': shopAddress,
      });

      final invRef = shopRef.collection('state').doc(AppConstants.inventoryDocId);
      batch.set(invRef, {
        'goldGrams': 0.0,
        'balances': {'USD': 0.0, 'EUR': 0.0, 'TRY': 0.0},
      });
      
      await batch.commit();
      
      final userAfterCommit = _auth.currentUser;
      if (userAfterCommit == null || userAfterCommit.uid != uid) {
        throw Exception('User authentication lost after registration');
      }
    } catch (e) {
      try {
        await cred.user?.delete();
      } catch (_) {}
      await _auth.signOut();
      rethrow;
    }

    return cred;
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail({
    required String username,
    required String oldPassword,
  }) async {
    final email = await _emailFromUsername(username);
    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: oldPassword);
      await _auth.sendPasswordResetEmail(email: email);
      await _auth.signOut();
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();
}
