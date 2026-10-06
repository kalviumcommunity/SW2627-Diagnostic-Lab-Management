import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/enums/user_role.dart';
import '../models/user_model.dart';

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

  /// Default demo patient for fast local testing and demonstration.
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

  static final UserModel defaultDemoPhlebotomist = UserModel(
    id: 'PH-204',
    name: 'Rahul Verma',
    phoneNumber: '+91 98765 11111',
    email: 'rahul.phlebo@labtrack.com',
    role: UserRole.phlebotomist,
    address: 'Central Diagnostic Hub, Sector 18',
    assignedBranchId: 'branch-delhi-central',
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
  );

  static final UserModel defaultDemoFrontDesk = UserModel(
    id: 'FD-108',
    name: 'Priya Sharma',
    phoneNumber: '+91 98765 22222',
    email: 'priya.frontdesk@labtrack.com',
    role: UserRole.frontDesk,
    address: 'Downtown Spoke Center, Reception Desk',
    assignedBranchId: 'branch-spoke-01',
    createdAt: DateTime.now().subtract(const Duration(days: 120)),
  );

  static final UserModel defaultDemoAdmin = UserModel(
    id: 'ADM-001',
    name: 'Dr. Vikram Malhotra',
    phoneNumber: '+91 98765 33333',
    email: 'dr.malhotra@labtrack.com',
    role: UserRole.admin,
    address: 'LabTrack Apex Operations HQ',
    assignedBranchId: 'branch-apex-hq',
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );

  /// Signs in as the default demo patient.
  Future<UserModel> signInAsDemoPatient() async {
    return signInAsRole(UserRole.patient);
  }

  /// Signs in as demo user of a specific role.
  Future<UserModel> signInAsRole(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final UserModel user;
    switch (role) {
      case UserRole.phlebotomist:
        user = defaultDemoPhlebotomist;
        break;
      case UserRole.frontDesk:
        user = defaultDemoFrontDesk;
        break;
      case UserRole.admin:
        user = defaultDemoAdmin;
        break;
      case UserRole.patient:
      default:
        user = defaultDemoPatient;
        break;
    }
    _cachedUser = user;
    return user;
  }

  /// Sends OTP to the specified phone number.
  /// Returns verificationId via callbacks.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerify,
  }) async {
    // If it's the demo phone number or Firebase isn't configured, bypass smoothly
    if (phoneNumber.replaceAll(RegExp(r'[^0-9]'), '').endsWith('9876543210')) {
      await Future.delayed(const Duration(milliseconds: 800));
      onCodeSent('demo-verification-id-84210');
      return;
    }

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (onAutoVerify != null) {
            onAutoVerify(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase phone auth failed: ${e.message}');
          // If Firebase phone quota or not configured in dev, fall back gracefully
          onError(e.message ?? 'Verification failed. Try the 1-Click Demo Login.');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      debugPrint('AuthRepository sendOtp exception: $e');
      onError(e.toString());
    }
  }

  /// Verifies the OTP code entered by the user.
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    // Check for demo verification ID or standard demo code '123456'
    if (verificationId.startsWith('demo-') || smsCode == '123456') {
      await Future.delayed(const Duration(milliseconds: 700));
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

      // Attempt to load existing user document from Firestore
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

      // Default new patient profile
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
      debugPrint('AuthRepository verifyOtp error: $e');
      throw Exception('Invalid OTP code. Please check and retry.');
    }
  }

  /// Updates or saves patient profile details in local cache & Firestore.
  Future<UserModel> saveProfile(UserModel user) async {
    _cachedUser = user;
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveProfile notice: $e');
    }
    return user;
  }

  /// Sign out the current user session.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    _cachedUser = null;
  }
}
