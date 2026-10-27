import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../auth/frontend/providers/auth_provider.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../shared/theme/app_colors.dart';
import '../../backend/models/lab_rack_model.dart';
import '../providers/lab_provider.dart';
import '../widgets/pathologist_sign_dialog.dart';
import '../widgets/qc_rejection_dialog.dart';
import '../widgets/rack_detail_modal.dart';
import '../widgets/result_entry_dialog.dart';
import '../../../shared/widgets/universal_qr_scanner_modal.dart';

/// Clinical Laboratory & Pathologist Station Portal
/// Features courier accessioning, visual analyzer racks, pre-analytical QC,
/// test parameter result entry, and pathologist electronic sign-off.
class LabHomeScreen extends StatelessWidget {
  const LabHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LabProvider(),
      child: const _LabHomeScreenScaffold(),
    );
  }
}

class _LabHomeScreenScaffold extends StatefulWidget {
  const _LabHomeScreenScaffold();

  @override
  State<_LabHomeScreenScaffold> createState() => _LabHomeScreenScaffoldState();
}

class _LabHomeScreenScaffoldState extends State<_LabHomeScreenScaffold> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _quickScanController = TextEditingController();
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quickScanController.dispose();
    super.dispose();
  }

  void _handleBackPress() {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
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

  void _handleQuickAccession() async {
    final barcode = _quickScanController.text.trim().toUpperCase();
    if (barcode.isEmpty) return;

    final success = await context.read<LabProvider>().accessionSpecimen(barcode: barcode);
    if (!mounted) return;

    if (success) {
      _quickScanController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vial $barcode checked in to Central Reference Lab.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final labProvider = context.watch<LabProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laboratory & Pathologist Portal', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Refresh Lab State',
            onPressed: () => context.read<LabProvider>().refresh(),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Credentials & Persona Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildHeaderCard(user),
              ),

              // KPI Metrics Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildKpiRow(labProvider),
              ),

              // Quick Accessioning Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildQuickAccessionBar(),
              ),
              const SizedBox(height: 12),

              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: const Color(0xFF7C3AED),
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: const Color(0xFF7C3AED),
                  indicatorWeight: 3,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
                  tabs: const [
                    Tab(text: 'Accession & Racks'),
                    Tab(text: 'Bench Testing & Results'),
                    Tab(text: 'Pathologist Sign-Off'),
                    Tab(text: 'QC & Analyzers'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: labProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAccessionTab(labProvider),
                          _buildTestingTab(labProvider),
                          _buildPathologistTab(labProvider),
                          _buildQcTab(labProvider),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ==========================================
  // Header Card
  // ==========================================
  Widget _buildHeaderCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.purpleIndigoGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.glowShadow(const Color(0xFF7C3AED), opacity: 0.3),
            ),
            child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user?.name ?? 'Dr. Sarah Chen',
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'NABL ACCREDITED',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Clinical Laboratory Specialist • Apex Central Reference Laboratory (NABL ISO 15189)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Switch Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED), width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KPI Metrics Row
  // ==========================================
  Widget _buildKpiRow(LabProvider provider) {
    final incoming = provider.incomingCouriers.length;
    final inLab = provider.accessionedSpecimens.length;
    final inTesting = provider.inAnalyzerSpecimens.length;
    final awaitingSign = provider.awaitingSignOffReports.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
        _buildKpiCard('Incoming Couriers', '$incoming', Icons.local_shipping_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
        const SizedBox(width: 10),
        _buildKpiCard('In Central Lab', '$inLab', Icons.inbox_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
        const SizedBox(width: 10),
        _buildKpiCard('In Analyzers', '$inTesting', Icons.science_rounded, const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
        const SizedBox(width: 10),
        _buildKpiCard('Awaiting Sign-Off', '$awaitingSign', Icons.draw_rounded, const Color(0xFF10B981), const Color(0xFFD1FAE5)),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, Color bg) {
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softCardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Quick Accession Bar
  // ==========================================
  Widget _buildQuickAccessionBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
        boxShadow: AppColors.glowShadow(const Color(0xFF7C3AED), opacity: 0.15),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Scan Barcode with Camera',
            child: InkWell(
              onTap: () async {
                final code = await UniversalQrScannerModal.show(
                  context,
                  title: 'Rapid Accession Scanner',
                  hint: 'Scan incoming vial barcode to accession into lab workflow',
                );
                if (code != null && code.isNotEmpty) {
                  _quickScanController.text = code;
                  _handleQuickAccession();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF7C3AED), size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _quickScanController,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Rapid Accession: Scan or Type Vial Barcode (e.g. SMP-90214)',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _handleQuickAccession(),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _handleQuickAccession,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shadowColor: const Color(0xFF7C3AED).withOpacity(0.35),
              elevation: 3,
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Accession Vial', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Tab 1: Accessioning & Racks
  // ==========================================
  Widget _buildAccessionTab(LabProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Active Analyzer Racks
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('ACTIVE ANALYZER SPECIMEN RACKS', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary)),
              ),
              const Spacer(),
              Text('${provider.racks.length} Racks Online', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width < 900 ? 1 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: MediaQuery.sizeOf(context).width < 900 ? 5.0 : 2.3,
            ),
            itemCount: provider.racks.length,
            itemBuilder: (context, index) {
              final rack = provider.racks[index];
              return _buildRackCard(rack);
            },
          ),
          const SizedBox(height: 24),

          // Section 2: Incoming Courier Batches
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('INCOMING COURIER TRANSIT BATCHES', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary)),
              ),
              const Spacer(),
              Text('${provider.incomingCouriers.length} Pending Intake', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.incomingCouriers.isEmpty)
            _buildEmptyState('No incoming courier vials pending check-in.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.incomingCouriers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = provider.incomingCouriers[index];
                return _buildCourierItemCard(s);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRackCard(LabRackModel rack) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => RackDetailModal(rack: rack),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(6)),
                    child: Text(rack.department, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
                  ),
                  const Spacer(),
                  Text(
                    '${rack.currentCount}/${rack.capacity} Vials',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const Spacer(),
              Text(rack.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(rack.analyzerName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rack.occupancyRate,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourierItemCard(SampleModel sample) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.science_outlined, color: Color(0xFF0284C7), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(sample.barcode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(6)),
                      child: Text(sample.status.displayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${sample.patientName} • ${sample.testNames.join(", ")}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Cap: ${sample.tubeType} • Temp: ${sample.temperatureC != null ? "${sample.temperatureC}°C" : "4.0°C"}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context.read<LabProvider>().accessionSpecimen(barcode: sample.barcode),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Check In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Tab 2: Bench Testing & Results
  // ==========================================
  Widget _buildTestingTab(LabProvider provider) {
    final activeList = provider.filteredSpecimens.where((s) => s.status == SampleStatus.receivedAtLab || s.status == SampleStatus.processing).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDepartmentFilterChip('All', provider),
                const SizedBox(width: 8),
                _buildDepartmentFilterChip('Hematology', provider),
                const SizedBox(width: 8),
                _buildDepartmentFilterChip('Biochemistry', provider),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (activeList.isEmpty)
            _buildEmptyState('No specimens currently waiting for analysis.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = activeList[index];
                return _buildTestingSpecimenCard(s);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentFilterChip(String dept, LabProvider provider) {
    final isSelected = provider.selectedDepartment == dept;
    return ChoiceChip(
      label: Text(dept),
      selected: isSelected,
      onSelected: (_) => provider.setDepartmentFilter(dept),
      selectedColor: const Color(0xFF7C3AED),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTestingSpecimenCard(SampleModel sample) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.biotech_rounded, color: Color(0xFF7C3AED), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(sample.barcode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sample.status == SampleStatus.processing ? AppColors.infoLight : AppColors.warningLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sample.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: sample.status == SampleStatus.processing ? AppColors.info : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${sample.patientName} (${sample.patientPhone})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DIAGNOSTIC TEST PANEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                  Text(sample.testNames.isNotEmpty ? sample.testNames.join(", ") : 'Diagnostic Assay', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TUBE TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                  Text(sample.tubeType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => QcRejectionDialog(sample: sample),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('QC Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ResultEntryDialog(sample: sample),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Enter Analyzer Findings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Tab 3: Pathologist Sign-Off
  // ==========================================
  Widget _buildPathologistTab(LabProvider provider) {
    final pendingReports = provider.awaitingSignOffReports;
    final verifiedReports = provider.verifiedReports;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.draw_rounded, size: 18, color: Color(0xFF15803D)),
              const SizedBox(width: 8),
              const Text('AWAITING CLINICAL AUTHORIZATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${pendingReports.length} Reports Ready for Review', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (pendingReports.isEmpty)
            _buildEmptyState('No reports currently awaiting Pathologist sign-off.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingReports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = pendingReports[index];
                return _buildPendingReportCard(report);
              },
            ),
          const SizedBox(height: 28),

          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              const Text('RECENTLY AUTHORIZED & RELEASED REPORTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${verifiedReports.length} Authorized', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: verifiedReports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = verifiedReports[index];
              return _buildVerifiedReportCard(r);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReportCard(ReportModel report) {
    final abnormalCount = report.testResults.where((p) => p.isAbnormal).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF15803D), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${report.patientName} • ${report.testName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Vial #${report.sampleBarcode} • Order #${report.orderId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (abnormalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(6)),
                  child: Text('$abnormalCount Abnormal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.error)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: report.testResults.map((p) {
              return Chip(
                padding: EdgeInsets.zero,
                backgroundColor: p.isAbnormal ? const Color(0xFFFEF2F2) : AppColors.background,
                label: Text('${p.name}: ${p.value} ${p.unit ?? ""}', style: TextStyle(fontSize: 11, fontWeight: p.isAbnormal ? FontWeight.w800 : FontWeight.w600, color: p.isAbnormal ? AppColors.error : AppColors.textPrimary)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => PathologistSignDialog(report: report),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.draw_rounded, size: 16),
              label: const Text('Review & Sign Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedReportCard(ReportModel report) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${report.patientName} • ${report.testName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Signed by: ${report.pathologistName ?? "Authorized Pathologist"}', style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
            child: const Text('READY & VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Tab 4: QC & Analyzers
  // ==========================================
  Widget _buildQcTab(LabProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Connected Analyzers Hardware Status
          Row(
            children: const [
              Icon(Icons.monitor_heart_rounded, size: 18, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('CONNECTED CLINICAL ANALYZERS HARDWARE STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: provider.analyzers.length,
            itemBuilder: (context, index) {
              final eq = provider.analyzers[index];
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
                      children: [
                        Expanded(
                          child: Text(
                            eq.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: Text(eq.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${eq.department} • Model: ${eq.modelNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Processed: ${eq.samplesProcessedToday} runs',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reagents: ${eq.reagentLevel}',
                            maxLines: 1,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Section 2: Pre-Analytical QC Rejections
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('PRE-ANALYTICAL QUALITY CONTROL REJECTION LOG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${provider.qcRejections.length} Rejections', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.qcRejections.isEmpty)
            _buildEmptyState('No pre-analytical specimen rejections recorded today.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.qcRejections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final qc = provider.qcRejections[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vial #${qc.sampleBarcode}: ${qc.rejectionReason}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.error)),
                            const SizedBox(height: 2),
                            Text('${qc.patientName} • ${qc.testName} • Flagged by: ${qc.technicianName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            if (qc.clinicalNotes != null)
                              Text('Notes: ${qc.clinicalNotes!}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                        child: const Text('RECOLLECTION ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
      ),
    );
  }
}
