import 'dart:convert';
import 'dart:io';

import '../lib/data/mock/seed_users.dart';
import '../lib/data/models/user_model.dart';

void main() {
  print('================================================================');
  print('🔬 LabTrack - Seed Users Validation & JSON Export Suite');
  print('================================================================');

  final total = kSeedUsers.length;
  print('📊 Total Seeded Users: $total');
  assert(total == 100, 'Expected exactly 100 users, found: $total');

  // 1. Role Distribution Checks
  final patients = kSeedPatients;
  final phlebotomists = kSeedPhlebotomists;
  final labTechs = kSeedLabTechnicians;
  final frontDesk = kSeedFrontDesk;
  final admins = kSeedAdmins;

  print('   ├─ Patients:        ${patients.length} (Expected: 50)');
  print('   ├─ Phlebotomists:   ${phlebotomists.length} (Expected: 20)');
  print('   ├─ Lab Technicians: ${labTechs.length} (Expected: 12)');
  print('   ├─ Front Desk:      ${frontDesk.length} (Expected: 12)');
  print('   └─ Admins:          ${admins.length} (Expected: 6)');

  assert(patients.length == 50, 'Patients count must be 50');
  assert(phlebotomists.length == 20, 'Phlebotomists count must be 20');
  assert(labTechs.length == 12, 'Lab Technicians count must be 12');
  assert(frontDesk.length == 12, 'Front Desk count must be 12');
  assert(admins.length == 6, 'Admins count must be 6');

  // 2. Uniqueness Checks
  final idSet = <String>{};
  final phoneSet = <String>{};
  final emailSet = <String>{};

  for (final user in kSeedUsers) {
    // Check ID
    if (user.id.isEmpty) {
      throw Exception('User has empty id: $user');
    }
    if (!idSet.add(user.id)) {
      throw Exception('Duplicate user ID detected: ${user.id}');
    }

    // Check Phone
    final cleanPhone = user.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      throw Exception('User ${user.id} has empty phone');
    }
    if (!phoneSet.add(cleanPhone)) {
      throw Exception('Duplicate phone number detected: ${user.phoneNumber} in user ${user.id}');
    }

    // Check Email
    if (user.email == null || !user.email!.contains('@')) {
      throw Exception('User ${user.id} has invalid email: ${user.email}');
    }
    final cleanEmail = user.email!.toLowerCase().trim();
    if (!emailSet.add(cleanEmail)) {
      throw Exception('Duplicate email detected: ${user.email} in user ${user.id}');
    }

    // Check Name and Address
    if (user.name.trim().isEmpty) {
      throw Exception('User ${user.id} has empty name');
    }
    if (user.address == null || user.address!.trim().isEmpty) {
      throw Exception('User ${user.id} has empty address');
    }

    // Check Serialization roundtrip
    final map = user.toMap();
    final roundtrip = UserModel.fromMap(map, documentId: user.id);
    assert(roundtrip.id == user.id, 'ID mismatch in roundtrip for ${user.id}');
    assert(roundtrip.name == user.name, 'Name mismatch for ${user.id}');
    assert(roundtrip.role == user.role, 'Role mismatch for ${user.id}');
    assert(roundtrip.phoneNumber == user.phoneNumber, 'Phone mismatch for ${user.id}');
    assert(roundtrip.email == user.email, 'Email mismatch for ${user.id}');
  }

  print('✅ Uniqueness Verification:');
  print('   ├─ Unique IDs:    ${idSet.length} / 100');
  print('   ├─ Unique Phones: ${phoneSet.length} / 100');
  print('   └─ Unique Emails: ${emailSet.length} / 100');

  // 3. Staff Allocation Conversion Check
  final staffUsers = kSeedUsers.where((u) => !u.isPatient).toList();
  assert(staffUsers.length == 50, 'Staff users count must be 50');
  for (final staff in staffUsers) {
    final allocation = userToStaffAllocation(staff);
    assert(allocation.id == staff.id, 'StaffAllocation ID mismatch');
    assert(allocation.name == staff.name, 'StaffAllocation name mismatch');
    assert(allocation.role == staff.role, 'StaffAllocation role mismatch');
  }
  print('✅ Staff Allocations verified for all 50 staff members.');

  // 4. Export to JSON
  final jsonList = kSeedUsers.map((u) => u.toMap()).toList();
  final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

  final toolJsonFile = File('lab_track/tool/seed_users.json');
  toolJsonFile.writeAsStringSync(jsonString);
  print('💾 Exported JSON to: ${toolJsonFile.path} (${(jsonString.length / 1024).toStringAsFixed(1)} KB)');

  final dataDir = Directory('lab_track/assets/data');
  if (!dataDir.existsSync()) {
    dataDir.createSync(recursive: true);
  }
  final assetsJsonFile = File('lab_track/assets/data/seed_users.json');
  assetsJsonFile.writeAsStringSync(jsonString);
  print('💾 Exported JSON to: ${assetsJsonFile.path}');

  print('\n🎉 ALL 100 SEEDED USERS VALIDATED AND EXPORTED SUCCESSFULLY!');
}
