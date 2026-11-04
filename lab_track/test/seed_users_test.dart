import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/data/mock/seed_users.dart';
import 'package:lab_track/domain/enums/user_role.dart';
import 'package:lab_track/data/services/central_data_store.dart';
import 'package:lab_track/auth/backend/repositories/auth_repository.dart';

void main() {
  group('Seed Personas Tests (Virender, Praveen, Aryan, Ritu mam)', () {
    test('Contains the presentation personas across all 5 operational roles', () {
      expect(kSeedUsers.length, 5);

      final virender = kSeedUsers.firstWhere((u) => u.id == 'PT-VIRENDER');
      expect(virender.name, 'Virender');
      expect(virender.role, UserRole.patient);

      final praveen = kSeedUsers.firstWhere((u) => u.id == 'PH-PRAVEEN');
      expect(praveen.name, 'Praveen');
      expect(praveen.role, UserRole.phlebotomist);

      final aryanFd = kSeedUsers.firstWhere((u) => u.id == 'FD-ARYAN');
      expect(aryanFd.name, 'Aryan');
      expect(aryanFd.role, UserRole.frontDesk);

      final aryanLab = kSeedUsers.firstWhere((u) => u.id == 'LAB-ARYAN');
      expect(aryanLab.name, 'Aryan');
      expect(aryanLab.role, UserRole.labTechnician);

      final ritu = kSeedUsers.firstWhere((u) => u.id == 'ADM-RITU');
      expect(ritu.name, 'Ritu mam');
      expect(ritu.role, UserRole.admin);
    });

    test('All persona IDs and roles are valid', () {
      final ids = kSeedUsers.map((u) => u.id).toSet();
      expect(ids.length, 5);
      for (final u in kSeedUsers) {
        expect(u.id.isNotEmpty, isTrue);
        expect(u.name.isNotEmpty, isTrue);
        expect(u.phoneNumber.isNotEmpty, isTrue);
        expect(u.email, isNotNull);
        expect(u.email!.contains('@'), isTrue);
      }
    });

    test('CentralDataStore initializes clean staff roster and users', () {
      final store = CentralDataStore.instance;
      expect(store.users.isNotEmpty, isTrue);
      expect(store.staff.any((s) => s.id == 'PH-PRAVEEN'), isTrue);
      expect(store.staff.any((s) => s.id == 'FD-ARYAN'), isTrue);
      expect(store.staff.any((s) => s.id == 'LAB-ARYAN'), isTrue);
      expect(store.staff.any((s) => s.id == 'ADM-RITU'), isTrue);
    });

    test('AuthRepository defaults route directly to the 5 presentation personas', () {
      expect(AuthRepository.defaultDemoPatient.id, 'PT-VIRENDER');
      expect(AuthRepository.defaultDemoPhlebotomist.id, 'PH-PRAVEEN');
      expect(AuthRepository.defaultDemoFrontDesk.id, 'FD-ARYAN');
      expect(AuthRepository.defaultDemoLabTechnician.id, 'LAB-ARYAN');
      expect(AuthRepository.defaultDemoAdmin.id, 'ADM-RITU');
    });
  });
}
