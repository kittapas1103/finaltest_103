import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthController {
  AuthController._();

  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// true ระหว่างสร้างบัญชีทดสอบ (กันไม่ให้ AuthGate เด้งเข้าหน้า Home)
  static final ValueNotifier<bool> seeding = ValueNotifier(false);

  static Stream<User?> get authChanges => _auth.authStateChanges();

  static Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  static Future<void> logout() => _auth.signOut();

  static Future<AppUser> loadProfile(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'] as String? ?? 'operator';
    return AppUser(uid: user.uid, email: user.email ?? '', role: role);
  }

  /// สร้าง admin@test.com / operator@test.com (รหัส 123456)
  static Future<void> seedTestAccounts() async {
    seeding.value = true;
    try {
      const accounts = [
        {'email': 'admin@test.com', 'role': 'admin'},
        {'email': 'operator@test.com', 'role': 'operator'},
      ];
      for (final a in accounts) {
        UserCredential cred;
        try {
          cred = await _auth.createUserWithEmailAndPassword(
              email: a['email']!, password: '123456');
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
          cred = await _auth.signInWithEmailAndPassword(
              email: a['email']!, password: '123456');
        }
        await _db.collection('users').doc(cred.user!.uid).set({
          'email': a['email'],
          'role': a['role'],
        });
        await _auth.signOut();
      }
    } finally {
      seeding.value = false;
    }
  }

  static String errorText(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
        case 'invalid-email':
          return 'รูปแบบอีเมลไม่ถูกต้อง';
        case 'network-request-failed':
          return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      }
      return e.message ?? e.code;
    }
    return e.toString();
  }
}
