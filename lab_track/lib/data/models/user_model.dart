import '../../domain/enums/user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final UserRole role;
  final String? address;
  final int? age;
  final String? gender;
  final String? emergencyContact;
  final String? assignedBranchId;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.role = UserRole.patient,
    this.address,
    this.age,
    this.gender,
    this.emergencyContact,
    this.assignedBranchId,
    required this.createdAt,
  });

  bool get isPatient => role == UserRole.patient;
  bool get isPhlebotomist => role == UserRole.phlebotomist;
  bool get isLabTechnician => role == UserRole.labTechnician;
  bool get isFrontDesk => role == UserRole.frontDesk;
  bool get isAdmin => role == UserRole.admin;

  UserModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    UserRole? role,
    String? address,
    int? age,
    String? gender,
    String? emergencyContact,
    String? assignedBranchId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      address: address ?? this.address,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      assignedBranchId: assignedBranchId ?? this.assignedBranchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role.toValue(),
      'address': address,
      'age': age,
      'gender': gender,
      'emergencyContact': emergencyContact,
      'assignedBranchId': assignedBranchId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return UserModel(
      id: documentId ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      email: map['email']?.toString(),
      role: UserRole.fromString(map['role']?.toString()),
      address: map['address']?.toString(),
      age: map['age'] != null ? int.tryParse(map['age'].toString()) : null,
      gender: map['gender']?.toString(),
      emergencyContact: map['emergencyContact']?.toString(),
      assignedBranchId: map['assignedBranchId']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
