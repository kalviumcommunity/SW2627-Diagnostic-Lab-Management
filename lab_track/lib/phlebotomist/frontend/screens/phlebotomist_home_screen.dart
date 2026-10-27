import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../shared/shared.dart';
import '../providers/phlebotomist_provider.dart';
import 'order_detail_screen.dart';
import 'pickup_list_screen.dart';
import 'scan_vial_screen.dart';

/// God-Level Phlebotomist Doorstep Operations Cockpit
class PhlebotomistHomeScreen extends StatefulWidget {
  const PhlebotomistHomeScreen({super.key});

  @override
  State<PhlebotomistHomeScreen> createState() => _PhlebotomistHomeScreenState();
}

class _PhlebotomistHomeScreenState extends State<PhlebotomistHomeScreen> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressed;

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
    final List<Widget> tabs = [
      const _PhlebotomistDashboardTab(),
      const PickupListScreen(showAppBar: false),
      const ScanVialScreen(),
      const _ColdBoxCustodyTab(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.amberOrangeGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppColors.glowShadow(const Color(0xFFD97706), opacity: 0.3),
              ),
              child: const Icon(Icons.vaccines_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Field Phlebotomy Station', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Refresh Queue',
            onPressed: () => context.read<PhlebotomistProvider>().refreshPickups(),
          ),
          TextButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFFD97706)),
            label: const Text('Switch Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: const Color(0xFFFEF3C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFD97706),
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Command',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_bulleted_rounded),
              activeIcon: Icon(Icons.fact_check_rounded),
              label: 'Pickups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Scan Vial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit_outlined),
              activeIcon: Icon(Icons.ac_unit_rounded),
              label: 'Cold Box',
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _PhlebotomistDashboardTab extends StatelessWidget {
  const _PhlebotomistDashboardTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final provider = context.watch<PhlebotomistProvider>();
    final nextOrder = provider.pendingPickups.isNotEmpty ? provider.pendingPickups.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operative Cockpit Status Card
          GodLevelCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            hasGlow: true,
            glowColor: const Color(0xFFD97706),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.amberOrangeGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.glowShadow(const Color(0xFFD97706), opacity: 0.3),
                      ),
                      child: const Icon(Icons.badge_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.name ?? 'Rahul Verma',
                                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CERTIFIED PHLEBO',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Field Operative • Badge #${user?.id ?? "PH-204"} • Hub Spoke-01',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Duty Switch
                    Column(
                      children: [
                        Switch(
                          value: provider.isOnDuty,
                          activeColor: const Color(0xFFD97706),
                          onChanged: (val) => provider.toggleDutyStatus(),
                        ),
                        Text(
                          provider.isOnDuty ? 'ACTIVE ON DUTY' : 'STANDBY',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: provider.isOnDuty ? AppColors.successDark : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // IoT Cold Box Live Sensor Telemetry Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cold Box Sensor:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.coldBoxTemp.toStringAsFixed(1)}°C',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.successDark),
                      ),
                      const SizedBox(width: 6),
                      const Text('(Safe Zone 2-8°C)', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      const Spacer(),
                      const Icon(Icons.battery_charging_full_rounded, size: 16, color: AppColors.successDark),
                      const SizedBox(width: 4),
                      const Text('92% IoT Batt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Operational KPI Cards
          Row(
            children: [
              Expanded(
                child: TelemetryMetricCard(
                  title: 'Today Pickups',
                  value: '${provider.todayTotalCount}',
                  subtitle: 'Doorstep visits',
                  icon: Icons.assignment_outlined,
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TelemetryMetricCard(
                  title: 'Pending Queue',
                  value: '${provider.pendingPickups.length}',
                  subtitle: 'To collect',
                  icon: Icons.hourglass_top_rounded,
                  accentColor: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TelemetryMetricCard(
                  title: 'Cold Box Vials',
                  value: '${provider.collectedVialsCount}',
                  subtitle: 'Secured at 4°C',
                  icon: Icons.check_circle_outline_rounded,
                  accentColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Next Stop Priority Card
          if (nextOrder != null) ...[
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
                  'NEXT IMMEDIATE DOORSTEP STOP',
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
            GodLevelCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 18,
              borderColor: const Color(0xFFF59E0B).withOpacity(0.5),
              hasGlow: true,
              glowColor: const Color(0xFFD97706),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                        ),
                        child: Text(
                          nextOrder.timeSlot,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      const Text(
                        '2.4 km away',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nextOrder.patientName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          nextOrder.collectionAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Required Tests: ${nextOrder.testNames.join(", ")}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting GPS route navigation to patient doorstep...')),
                          );
                        },
                        icon: const Icon(Icons.navigation_rounded, size: 16),
                        label: const Text('Turn-by-Turn GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailScreen(order: nextOrder),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                          label: const Text('Begin Collection', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],

          // Protocols Hub
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
                'STANDARD OPERATING PROTOCOLS',
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

          // Protocol 1: Scan & Bind Barcode
          GodLevelCard(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanVialScreen()));
            },
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Scan Barcode & Bind Specimen Vial',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Link physical EDTA/Serum vial to patient record digitally.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Protocol 2: Handover to Branch Spoke
          GodLevelCard(
            onTap: () => _showHubHandoverDialog(context),
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.emeraldTealGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.move_to_inbox_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Handover Cold Box to Spoke Lab',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Transfer batch chain-of-custody to Branch Desk.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showHubHandoverDialog(BuildContext context) {
    final provider = context.read<PhlebotomistProvider>();
    final samples = provider.collectedSamples;
    final receiverController = TextEditingController(text: 'Priya Sharma (Desk #1)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.handshake_outlined, color: AppColors.successDark, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Branch Hub Handover', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transferring ${samples.length} collected vials to Branch Hub receiving desk.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Receiving Staff Name / Desk ID:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: receiverController,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final barcodes = samples.map((s) => s.barcode).toList();
                  final success = await provider.handoverBatchToHub(
                    phlebotomistId: 'PH-204',
                    branchId: 'BR-004',
                    branchName: 'Branch Hub 4 - Central',
                    sampleBarcodes: barcodes,
                    receiverName: receiverController.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All specimens successfully transferred to Branch Hub receiving desk!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Confirm Custody Transfer', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColdBoxCustodyTab extends StatelessWidget {
  const _ColdBoxCustodyTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhlebotomistProvider>();
    final samples = provider.collectedSamples;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // High-Tech Temperature Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cyanTealGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.glowShadow(AppColors.accent, opacity: 0.28),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IoT Active Gel Cooler Box #08',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.coldBoxTemp.toStringAsFixed(1)} °C',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Standard: 2.0°C - 8.0°C • Cold-Chain Certified',
                          style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Secured Specimens Header
            Row(
              children: [
                const Text(
                  'Vials in Cold Box Custody',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${samples.length} Secured Vials',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (samples.isEmpty)
              GodLevelCard(
                padding: const EdgeInsets.all(36),
                borderRadius: 18,
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
                      SizedBox(height: 12),
                      Text('Cold Box is Ready & Empty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('Doorstep collected vials will appear here automatically.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              ...samples.map((s) => _buildSampleTile(context, s)),

            const SizedBox(height: 24),
            // Handover button
            if (samples.isNotEmpty)
              GlowingActionButton(
                label: 'Handover All Specimens to Spoke Lab',
                icon: Icons.move_to_inbox_rounded,
                gradient: AppColors.emeraldTealGradient,
                glowColor: AppColors.success,
                onPressed: () => _PhlebotomistDashboardTab._showHubHandoverDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleTile(BuildContext context, SampleModel sample) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GodLevelCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Text(
                sample.barcode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sample.patientName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vial: ${sample.vialType}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  Text(
                    sample.temperatureStatus ?? '4.2°C (Cold-Chain Verified)',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.successDark),
                  ),
                ],
              ),
            ),
            PulsingStatusBadge.fromSampleStatus(sample.status),
          ],
        ),
      ),
    );
  }
}
