import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/enums/user_role.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/god_level_card.dart';
import '../providers/auth_provider.dart';
import 'role_auth_screen.dart';
import 'signup_screen.dart';

/// God-Level Role Selection & Gateway Portal for LabTrack
/// Bio-Tech / Health Tech aesthetic with real-time operational telemetry,
/// 1-click instant demo launches, and role-specific glowing cards.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  UserRole? _loadingRole;
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleQuickDemoLogin(UserRole role) async {
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

  void _handleCustomAuth(UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoleAuthScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Futuristic Biotech Hero Header
                  _buildHeroHeader(),
                  const SizedBox(height: 24),

                  // Real-Time Telemetry Bar (4 KPI Tiles)
                  _buildTelemetryRibbon(),
                  const SizedBox(height: 32),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'OPERATIONAL WORKSPACES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '1-CLICK INSTANT DEMO ACCESS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Patient Portal
                  _buildGodLevelRoleCard(
                    role: UserRole.patient,
                    title: 'Patient Self-Service Portal',
                    badge: 'PATIENT',
                    personaName: 'John Doe',
                    description: 'Book home sample collection, track vial chain of custody live, and download digital PDF lab reports.',
                    icon: Icons.person_rounded,
                    accentColor: AppColors.primary,
                    gradient: AppColors.primaryGradient,
                    lightBg: AppColors.primaryLight,
                    featureTags: const ['Home Booking', 'Live Vial GPS', 'PDF Reports', 'TAT Tracking'],
                  ),
                  const SizedBox(height: 16),

                  // 2. Phlebotomist App
                  _buildGodLevelRoleCard(
                    role: UserRole.phlebotomist,
                    title: 'Phlebotomist Field Operations',
                    badge: 'FIELD OPS',
                    personaName: 'Rahul Verma (#PH-204)',
                    description: 'Doorstep pickup queue, barcode vial scan-and-bind, and IoT cool-chain ice pack temperature telemetry.',
                    icon: Icons.vaccines_rounded,
                    accentColor: const Color(0xFFD97706),
                    gradient: AppColors.amberOrangeGradient,
                    lightBg: const Color(0xFFFEF3C7),
                    featureTags: const ['Pickup Queue', 'Barcode Scan', 'Cold Box Sensor (4°C)', 'Route Nav'],
                  ),
                  const SizedBox(height: 16),

                  // 3. Front Desk Console
                  _buildGodLevelRoleCard(
                    role: UserRole.frontDesk,
                    title: 'Front Desk Reception Console',
                    badge: 'BRANCH HUB',
                    personaName: 'Priya Sharma (Desk #1)',
                    description: 'Walk-in patient registration, instant search by phone/barcode, and thermal specimen dispatch label printing.',
                    icon: Icons.desk_rounded,
                    accentColor: AppColors.accent,
                    gradient: AppColors.accentGradient,
                    lightBg: AppColors.accentLight,
                    featureTags: ['Instant Search', 'Walk-in Intake', 'Thermal Barcode', 'Spoke Dispatch'],
                  ),
                  const SizedBox(height: 16),

                  // 4. Lab Technician Portal
                  _buildGodLevelRoleCard(
                    role: UserRole.labTechnician,
                    title: 'Clinical Laboratory & Pathologist Station',
                    badge: 'CENTRAL LAB',
                    personaName: 'Dr. Sarah Chen (#LAB-501)',
                    description: 'Courier rack intake accessioning, specimen centrifugation, automated biochemistry analyzers, and electronic sign-off.',
                    icon: Icons.science_rounded,
                    accentColor: const Color(0xFF7C3AED),
                    gradient: AppColors.purpleIndigoGradient,
                    lightBg: const Color(0xFFF3E8FF),
                    featureTags: ['Rack Accessioning', 'Centrifuge QC', 'Biochemistry Analyzer', 'Digital Sign-off'],
                  ),
                  const SizedBox(height: 16),

                  // 5. Admin SLA Dashboard
                  _buildGodLevelRoleCard(
                    role: UserRole.admin,
                    title: 'Admin SLA & Turnaround Analytics',
                    badge: 'EXECUTIVE HQ',
                    personaName: 'Dr. Vikram Malhotra (HQ)',
                    description: 'Monitor TAT bottlenecks, courier dispatch SLAs, branch transit quotas, and lab compliance in real-time.',
                    icon: Icons.insights_rounded,
                    accentColor: const Color(0xFF4F46E5),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    lightBg: const Color(0xFFEEF2FF),
                    featureTags: ['TAT Bottlenecks', 'SLA Heatmap', 'Branch Quotas', 'Courier Fleet'],
                  ),
                  const SizedBox(height: 32),

                  // Enterprise Credentials & Alternative Login Options
                  _buildEnterpriseSection(),
                  const SizedBox(height: 28),

                  // Security & Compliance Footer
                  _buildComplianceFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        // Glowing Biotech Emblem
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35 * _glowAnimation.value),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.biotech_rounded,
                color: Colors.white,
                size: 40,
              ),
            );
          },
        ),
        const SizedBox(height: 18),

        // Brand Name with gradient feeling
        const Text(
          'LabTrack OS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'End-to-End Diagnostic Specimen Tracking & Chain-of-Custody',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Live Network Telemetry Status Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'LIVE NETWORK: 5 HUBS ONLINE • 99.98% SLA COMPLIANCE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.successDark,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTelemetryStat('4,820', 'Specimens Tracked', Icons.bloodtype_outlined, AppColors.primary),
          _buildVerticalDivider(),
          _buildTelemetryStat('18 min', 'Avg Hub Transit', Icons.timer_outlined, const Color(0xFFD97706)),
          _buildVerticalDivider(),
          _buildTelemetryStat('4.2°C', 'IoT Cold-Chain', Icons.ac_unit_rounded, AppColors.accent),
          _buildVerticalDivider(),
          _buildTelemetryStat('99.4%', 'On-Time SLA', Icons.verified_outlined, AppColors.success),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }

  Widget _buildTelemetryStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGodLevelRoleCard({
    required UserRole role,
    required String title,
    required String badge,
    required String personaName,
    required String description,
    required IconData icon,
    required Color accentColor,
    required LinearGradient gradient,
    required Color lightBg,
    required List<String> featureTags,
  }) {
    final isThisLoading = _loadingRole == role;

    return GodLevelCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      borderColor: isThisLoading ? accentColor : AppColors.border,
      hasGlow: isThisLoading,
      glowColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vibrant Icon Badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),

              // Title and Persona
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
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: lightBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Demo Persona: $personaName',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),

          // Feature capability pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: featureTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action Buttons: 1-Click Launch vs Sign In Options
          Row(
            children: [
              // 1-Click Launch Demo Button
              Expanded(
                flex: 3,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loadingRole != null ? null : () => _handleQuickDemoLogin(role),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isThisLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.bolt_rounded, size: 17, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Instant Demo Launch',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Secondary Enter Portal / Custom Login
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _loadingRole != null ? null : () => _handleCustomAuth(role),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Credentials',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'ENTERPRISE AUTHENTICATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleCustomAuth(UserRole.patient),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign In With Email / Phone', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Create New Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplianceFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield_outlined, size: 16, color: AppColors.textTertiary),
            SizedBox(width: 8),
            Text(
              'LabTrack v2.0 • ISO 15189 • HIPAA Compliant • 256-bit Cryptographic Chain',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Zero-Trust Role Based Access Control (RBAC) Architecture',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
