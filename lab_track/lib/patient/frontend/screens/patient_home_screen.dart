import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/shared.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../auth/frontend/screens/profile_setup_screen.dart';
import '../providers/patient_provider.dart';
import 'book_collection_screen.dart';
import 'track_sample_screen.dart';
import 'my_reports_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressed;

  final List<Widget> _tabs = const [
    _PatientDashboardTab(),
    BookCollectionScreen(),
    TrackSampleScreen(),
    MyReportsScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _tabHistory.add(index);
    });
  }

  void _handleBackPress() {
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      setState(() => _currentIndex = _tabHistory.last);
      return;
    }
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _tabHistory.clear();
        _tabHistory.add(0);
      });
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit LabTrack'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle_rounded),
              label: 'Book Test',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar_outlined),
              activeIcon: Icon(Icons.radar_rounded),
              label: 'Live Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: 'My Reports',
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientDashboardTab extends StatelessWidget {
  const _PatientDashboardTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final user = authProvider.currentUser;
    final patientName = user?.name ?? 'John Doe';
    final patientId = user?.id ?? 'PT-84210';
    final activeSample = patientProvider.activeSample;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.glowShadow(AppColors.primary, opacity: 0.25),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VERIFIED PATIENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Patient Record: #$patientId',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Scan Receipt / Sample Barcode',
            onPressed: () async {
              final scanned = await UniversalQrScannerModal.show(
                context,
                title: 'Scan Receipt or Sample Barcode',
                hint: 'Scan receipt QR or test vial barcode to track live custody',
              );
              if (scanned != null && scanned.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackSampleScreen(initialBarcode: scanned),
                  ),
                );
              }
            },
          ),
          // Switch portal button
          TextButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primary),
            label: const Text(
              'Switch Portal',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) async {
              if (val == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                );
              } else if (val == 'logout' || val == 'switch_role') {
                await context.read<AuthProvider>().logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'switch_role',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Switch Workspace'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Health Profile'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // God-Level Home Booking CTA Banner
            _buildActionBanner(context),
            const SizedBox(height: 24),

            // Active Sample In-Transit Live Radar
            if (activeSample != null) ...[
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: AppColors.amberOrangeGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE SPECIMEN IN-TRANSIT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const CoolChainBadge(compact: true),
                ],
              ),
              const SizedBox(height: 12),
              _buildActiveSampleCard(context, activeSample),
              const SizedBox(height: 24),
            ],

            // Quick Actions Hub
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'QUICK SERVICES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context),
            const SizedBox(height: 24),

            // Recent Reports Section
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'RECENT DIAGNOSTIC REPORTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyReportsScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...patientProvider.reports.take(2).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecentReportCard(
                    context: context,
                    report: r,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroNavyGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: AppColors.electricCyan.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.electricCyan.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt_rounded, color: AppColors.electricCyan, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '45-MIN DOORSTEP DISPATCH AVAILABLE',
                      style: TextStyle(
                        color: AppColors.electricCyan,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.ac_unit_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      '2°C - 8°C Cool-Box Certified',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Schedule Home Specimen Pickup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A certified phlebotomist arrives with sterile barcoded vacuum vials, digital consent, and temperature-logged cold transport.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookCollectionScreen()),
              );
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
            label: const Text(
              'Book Collection Appointment',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSampleCard(BuildContext context, dynamic sample) {
    return GodLevelCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.warning.withOpacity(0.4),
      hasGlow: true,
      glowColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.amberOrangeGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample.testNames.isNotEmpty ? sample.testNames.first : 'Comprehensive Metabolic Panel',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'BARCODE #${sample.barcode}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const CoolChainBadge(compact: true),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              PulsingStatusBadge.fromSampleStatus(sample.status),
            ],
          ),
          const SizedBox(height: 18),

          // High-Tech Horizontal Progress Stepper
          Row(
            children: [
              _buildStepItem(label: 'Collected', isDone: true, isActive: false),
              _buildStepConnector(isDone: true),
              _buildStepItem(label: 'In Transit', isDone: false, isActive: true),
              _buildStepConnector(isDone: false),
              _buildStepItem(label: 'At Central Lab', isDone: false, isActive: false),
              _buildStepConnector(isDone: false),
              _buildStepItem(label: 'Testing & QC', isDone: false, isActive: false),
            ],
          ),
          const SizedBox(height: 18),

          // Contextual Info Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation_rounded, color: AppColors.warningDark, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sample.notes ?? 'Vial in IoT cold-chain transit from Spoke-01 to Central Reference Hub.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warningDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackSampleScreen(initialBarcode: sample.barcode),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Track Live',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warningDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({required String label, required bool isDone, required bool isActive}) {
    Color bg = isDone ? AppColors.success : (isActive ? AppColors.warning : AppColors.borderLight);
    Color fg = isDone || isActive ? Colors.white : AppColors.textTertiary;

    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.warningDark : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isDone ? Icons.check : (isActive ? Icons.navigation : Icons.circle),
              color: fg,
              size: 13,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive || isDone ? FontWeight.w800 : FontWeight.w500,
            color: isActive ? AppColors.warningDark : (isDone ? AppColors.textPrimary : AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDone ? AppColors.success : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            title: 'Book Visit',
            subtitle: 'Home Sample',
            icon: Icons.calendar_today_rounded,
            color: AppColors.primary,
            gradient: AppColors.primaryGradient,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BookCollectionScreen()));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionTile(
            title: 'Live Radar',
            subtitle: 'Vial Tracking',
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.accent,
            gradient: AppColors.accentGradient,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TrackSampleScreen()));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionTile(
            title: 'My Reports',
            subtitle: 'PDF Vault',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFF8B5CF6),
            gradient: AppColors.purpleIndigoGradient,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReportsScreen()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GodLevelCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportCard({
    required BuildContext context,
    required ReportModel report,
  }) {
    return GodLevelCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyReportsScreen()),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: report.isReady ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              report.isReady ? Icons.verified_rounded : Icons.hourglass_top_rounded,
              color: report.isReady ? AppColors.successDark : AppColors.warningDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.testName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.branchName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: AppColors.textTertiary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      report.isReady ? 'Verified & Signed' : 'In Analysis',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: report.isReady ? AppColors.successDark : AppColors.warningDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: report.isReady ? AppColors.primaryLight : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  report.isReady ? Icons.download_rounded : Icons.visibility_rounded,
                  size: 14,
                  color: report.isReady ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  report.isReady ? 'PDF' : 'Track',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: report.isReady ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
