import '../../domain/enums/user_role.dart';
import '../models/user_model.dart';
import '../../admin/backend/models/sla_metric_model.dart';

/// Clean Dedicated Seed Dataset of the 5 Presentation Personas:
/// - Patient: Virender
/// - Phlebotomist: Praveen
/// - Front Desk: Aryan
/// - Lab Technician: Aryan
/// - Admin: Ritu mam

final List<UserModel> kSeedUsers = [
  UserModel(
    id: 'PT-VIRENDER',
    name: 'Virender',
    phoneNumber: '+91 98765 00003',
    email: 'virender@labtrack.com',
    role: UserRole.patient,
    address: 'House 420, Tension Colony, New Delhi',
    age: 24,
    gender: 'Male',
    emergencyContact: '+91 98765 99999',
    assignedBranchId: 'branch-spoke-01',
    createdAt: DateTime(2026, 8, 1, 9, 30),
  ),
  UserModel(
    id: 'PH-PRAVEEN',
    name: 'Praveen',
    phoneNumber: '+91 98765 00002',
    email: 'praveen@labtrack.com',
    role: UserRole.phlebotomist,
    address: 'Downtown Spoke Center #1, Connaught Place',
    age: 24,
    gender: 'Male',
    emergencyContact: '+91 98765 99999',
    assignedBranchId: 'branch-spoke-01',
    createdAt: DateTime(2026, 7, 1, 9, 0),
  ),
  UserModel(
    id: 'FD-ARYAN',
    name: 'Aryan',
    phoneNumber: '+91 98765 00001',
    email: 'aryan.frontdesk@labtrack.com',
    role: UserRole.frontDesk,
    address: 'Downtown Spoke Center Reception Desk',
    age: 24,
    gender: 'Male',
    emergencyContact: '+91 98765 99999',
    assignedBranchId: 'branch-spoke-01',
    createdAt: DateTime(2026, 1, 1, 9, 0),
  ),
  UserModel(
    id: 'LAB-ARYAN',
    name: 'Aryan',
    phoneNumber: '+91 98765 00001',
    email: 'aryan.lab@labtrack.com',
    role: UserRole.labTechnician,
    address: 'Apex Central Reference Laboratory HQ, Gurugram',
    age: 24,
    gender: 'Male',
    emergencyContact: '+91 98765 99999',
    assignedBranchId: 'branch-apex-hq',
    createdAt: DateTime(2026, 1, 1, 9, 0),
  ),
  UserModel(
    id: 'ADM-RITU',
    name: 'Ritu mam',
    phoneNumber: '+91 98765 00000',
    email: 'ritu.admin@labtrack.com',
    role: UserRole.admin,
    address: 'Apex Central Reference Laboratory HQ, Gurugram',
    age: 35,
    gender: 'Female',
    emergencyContact: '+91 98765 99999',
    assignedBranchId: 'branch-apex-hq',
    createdAt: DateTime(2026, 1, 1, 9, 0),
  ),
];

StaffAllocationModel userToStaffAllocation(
  UserModel u, {
  required String assignedBranchName,
  bool isOnDuty = true,
  int todayCompletedTasks = 0,
  int pendingTasks = 0,
  double avgRating = 5.0,
}) {
  return StaffAllocationModel(
    id: u.id,
    name: u.name,
    email: u.email ?? '${u.id.toLowerCase()}@labtrack.com',
    phoneNumber: u.phoneNumber,
    role: u.role,
    assignedBranchId: u.assignedBranchId ?? 'branch-apex-hq',
    assignedBranchName: assignedBranchName,
    isOnDuty: isOnDuty,
    todayCompletedTasks: todayCompletedTasks,
    pendingTasks: pendingTasks,
    avgRating: avgRating,
  );
}

final Map<String, UserModel> kSeedUsersById = {
  for (final u in kSeedUsers) u.id: u,
};

final Map<String, UserModel> kSeedUsersByEmail = {
  for (final u in kSeedUsers) if (u.email != null) u.email!.toLowerCase().trim(): u,
};

final Map<String, UserModel> kSeedUsersByPhone = {
  for (final u in kSeedUsers) u.phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''): u,
};
