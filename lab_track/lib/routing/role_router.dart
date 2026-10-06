import 'package:flutter/material.dart';
import '../domain/enums/user_role.dart';
import '../patient/frontend/screens/patient_home_screen.dart';
import '../phlebotomist/frontend/screens/phlebotomist_home_screen.dart';
import '../frontdesk/frontend/screens/frontdesk_home_screen.dart';
import '../admin/frontend/screens/admin_home_screen.dart';
import '../lab/frontend/screens/lab_home_screen.dart';

/// Routes authenticated users to their corresponding role-specific dashboard.
class RoleRouter {
  static Widget getHomeScreenForRole(UserRole? role) {
    switch (role) {
      case UserRole.phlebotomist:
        return const PhlebotomistHomeScreen();
      case UserRole.frontDesk:
        return const FrontDeskHomeScreen();
      case UserRole.admin:
        return const AdminHomeScreen();
      case UserRole.labTechnician:
        return const LabHomeScreen();
      case UserRole.patient:
      default:
        return const PatientHomeScreen();
    }
  }
}
