import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/admin_provider.dart';
import 'sla_dashboard_screen.dart';
import 'branch_management_screen.dart';
import 'staff_management_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: const _AdminHomeScreenScaffold(),
    );
  }
}

class _AdminHomeScreenScaffold extends StatefulWidget {
  const _AdminHomeScreenScaffold();

  @override
  State<_AdminHomeScreenScaffold> createState() => _AdminHomeScreenScaffoldState();
}

class _AdminHomeScreenScaffoldState extends State<_AdminHomeScreenScaffold> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _AdminOverviewTab(onNavigateToTab: _navigateToTab),
      const SlaDashboardScreen(showAppBar: false),
      const BranchManagementScreen(showAppBar: false),
      const StaffManagementScreen(showAppBar: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin SLA & TAT Analytics', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => context.read<AdminProvider>().refresh(),
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
        selectedItemColor: const Color(0xFF6366F1), // Royal Indigo
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_outlined),
            activeIcon: Icon(Icons.speed_rounded),
            label: 'SLA & TAT',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hub_outlined),
            activeIcon: Icon(Icons.hub_rounded),
            label: 'Branches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge_rounded),
            label: 'Staff Fleet',
          ),
        ],
      ),
    );
  }
}

class _AdminOverviewTab extends StatelessWidget {
  final void Function(int) onNavigateToTab;
  const _AdminOverviewTab({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final provider = context.watch<AdminProvider>();
    final kpis = provider.kpis;
    final alerts = provider.alerts.where((a) => !a.isResolved).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header Card
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6366F1), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Dr. Vikram Malhotra',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lab Operations Director • ${user?.assignedBranchId ?? "Apex HQ Operations"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Switch Role', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Operational KPI Cards Row 1
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Daily Volume',
                  value: '${kpis['totalDailyVolume'] ?? 1420}',
                  subtitle: 'Total samples',
                  icon: Icons.biotech_rounded,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'SLA Compliance',
                  value: '${kpis['slaComplianceRate'] ?? 96.8}%',
                  subtitle: 'On-time reports',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'Avg TAT',
                  value: '${kpis['avgTatHours'] ?? 3.2}h',
                  subtitle: 'Turnaround time',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFEEF2FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Operational KPI Cards Row 2
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'In Transit',
                  value: '${kpis['activeInTransit'] ?? 84}',
                  subtitle: 'Courier relays',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'Active Fleet',
                  value: '${kpis['onDutyStaffCount'] ?? 5}',
                  subtitle: 'Staff on duty',
                  icon: Icons.badge_outlined,
                  color: AppColors.accent,
                  bgColor: AppColors.accentLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'Escalations',
                  value: '${alerts.length}',
                  subtitle: 'Open alerts',
                  icon: Icons.warning_amber_rounded,
                  color: alerts.isNotEmpty ? AppColors.error : AppColors.success,
                  bgColor: alerts.isNotEmpty ? AppColors.errorLight : AppColors.successLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custody Pipeline Monitor Strip
          _buildPipelineStrip(context),
          const SizedBox(height: 20),

          // Operational Alerts Section
          if (alerts.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'CRITICAL OPERATIONAL ESCALATIONS & ALERTS',
              accentColor: AppColors.error,
            ),
            const SizedBox(height: 10),
            ...alerts.map((a) => _buildAlertCard(context, a)),
            const SizedBox(height: 20),
          ],

          // Quick Navigation Protocols
          _buildSectionHeader(
            title: 'ADMINISTRATIVE WORKFLOWS & PORTALS',
            accentColor: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.speed_rounded, color: Color(0xFF6366F1)),
              ),
              title: const Text('SLA Turnaround Time Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Monitor branch transit bottlenecks, test benchmarks, and rejection root causes'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => onNavigateToTab(1),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.hub_rounded, color: AppColors.primary),
              ),
              title: const Text('Multi-Branch Custody Topology', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Inspect Spoke centers, central testing labs, and courier relay health'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => onNavigateToTab(2),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(Icons.badge_rounded, color: Color(0xFFD97706)),
              ),
              title: const Text('Staff & Phlebotomist Fleet Allocation', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Roster management, live duty status, and cross-branch task reallocation'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => onNavigateToTab(3),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required Color accentColor}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStrip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timeline_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Live Specimen Pipeline Stages',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Spacer(),
              Text('Real-time Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              _PipelineStage(label: 'Booked', count: '142', color: Color(0xFF64748B)),
              _PipelineArrow(),
              _PipelineStage(label: 'Collected', count: '98', color: Color(0xFFD97706)),
              _PipelineArrow(),
              _PipelineStage(label: 'In Transit', count: '84', color: AppColors.warning),
              _PipelineArrow(),
              _PipelineStage(label: 'Bench', count: '48', color: AppColors.info),
              _PipelineArrow(),
              _PipelineStage(label: 'Ready', count: '1,285', color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, dynamic alert) {
    final bool isCritical = alert.severity == 'critical';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
            size: 20,
            color: isCritical ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCritical ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.read<AdminProvider>().resolveAlert(alert.id),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Resolve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _PipelineStage extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _PipelineStage({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PipelineArrow extends StatelessWidget {
  const _PipelineArrow();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textTertiary);
  }
}
