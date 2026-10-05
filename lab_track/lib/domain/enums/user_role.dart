// Enum representing user roles within the diagnostic lab management system.

enum UserRole {
  patient,
  phlebotomist,
  labTechnician,
  frontDesk,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.phlebotomist:
        return 'Phlebotomist';
      case UserRole.labTechnician:
        return 'Lab Technician';
      case UserRole.frontDesk:
        return 'Front Desk Staff';
      case UserRole.admin:
        return 'Lab Administrator';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase().trim()) {
      case 'phlebotomist':
        return UserRole.phlebotomist;
      case 'labtechnician':
      case 'lab_technician':
      case 'lab':
        return UserRole.labTechnician;
      case 'frontdesk':
      case 'front_desk':
        return UserRole.frontDesk;
      case 'admin':
        return UserRole.admin;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }

  String toValue() => name;
}
