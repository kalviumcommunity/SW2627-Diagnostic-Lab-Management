import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/enums/user_role.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Startup screen presenting the 4 core diagnostic system personas:
/// 1. Patient
/// 2. Phlebotomist
/// 3. Front Desk
/// 4. Admin
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _loadingRole;

  Future<void> _handleRoleSelect(UserRole role) async {
    setState(() => _loadingRole = role);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginAsRole(role);

    if (!mounted) return;
    setState(() => _loadingRole = null);

    if (!success && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  _buildHeader(),
                  const SizedBox(height: 28),

                  // Role Cards Section Title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SELECT WORKSPACE / PORTAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 1. Patient Card
                  _buildRoleCard(
                    role: UserRole.patient,
                    title: 'Patient Portal',
                    badge: 'Self-Service',
                    personaName: 'John Doe',
                    description: 'Book home collection, track vial chain of custody live, and view PDF test reports.',
                    icon: Icons.person_rounded,
                    accentColor: AppColors.primary,
                    bgColor: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 14),

                  // 2. Phlebotomist Card
                  _buildRoleCard(
                    role: UserRole.phlebotomist,
                    title: 'Phlebotomist App',
                    badge: 'Field Operations',
                    personaName: 'Rahul Verma (#PH-204)',
                    description: 'Doorstep blood sample collection, barcode vial scan-and-bind, and cool-chain temperature logs.',
                    icon: Icons.vaccines_rounded,
                    accentColor: const Color(0xFFD97706), // Warm Amber
                    bgColor: const Color(0xFFFEF3C7),
                  ),
                  const SizedBox(height: 14),

                  // 3. Front Desk Card
                  _buildRoleCard(
                    role: UserRole.frontDesk,
                    title: 'Front Desk Console',
                    badge: 'Branch Counter',
                    personaName: 'Priya Sharma (Desk #1)',
                    description: 'Walk-in patient registration, quick order search by phone/barcode, and slip printing.',
                    icon: Icons.desk_rounded,
                    accentColor: AppColors.accent,
                    bgColor: AppColors.accentLight,
                  ),
                  const SizedBox(height: 14),

                  // 4. Admin Card
                  _buildRoleCard(
                    role: UserRole.admin,
                    title: 'Admin SLA Dashboard',
                    badge: 'Management & TAT',
                    personaName: 'Dr. Vikram Malhotra (HQ)',
                    description: 'Monitor TAT bottlenecks, courier dispatch SLAs, branch transit quotas, and lab compliance.',
                    icon: Icons.insights_rounded,
                    accentColor: const Color(0xFF6366F1), // Indigo
                    bgColor: const Color(0xFFEEF2FF),
                  ),
                  const SizedBox(height: 28),

                  // Divider with Traditional Login Option
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR ENTERPRISE AUTHENTICATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Phone OTP Login Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.phone_android_rounded, size: 20, color: AppColors.textPrimary),
                    label: const Text(
                      'Log in with Mobile Phone & OTP',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield_outlined, size: 15, color: AppColors.textTertiary),
                      SizedBox(width: 6),
                      Text(
                        'LabTrack v2.0 • Zero-Trust Role Based Access Control',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.biotech_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'LabTrack',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Diagnostic Lab & Specimen Tracking System',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String badge,
    required String personaName,
    required String description,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    final isThisLoading = _loadingRole == role;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: _loadingRole != null ? null : () => _handleRoleSelect(role),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isThisLoading ? accentColor : AppColors.border,
              width: isThisLoading ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 14),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.account_circle_outlined, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Demo User: $personaName',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Action Arrow / Loader
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: isThisLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
