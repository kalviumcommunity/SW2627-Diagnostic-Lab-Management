import 'dart:convert';
import 'dart:io';

import '../lib/data/mock/seed_users.dart';
import '../lib/data/models/user_model.dart';

void main() {
  print('================================================================');
  print('🔬 LabTrack - Seed Users Validation & JSON Export Suite');
  print('================================================================');

  final total = kSeedUsers.length;
  print('📊 Total Seeded Personas: $total');
  assert(total == 5, 'Expected exactly 5 personas, found: $total');

  // 1. Role Distribution Checks
  final patients = kSeedUsers.where((u) => u.isPatient).toList();
  final phlebotomists = kSeedUsers.where((u) => u.isPhlebotomist).toList();
  final labTechs = kSeedUsers.where((u) => u.isLabTechnician).toList();
  final frontDesk = kSeedUsers.where((u) => u.isFrontDesk).toList();
  final admins = kSeedUsers.where((u) => u.isAdmin).toList();

  print('   ├─ Patients:        ${patients.length} (Expected: 1 - Virender)');
  print('   ├─ Phlebotomists:   ${phlebotomists.length} (Expected: 1 - Praveen)');
  print('   ├─ Lab Technicians: ${labTechs.length} (Expected: 1 - Aryan)');
  print('   ├─ Front Desk:      ${frontDesk.length} (Expected: 1 - Aryan)');
  print('   └─ Admins:          ${admins.length} (Expected: 1 - Ritu mam)');

  assert(patients.length == 1, 'Patients count must be 1');
  assert(phlebotomists.length == 1, 'Phlebotomists count must be 1');
  assert(labTechs.length == 1, 'Lab Technicians count must be 1');
  assert(frontDesk.length == 1, 'Front Desk count must be 1');
  assert(admins.length == 1, 'Admins count must be 1');

  // 2. Uniqueness Checks
  final idSet = <String>{};

  for (final user in kSeedUsers) {
    if (user.id.isEmpty) {
      throw Exception('User has empty id: $user');
    }
    if (!idSet.add(user.id)) {
      throw Exception('Duplicate user ID detected: ${user.id}');
    }

    // Check Serialization roundtrip
    final map = user.toMap();
    final roundtrip = UserModel.fromMap(map, documentId: user.id);
    assert(roundtrip.id == user.id, 'ID mismatch in roundtrip for ${user.id}');
    assert(roundtrip.name == user.name, 'Name mismatch for ${user.id}');
    assert(roundtrip.role == user.role, 'Role mismatch for ${user.id}');
  }

  print('✅ Uniqueness Verification:');
  print('   └─ Unique IDs: ${idSet.length} / 5');

  // 3. Staff Allocation Conversion Check
  final staffUsers = kSeedUsers.where((u) => !u.isPatient).toList();
  assert(staffUsers.length == 4, 'Staff users count must be 4');
  for (final staff in staffUsers) {
    final allocation = userToStaffAllocation(staff, assignedBranchName: 'Downtown Spoke Center #1');
    assert(allocation.id == staff.id, 'StaffAllocation ID mismatch');
    assert(allocation.name == staff.name, 'StaffAllocation name mismatch');
    assert(allocation.role == staff.role, 'StaffAllocation role mismatch');
  }
  print('✅ Staff Allocations verified for all 4 staff members.');

  // 4. Export to JSON
  final outputFile = File('tool/seed_users_export.json');
  final jsonList = kSeedUsers.map((u) => u.toMap()).toList();
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(jsonList),
  );
  print('💾 Exported 5 personas to: ${outputFile.path}');
  print('🎉 All Persona Verifications Passed Successfully!');
}
