import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/enums/user_role.dart';
import '../../../data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  UserModel? _cachedUser;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  UserModel? get cachedUser => _cachedUser;

  static final UserModel defaultDemoPatient = UserModel(
    id: 'PT-84210',
    name: 'John Doe',
    phoneNumber: '+91 98765 43210',
    email: 'john.doe@example.com',
    role: UserRole.patient,
    address: 'Apartment 4B, Sunrise Residency, Sector 14',
    age: 38,
    gender: 'Male',
    emergencyContact: '+91 98765 00000',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  Future<UserModel> signInAsDemoPatient() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _cachedUser = defaultDemoPatient;
    return defaultDemoPatient;
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerify,
  }) async {
    if (phoneNumber.replaceAll(RegExp(r'[^0-9]'), '').endsWith('9876543210')) {
      await Future.delayed(const Duration(milliseconds: 600));
      onCodeSent('demo-verification-id-84210');
      return;
    }

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (onAutoVerify != null) onAutoVerify(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed. Try the 1-Click Demo Login.');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    if (verificationId.startsWith('demo-') || smsCode == '123456') {
      await Future.delayed(const Duration(milliseconds: 500));
      final user = defaultDemoPatient.copyWith(
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : defaultDemoPatient.phoneNumber,
      );
      _cachedUser = user;
      return user;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final uid = userCredential.user?.uid ?? 'unknown_uid';

      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final user = UserModel.fromMap(doc.data()!, documentId: uid);
          _cachedUser = user;
          return user;
        }
      } catch (e) {
        debugPrint('Firestore fetch user error: $e');
      }

      final newUser = UserModel(
        id: uid,
        name: userCredential.user?.displayName ?? 'Valued Patient',
        phoneNumber: phoneNumber,
        role: UserRole.patient,
        createdAt: DateTime.now(),
      );
      _cachedUser = newUser;
      return newUser;
    } catch (e) {
      throw Exception('Invalid OTP code. Please check and retry.');
    }
  }

  Future<UserModel> saveProfile(UserModel user) async {
    _cachedUser = user;
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (_) {}
    return user;
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    _cachedUser = null;
  }
}
