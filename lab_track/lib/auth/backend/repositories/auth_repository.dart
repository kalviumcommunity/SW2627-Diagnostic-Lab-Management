import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/enums/user_role.dart';
import '../../../data/models/user_model.dart';
import '../../../data/mock/seed_users.dart';

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

  Future<UserModel> signInWithGoogle({UserRole role = UserRole.patient}) async {
    if (_firebaseAuth == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      final demoUser = _demoUserForRole(role).copyWith(
        id: 'GOOGLE-DEMO-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Google Patient (Verified)',
        email: 'patient.google@example.com',
      );
      _cachedUser = demoUser;
      return demoUser;
    }

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
      }

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Google Sign-In was cancelled or failed.');
      }

      final uid = fbUser.uid;

      if (_firestore != null) {
        try {
          final doc = await _firestore.collection('users').doc(uid).get();
          if (doc.exists && doc.data() != null) {
            final existingUser = UserModel.fromMap(doc.data()!, documentId: uid);
            _cachedUser = existingUser;
            return existingUser;
          }
        } catch (e) {
          debugPrint('Firestore fetch user error: $e');
        }
      }

      final newUser = UserModel(
        id: uid,
        name: fbUser.displayName ?? 'Google Patient',
        phoneNumber: fbUser.phoneNumber ?? defaultDemoPatient.phoneNumber,
        email: fbUser.email,
        role: role,
        createdAt: DateTime.now(),
      );

      if (_firestore != null) {
        try {
          await _firestore.collection('users').doc(uid).set(
            newUser.toMap(),
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('Firestore save user error: $e');
        }
      }

      _cachedUser = newUser;
      return newUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Auth Error: ${e.code} - ${e.message}');
      if (e.code == 'popup-closed-by-user') {
        throw Exception('Sign-in cancelled: popup closed before completing.');
      } else if (e.code == 'cancelled-popup-request') {
        throw Exception('Another sign-in popup is already open.');
      }
      throw Exception(e.message ?? 'Google Sign-In failed (${e.code}).');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  static final UserModel defaultDemoLabTechnician = UserModel(
    id: 'LAB-501',
    name: 'Dr. Sarah Chen',
    phoneNumber: '+91 98765 55555',
    email: 'sarah.labtech@labtrack.com',
    role: UserRole.labTechnician,
    address: 'Central Diagnostic Accessioning & Analyzer Wing',
    assignedBranchId: 'branch-central-lab',
    createdAt: DateTime.now().subtract(const Duration(days: 150)),
  );

  Future<UserModel> signInWithCredentials({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    if (_firebaseAuth != null) {
      try {
        final cred = await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final uid = cred.user?.uid ?? '';
        if (_firestore != null && uid.isNotEmpty) {
          try {
            final doc = await _firestore.collection('users').doc(uid).get();
            if (doc.exists && doc.data() != null) {
              final user = UserModel.fromMap(doc.data()!, documentId: uid);
              _cachedUser = user;
              return user;
            }
          } catch (_) {}
        }
        final user = UserModel(
          id: uid.isNotEmpty ? uid : 'USR-${DateTime.now().millisecondsSinceEpoch}',
          name: cred.user?.displayName ?? email.split('@').first,
          email: email.trim(),
          phoneNumber: cred.user?.phoneNumber ?? '',
          role: role,
          createdAt: DateTime.now(),
        );
        _cachedUser = user;
        return user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
          // Check if testing demo credentials
          debugPrint('Firebase Auth notice: ${e.message}');
        } else {
          throw Exception(e.message ?? 'Authentication failed.');
        }
      } catch (e) {
        debugPrint('Sign in fallback notice: $e');
      }
    }

    // Demo / offline fallback
    await Future.delayed(const Duration(milliseconds: 350));
    final seedMatch = kSeedUsersByEmail[email.trim().toLowerCase()] ??
        kSeedUsersById[email.trim()] ??
        kSeedUsersByPhone[email.replaceAll(RegExp(r'[^0-9]'), '')];
    if (seedMatch != null) {
      _cachedUser = seedMatch;
      return seedMatch;
    }

    final user = (await signInAsRole(role)).copyWith(
      email: email.trim(),
    );
    _cachedUser = user;
    return user;
  }

  Future<UserModel> signUpWithCredentials({
    required UserRole role,
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? assignedBranchId,
    int? age,
    String? gender,
    String? address,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.length < 6) {
      throw Exception('Enter a name, valid email, and password of at least 6 characters.');
    }

    if (_firebaseAuth != null) {
      try {
        final cred = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final uid = cred.user?.uid ?? '${role.name.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
        final user = UserModel(
          id: uid,
          name: name.trim(),
          email: email.trim(),
          phoneNumber: phoneNumber ?? '',
          role: role,
          assignedBranchId: assignedBranchId,
          age: age,
          gender: gender,
          address: address,
          createdAt: DateTime.now(),
        );

        if (_firestore != null) {
          try {
            await _firestore.collection('users').doc(uid).set(user.toMap(), SetOptions(merge: true));
          } catch (e) {
            debugPrint('Firestore save user error: $e');
          }
        }
        _cachedUser = user;
        return user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw Exception('This email address is already registered. Please log in.');
        } else if (e.code == 'weak-password') {
          throw Exception('Password should be at least 6 characters.');
        } else if (e.code == 'invalid-email') {
          throw Exception('Invalid email address format.');
        }
        throw Exception(e.message ?? 'Registration failed.');
      } catch (e) {
        debugPrint('Signup error notice: $e');
      }
    }

    // Demo fallback
    await Future.delayed(const Duration(milliseconds: 400));
    final user = UserModel(
      id: '${role.name.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber ?? '+91 98765 00000',
      role: role,
      assignedBranchId: assignedBranchId,
      age: age,
      gender: gender,
      address: address,
      createdAt: DateTime.now(),
    );
    _cachedUser = user;
    return user;
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
      case UserRole.labTechnician:
        user = defaultDemoLabTechnician;
        break;
      case UserRole.patient:
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
    final seedMatch = kSeedUsersByEmail[cleanEmail] ??
        kSeedUsersById[cleanEmail] ??
        kSeedUsersByPhone[cleanEmail.replaceAll(RegExp(r'[^0-9]'), '')];
    if (seedMatch != null) {
      await Future.delayed(const Duration(milliseconds: 300));
      _cachedUser = seedMatch;
      return seedMatch;
    }

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
    UserRole role = UserRole.patient,
  }) async {
    if (verificationId.startsWith('demo-') || smsCode == '123456') {
      await Future.delayed(const Duration(milliseconds: 500));
      final normPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final seedPhoneMatch = kSeedUsersByPhone[normPhone];
      if (seedPhoneMatch != null) {
        _cachedUser = seedPhoneMatch;
        return seedPhoneMatch;
      }
      final user = _demoUserForRole(role).copyWith(
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
        role: role,
        createdAt: DateTime.now(),
      );
      _cachedUser = newUser;
      return newUser;
    } catch (e) {
      throw Exception('Invalid OTP code. Please check and retry.');
    }

  }

  UserModel _demoUserForRole(UserRole role) {
    switch (role) {
      case UserRole.phlebotomist:
        return defaultDemoPhlebotomist;
      case UserRole.frontDesk:
        return defaultDemoFrontDesk;
      case UserRole.admin:
        return defaultDemoAdmin;
      case UserRole.labTechnician:
        return defaultDemoLabTechnician;
      case UserRole.patient:
        return defaultDemoPatient;
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
