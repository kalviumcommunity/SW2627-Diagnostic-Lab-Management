import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../data/models/sample_model.dart';
import '../providers/phlebotomist_provider.dart';
import 'order_detail_screen.dart';
import 'pickup_list_screen.dart';
import 'scan_vial_screen.dart';

class PhlebotomistHomeScreen extends StatefulWidget {
  const PhlebotomistHomeScreen({super.key});

  @override
  State<PhlebotomistHomeScreen> createState() => _PhlebotomistHomeScreenState();
}

class _PhlebotomistHomeScreenState extends State<PhlebotomistHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const _PhlebotomistDashboardTab(),
      const PickupListScreen(showAppBar: false),
      const ScanVialScreen(),
      const _ColdBoxCustodyTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phlebotomist - Doorstep Specimen Portal', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Refresh Queue',
            onPressed: () => context.read<PhlebotomistProvider>().refreshPickups(),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch Portal / Role',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD97706),
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User & Duty Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFFEF3C7),
                      child: const Icon(Icons.vaccines_rounded, color: Color(0xFFD97706), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Rahul Verma',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Field Phlebotomist • ID: ${user?.id ?? "PH-204"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // On Duty Toggle
                    Column(
                      children: [
                        Switch(
                          value: provider.isOnDuty,
                          activeColor: const Color(0xFFD97706),
                          onChanged: (val) => provider.toggleDutyStatus(),
                        ),
                        Text(
                          provider.isOnDuty ? 'On Duty' : 'Off Duty',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: provider.isOnDuty ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                // Live Cold Box Status Strip
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Portable Box Temp:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${provider.coldBoxTemp.toStringAsFixed(1)}°C (Cold-Chain Verified)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                    const Spacer(),
                    const Icon(Icons.battery_charging_full_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    const Text('92%', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Operational KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Today Pickups',
                  value: '${provider.todayTotalCount}',
                  subtitle: 'Doorstep visits',
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Pending',
                  value: '${provider.pendingPickups.length}',
                  subtitle: 'To collect',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'In Cold Box',
                  value: '${provider.collectedVialsCount}',
                  subtitle: 'Vials secured',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Next Stop / Immediate Priority Card
          if (nextOrder != null) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'NEXT SCHEDULED STOP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nextOrder.timeSlot,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      const Text('2.4 km away', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nextOrder.patientName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tests: ${nextOrder.testNames.join(", ")}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting GPS navigation to patient home...')),
                          );
                        },
                        icon: const Icon(Icons.navigation_rounded, size: 16),
                        label: const Text('Navigate Route', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          label: const Text('Start Collection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quick Workflow Shortcuts
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'QUICK ACTIONS & PROTOCOLS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action 1: Scan & Bind Vial
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFD97706)),
              ),
              title: const Text('Scan & Bind Sterile Vial Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Affix sterile barcodes and record cool-chain temperature on-site'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanVialScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Action 2: Pickup Queue
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.route_rounded, color: AppColors.primary),
              ),
              title: const Text('Today\'s Doorstep Route & Appointments', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('View patient home addresses, time slots, and fasting prerequisites'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PickupListScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Action 3: Batch Hub Handover
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.successLight,
                child: const Icon(Icons.move_to_inbox_rounded, color: AppColors.success),
              ),
              title: const Text('Batch Handover to Branch Hub Rack', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Transfer secured cold-box vials to central reception or courier bag'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => _showHubHandoverDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  static void _showHubHandoverDialog(BuildContext context) {
    final provider = context.read<PhlebotomistProvider>();
    final samples = provider.collectedSamples;

    if (samples.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vials currently in cold box to hand over.')),
      );
      return;
    }

    final receiverController = TextEditingController(text: 'Priya Sharma (Desk 01)');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.move_to_inbox_rounded, color: AppColors.success, size: 26),
                const SizedBox(width: 10),
                const Text(
                  'Branch Hub Courier Handover',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Transferring ${samples.length} collected specimens to Branch Hub 4 receiving counter.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Receiving Staff Name / Desk ID:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: receiverController,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                          content: Text('All specimens successfully transferred to Branch Hub 4!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Confirm Custody Transfer', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temperature Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Portable Gel Cold Box #08',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.coldBoxTemp.toStringAsFixed(1)} °C',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        const Text(
                          'Norm: 2.0°C - 8.0°C • Safe Cold Chain',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Secured Specimens Header
            Row(
              children: [
                const Text(
                  'Specimens in Custody',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(
                  '${samples.length} Vials',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (samples.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 10),
                    Text('Cold Box is Empty', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Collect samples to secure them in the cold box.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ...samples.map((s) => _buildSampleTile(context, s)),

            const SizedBox(height: 24),
            // Handover button
            if (samples.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _PhlebotomistDashboardTab._showHubHandoverDialog(context),
                  icon: const Icon(Icons.move_to_inbox_rounded),
                  label: const Text('Handover All Vials to Branch Hub', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _buildSampleTile(BuildContext context, SampleModel sample) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sample.barcode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sample.patientName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  sample.vialType,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  sample.temperatureStatus ?? '4.0°C (Intact)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sample.status.shortLabel,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
