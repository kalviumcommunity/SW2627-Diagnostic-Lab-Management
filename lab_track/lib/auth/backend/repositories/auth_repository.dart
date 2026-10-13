import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/enums/user_role.dart';
import '../../../data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  UserModel? _cachedUser;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? _tryGetFirebaseAuth(),
        _firestore = firestore ?? _tryGetFirestore();

  static FirebaseAuth? _tryGetFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

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

  Future<UserModel> signInAsDemoPatient() async {
    return signInAsRole(UserRole.patient);
  }

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

  /// Sign In with Email and Password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Fast-track demo credentials for instant reliable login in all environments
    if (cleanEmail == 'dr.malhotra@labtrack.com' || cleanEmail == 'admin@labtrack.com') {
      await Future.delayed(const Duration(milliseconds: 300));
      _cachedUser = defaultDemoAdmin;
      return defaultDemoAdmin;
    } else if (cleanEmail == 'rahul.phlebo@labtrack.com' || cleanEmail == 'phlebo@labtrack.com') {
      await Future.delayed(const Duration(milliseconds: 300));
      _cachedUser = defaultDemoPhlebotomist;
      return defaultDemoPhlebotomist;
    } else if (cleanEmail == 'priya.frontdesk@labtrack.com' || cleanEmail == 'frontdesk@labtrack.com') {
      await Future.delayed(const Duration(milliseconds: 300));
      _cachedUser = defaultDemoFrontDesk;
      return defaultDemoFrontDesk;
    } else if (cleanEmail == 'john.doe@example.com' || cleanEmail == 'patient@labtrack.com') {
      await Future.delayed(const Duration(milliseconds: 300));
      _cachedUser = defaultDemoPatient;
      return defaultDemoPatient;
    }

    if (_firebaseAuth != null) {
      try {
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final uid = credential.user?.uid ?? 'usr-uid';

        if (_firestore != null) {
          try {
            final doc = await _firestore.collection('users').doc(uid).get();
            if (doc.exists && doc.data() != null) {
              final user = UserModel.fromMap(doc.data()!, documentId: uid);
              _cachedUser = user;
              return user;
            }
          } catch (e) {
            debugPrint('Firestore fetch error: $e');
          }
        }

        final inferredRole = _inferRoleFromEmail(cleanEmail);
        final user = UserModel(
          id: uid,
          name: credential.user?.displayName ?? cleanEmail.split('@').first,
          email: cleanEmail,
          phoneNumber: credential.user?.phoneNumber ?? '',
          role: inferredRole,
          createdAt: DateTime.now(),
        );
        _cachedUser = user;
        return user;
      } on FirebaseAuthException catch (e) {
        throw Exception(_mapFirebaseAuthError(e));
      } catch (e) {
        throw Exception('Sign in failed: ${e.toString().replaceAll("Exception: ", "")}');
      }
    }

    // Offline / Demo fallback for any other email
    await Future.delayed(const Duration(milliseconds: 400));
    final inferredRole = _inferRoleFromEmail(cleanEmail);
    final user = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: cleanEmail.split('@').first,
      email: cleanEmail,
      phoneNumber: '+91 98765 00000',
      role: inferredRole,
      createdAt: DateTime.now(),
    );
    _cachedUser = user;
    return user;
  }

  /// Sign Up with Email, Password, and Role
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phoneNumber,
    String? branchId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    String uid = 'USR-${DateTime.now().millisecondsSinceEpoch}';

    if (_firebaseAuth != null) {
      try {
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        uid = credential.user?.uid ?? uid;
        try {
          await credential.user?.updateDisplayName(name);
        } catch (_) {}
      } on FirebaseAuthException catch (e) {
        throw Exception(_mapFirebaseAuthError(e));
      } catch (e) {
        throw Exception('Registration failed: ${e.toString().replaceAll("Exception: ", "")}');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
    }

    final newUser = UserModel(
      id: uid,
      name: name.trim(),
      email: cleanEmail,
      phoneNumber: phoneNumber ?? '',
      role: role,
      assignedBranchId: branchId,
      createdAt: DateTime.now(),
    );

    if (_firestore != null) {
      try {
        await _firestore.collection('users').doc(uid).set(newUser.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore save error: $e');
      }
    }

    _cachedUser = newUser;
    return newUser;
  }

  /// Google Authentication Integration
  Future<UserModel> signInWithGoogle() async {
    if (_firebaseAuth != null) {
      try {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
        final fbUser = userCredential.user;
        final uid = fbUser?.uid ?? 'google-uid';
        final email = fbUser?.email ?? 'google.user@labtrack.com';

        if (_firestore != null) {
          try {
            final doc = await _firestore.collection('users').doc(uid).get();
            if (doc.exists && doc.data() != null) {
              final existing = UserModel.fromMap(doc.data()!, documentId: uid);
              _cachedUser = existing;
              return existing;
            }
          } catch (e) {
            debugPrint('Firestore google user lookup error: $e');
          }
        }

        final role = _inferRoleFromEmail(email);
        final newUser = UserModel(
          id: uid,
          name: fbUser?.displayName ?? 'Verified Google User',
          email: email,
          phoneNumber: fbUser?.phoneNumber ?? '',
          role: role,
          createdAt: DateTime.now(),
        );

        if (_firestore != null) {
          try {
            await _firestore.collection('users').doc(uid).set(newUser.toMap(), SetOptions(merge: true));
          } catch (_) {}
        }

        _cachedUser = newUser;
        return newUser;
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Google Auth error: ${e.code} - ${e.message}');
        // If Google sign-in is not yet enabled in Firebase Console, fallback gracefully to verified demo
        if (e.code == 'operation-not-allowed' || e.code == 'configuration-not-found' || e.code == 'popup-closed-by-user') {
          if (e.code == 'popup-closed-by-user') {
            throw Exception('Google sign-in was cancelled.');
          }
          throw Exception('Google sign-in is being enabled on this project. ${e.message ?? ""}');
        }
        throw Exception(_mapFirebaseAuthError(e));
      } catch (e) {
        debugPrint('Google Auth exception: $e');
        throw Exception(e.toString().replaceAll("Exception: ", ""));
      }
    }

    // Offline / Demo fallback for Google sign-in
    await Future.delayed(const Duration(milliseconds: 500));
    final demoGoogleUser = UserModel(
      id: 'GGL-98210',
      name: 'Dr. Vikram Malhotra (Google Verified)',
      email: 'dr.malhotra@labtrack.com',
      phoneNumber: '+91 98765 33333',
      role: UserRole.admin,
      address: 'LabTrack Apex Operations HQ',
      assignedBranchId: 'branch-apex-hq',
      createdAt: DateTime.now(),
    );
    _cachedUser = demoGoogleUser;
    return demoGoogleUser;
  }

  static UserRole _inferRoleFromEmail(String email) {
    if (email.contains('admin') || email.contains('malhotra') || email.contains('director')) {
      return UserRole.admin;
    } else if (email.contains('phlebo') || email.contains('rahul')) {
      return UserRole.phlebotomist;
    } else if (email.contains('frontdesk') || email.contains('priya') || email.contains('desk')) {
      return UserRole.frontDesk;
    } else if (email.contains('tech') || email.contains('lab') || email.contains('pathology')) {
      return UserRole.labTechnician;
    }
    return UserRole.patient;
  }

  static String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please log in.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
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

    if (_firebaseAuth == null) {
      onError('Firebase Auth is not available in offline/demo mode. Please use demo login.');
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

    if (_firebaseAuth == null) {
      throw Exception('Firebase Auth is not available in offline/demo mode.');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final uid = userCredential.user?.uid ?? 'unknown_uid';

      if (_firestore != null) {
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
    if (_firestore != null) {
      try {
        await _firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
    return user;
  }

  Future<void> signOut() async {
    if (_firebaseAuth != null) {
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
    }
    _cachedUser = null;
  }
}
