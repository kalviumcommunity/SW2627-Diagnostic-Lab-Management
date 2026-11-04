import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/shared.dart';
import '../../../shared/services/pdf/pdf_report_service.dart';
import '../../../shared/widgets/appointment_qr_pass_modal.dart';
import '../../../shared/widgets/universal_qr_scanner_modal.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../auth/frontend/screens/profile_setup_screen.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/services/central_data_store.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../providers/patient_provider.dart';
import 'book_collection_screen.dart';
import 'past_bookings_screen.dart';
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
          children: [
            _PatientDashboardTab(onNavigateTab: _onTabTapped),
            BookCollectionScreen(onNavigateToTracking: (barcode) {
              _onTabTapped(3); // Navigate to Live Track
            }),
            PastBookingsScreen(
              onNavigateToBooking: () => _onTabTapped(1),
              onNavigateToTracking: (barcode) => _onTabTapped(3),
            ),
            const TrackSampleScreen(),
            const MyReportsScreen(),
          ],
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
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textTertiary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5),
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
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history_rounded),
                label: 'Bookings',
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
      ),
    );
  }
}

/// Simplified, Clean, Uncluttered Patient Dashboard
class _PatientDashboardTab extends StatelessWidget {
  final void Function(int) onNavigateTab;
  const _PatientDashboardTab({required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final user = authProvider.currentUser;
    final patientName = user?.name ?? 'Virender';
    final patientId = user?.id ?? 'PT-VIRENDER';

    // Find active order or sample in real time
    final activeOrders = patientProvider.orders;
    final activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;
    final activeSample = patientProvider.activeSample ??
        (activeOrder != null && activeOrder.sampleBarcodes.isNotEmpty
            ? CentralDataStore.instance.getSample(activeOrder.sampleBarcodes.first)
            : null);
    final reports = patientProvider.reports;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppColors.glowShadow(AppColors.primary, opacity: 0.25),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $patientName 👋',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  'Patient Record #$patientId',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Scan Barcode',
            onPressed: () async {
              final scanned = await UniversalQrScannerModal.show(
                context,
                title: 'Scan Receipt or Sample Barcode',
                hint: 'Scan sample barcode or receipt to track custody',
              );
              if (scanned != null && scanned.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrackSampleScreen(initialBarcode: scanned)),
                );
              }
            },
          ),
          TextButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primary),
            label: const Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await patientProvider.refreshPatientData(patientId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Active Booking Status Card
              if (activeOrder != null) ...[
                _buildActiveOrderCard(context, activeOrder, activeSample),
                const SizedBox(height: 20),
              ] else ...[
                _buildEmptyBookingHero(context),
                const SizedBox(height: 20),
              ],

              // 2. Section Header: Quick Services
              const Text(
                'CORE SERVICES',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              // 4 Core Action Tiles (Simple 2x2 Grid)
              Row(
                children: [
                  Expanded(
                    child: _buildServiceTile(
                      title: 'Book Test',
                      subtitle: 'Doorstep blood draw',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      bgColor: const Color(0xFFEFF6FF),
                      onTap: () => onNavigateTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildServiceTile(
                      title: 'Past Bookings',
                      subtitle: '${activeOrders.length} appointments',
                      icon: Icons.history_rounded,
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                      onTap: () => onNavigateTab(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildServiceTile(
                      title: 'Live Track',
                      subtitle: 'Real-time custody',
                      icon: Icons.radar_rounded,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                      onTap: () => onNavigateTab(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildServiceTile(
                      title: 'My Reports',
                      subtitle: '${reports.length} diagnostic PDFs',
                      icon: Icons.description_rounded,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFD1FAE5),
                      onTap: () => onNavigateTab(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Section Header: Recent Reports
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT TEST REPORTS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: AppColors.textPrimary),
                  ),
                  if (reports.isNotEmpty)
                    TextButton(
                      onPressed: () => onNavigateTab(4),
                      child: const Text('View All', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (reports.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.description_outlined, color: Colors.grey, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No Reports Published Yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                            SizedBox(height: 2),
                            Text('Reports will appear here once signed by pathologist.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...reports.take(2).map((r) => _buildSimpleReportTile(context, r)),
            ],
          ),
        ),
      ),
    );
  }

  /// Clean Active Booking Card with Instant Mutual QR Pass Trigger
  Widget _buildActiveOrderCard(BuildContext context, OrderModel order, SampleModel? sample) {
    final isVerified = order.doorstepVerifiedAt != null;
    final isCollected = sample != null && sample.status != SampleStatus.booked;
    final isInLab = sample != null &&
        (sample.status == SampleStatus.receivedAtLab || sample.status == SampleStatus.processing);
    final isReportReady = sample != null && sample.status == SampleStatus.reportReady;

    String statusText;
    Color statusBg;
    Color statusColor;

    if (isReportReady) {
      statusText = '● Report Published & Ready';
      statusBg = const Color(0xFFD1FAE5);
      statusColor = const Color(0xFF047857);
    } else if (isInLab) {
      statusText = '● Testing in Central Lab (Aryan)';
      statusBg = const Color(0xFFF3E8FF);
      statusColor = const Color(0xFF7C3AED);
    } else if (isCollected) {
      statusText = '● Sample Collected • Cold Box (#08)';
      statusBg = const Color(0xFFE0F2FE);
      statusColor = const Color(0xFF0284C7);
    } else if (isVerified) {
      statusText = '● Phlebotomist at Doorstep • Blood Draw Active';
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
    } else {
      statusText = '● Booking Confirmed • Praveen Assigned';
      statusBg = const Color(0xFFEFF6FF);
      statusColor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
              Text(
                '#${order.id}',
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.testNames.isNotEmpty ? order.testNames.join(', ') : 'Complete Diagnostic Panel',
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Slot: ${order.timeSlot} • ${order.collectionAddress.split(",").first}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Doorstep QR Pass + Live Track
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => AppointmentQrPassModal.show(context, order),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Show Doorstep QR Pass', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => onNavigateTab(3),
                  icon: const Icon(Icons.radar_rounded, size: 16),
                  label: const Text('Live Track', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBookingHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroNavyGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'FAST DOORSTEP BLOOD COLLECTION',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Schedule Blood Test at Home',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Phlebotomist Praveen visits your doorstep with sterile barcoded vials & active cold-chain box.',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => onNavigateTab(1),
            icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
            label: const Text('Book Test Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleReportTile(BuildContext context, ReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF047857), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.testName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  'Signed by ${report.pathologistName ?? "Aryan"} • ${report.verificationDate != null ? DateFormat("dd MMM yyyy").format(report.verificationDate!) : "Ready"}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              PdfReportService.downloadOfficialPdf(
                context: context,
                report: report,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View PDF', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}
