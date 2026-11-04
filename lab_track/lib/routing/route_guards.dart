import '../domain/enums/user_role.dart';
import '../data/models/user_model.dart';

/// Route guards for role-based navigation and authentication checks.
class RouteGuards {
  /// Verifies whether the active user possesses clearance for the targeted workspace.
  static bool canAccessRole(UserModel? user, UserRole requiredRole) {
    if (user == null) return false;
    if (user.role == UserRole.admin) return true;
    return user.role == requiredRole;
  }
}
