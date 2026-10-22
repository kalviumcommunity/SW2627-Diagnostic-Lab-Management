import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/data/mock/seed_users.dart';
import 'package:lab_track/data/models/user_model.dart';
import 'package:lab_track/domain/enums/user_role.dart';
import 'package:lab_track/data/services/central_data_store.dart';
import 'package:lab_track/auth/backend/repositories/auth_repository.dart';

void main() {
  group('Seed Users (100 Users Dataset) Tests', () {
    test('Contains exactly 100 users across 5 operational roles', () {
      expect(kSeedUsers.length, 100);

      final patients = kSeedPatients;
      final phlebotomists = kSeedPhlebotomists;
      final labTechs = kSeedLabTechnicians;
      final frontDesk = kSeedFrontDesk;
      final admins = kSeedAdmins;

      expect(patients.length, 50);
      expect(phlebotomists.length, 20);
      expect(labTechs.length, 12);
      expect(frontDesk.length, 12);
      expect(admins.length, 6);
    });

    test('All 100 user IDs, phone numbers, and emails are unique', () {
      final ids = kSeedUsers.map((u) => u.id).toSet();
      final phones = kSeedUsers.map((u) => u.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')).toSet();
      final emails = kSeedUsers.map((u) => u.email?.toLowerCase().trim()).toSet();

      expect(ids.length, 100);
      expect(phones.length, 100);
      expect(emails.length, 100);
    });

    test('All users have valid non-empty fields and serializable structure', () {
      for (final user in kSeedUsers) {
        expect(user.id.isNotEmpty, isTrue);
        expect(user.name.isNotEmpty, isTrue);
        expect(user.phoneNumber.isNotEmpty, isTrue);
        expect(user.email, isNotNull);
        expect(user.email!.contains('@'), isTrue);
        expect(user.address, isNotNull);
        expect(user.address!.isNotEmpty, isTrue);
        expect(user.age, isNotNull);
        expect(user.age!, inInclusiveRange(18, 90));
        expect(user.gender, isIn(['Male', 'Female', 'Other']));

        // Verify JSON round-trip
        final map = user.toMap();
        final reconstructed = UserModel.fromMap(map, documentId: user.id);
        expect(reconstructed.id, user.id);
        expect(reconstructed.name, user.name);
        expect(reconstructed.role, user.role);
        expect(reconstructed.email, user.email);
        expect(reconstructed.phoneNumber, user.phoneNumber);
      }
    });

    test('Lookup maps provide O(1) query access', () {
      expect(kSeedUsersById['PT-84210']?.name, 'John Doe');
      expect(kSeedUsersById['PH-204']?.name, 'Rahul Verma');
      expect(kSeedUsersById['LAB-501']?.name, 'Dr. Sarah Chen');
      expect(kSeedUsersById['FD-108']?.name, 'Priya Sharma');
      expect(kSeedUsersById['ADM-001']?.name, 'Dr. Vikram Malhotra');

      expect(kSeedUsersByEmail['john.doe@example.com']?.id, 'PT-84210');
      expect(kSeedUsersByPhone['919876543210']?.id, 'PT-84210');
    });

    test('CentralDataStore exposes seeded users and populated staff', () {
      final store = CentralDataStore.instance;
      expect(store.users.length, greaterThanOrEqualTo(100));
      expect(store.patients.length, greaterThanOrEqualTo(50));
      expect(store.staff.length, greaterThanOrEqualTo(50));
    });

    test('AuthRepository authenticates any seeded user by email or phone', () async {
      final authRepo = AuthRepository();

      // Sign in by patient email
      final patient = await authRepo.signInWithEmailAndPassword(
        email: 'john.doe@example.com',
        password: 'password123',
      );
      expect(patient.id, 'PT-84210');
      expect(patient.role, UserRole.patient);

      // Sign in by phlebotomist email
      final phlebo = await authRepo.signInWithEmailAndPassword(
        email: 'rahul.phlebo@labtrack.com',
        password: 'password123',
      );
      expect(phlebo.id, 'PH-204');
      expect(phlebo.role, UserRole.phlebotomist);

      // Verify OTP by phone
      final verified = await authRepo.verifyOtp(
        verificationId: 'demo-test',
        smsCode: '123456',
        phoneNumber: '+91 98765 43210',
      );
      expect(verified.id, 'PT-84210');
    });
  });
}
