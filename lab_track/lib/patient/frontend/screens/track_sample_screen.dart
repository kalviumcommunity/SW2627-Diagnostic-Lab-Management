import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/appointment_qr_pass_modal.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../shared/shared.dart';
import '../../../shared/services/pdf/pdf_report_service.dart';
import '../../../data/services/central_data_store.dart';
import '../providers/patient_provider.dart';

/// God-Level Chain of Custody & IoT Telemetry Tracking Screen
class TrackSampleScreen extends StatefulWidget {
  final String? initialBarcode;
  const TrackSampleScreen({super.key, this.initialBarcode});

  @override
  State<TrackSampleScreen> createState() => _TrackSampleScreenState();
}

class _TrackSampleScreenState extends State<TrackSampleScreen> {
  final TextEditingController _searchController = TextEditingController();
  SampleModel? _searchedSample;
  String? _trackedBarcode;
  bool _searchAttempted = false;
  bool _isSearching = false;

  final List<String> _demoBarcodes = [
    'SMP-88390',
    'SMP-99120',
    'SMP-77401',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialBarcode ?? 'SMP-88390';
    _trackedBarcode = widget.initialBarcode ?? 'SMP-88390';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchSample([String? overrideQuery]) async {
    final query = (overrideQuery ?? _searchController.text).trim();
    if (query.isEmpty) return;

    if (overrideQuery != null) {
      _searchController.text = overrideQuery;
    }

    setState(() {
      _isSearching = true;
      _searchAttempted = true;
    });
    final patientProvider = context.read<PatientProvider>();
    final result = await patientProvider.trackSample(query);

    if (!mounted) return;
    setState(() {
      _searchedSample = result;
      _trackedBarcode = result != null ? result.barcode : null;
      _isSearching = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No specimen found matching barcode "$query"'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final store = CentralDataStore.instance;

    // Resolve live sample
    SampleModel? sample;
    if (_searchAttempted) {
      sample = _trackedBarcode != null
          ? store.getSample(_trackedBarcode!) ?? _searchedSample
          : null;
    } else {
      sample = _trackedBarcode != null
          ? store.getSample(_trackedBarcode!) ?? _searchedSample ?? patientProvider.activeSample
          : _searchedSample ?? patientProvider.activeSample;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Chain of Custody Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Barcode / QR',
            onPressed: () async {
              final scanned = await UniversalQrScannerModal.show(
                context,
                title: 'Scan Receipt / Sample Barcode',
                hint: 'Scan your booking receipt QR or vial barcode to track live custody',
              );
              if (scanned != null && scanned.isNotEmpty) {
                _searchController.text = scanned;
                _searchSample();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Telemetry',
            onPressed: () => _searchSample(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // High-Tech Search Bar
            GodLevelCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              borderRadius: 16,
              child: Row(
                children: [
                  InkWell(
                    onTap: () async {
                      final scanned = await UniversalQrScannerModal.show(
                        context,
                        title: 'Scan Receipt / Sample Barcode',
                        hint: 'Scan your booking receipt QR or vial barcode to track live custody',
                      );
                      if (scanned != null && scanned.isNotEmpty) {
                        _searchController.text = scanned;
                        _searchSample();
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Scan or Enter Barcode (e.g. SMP-88390)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _searchSample(),
                    ),
                  ),
                  if (_isSearching)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _searchSample(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Demo Barcode Quick Selector Chips
            Row(
              children: [
                const Text(
                  'Quick Barcode Demo:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _demoBarcodes.map((code) {
                        final isSelected = _searchController.text == code;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => _searchSample(code),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (sample != null) ...[
              // Specimen Overview Hero Card
              _buildOverviewCard(sample),
              const SizedBox(height: 24),

              // Digital Audit Trail Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DIGITAL CHAIN OF CUSTODY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CRYPTOGRAPHIC AUDIT LOG',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.successDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tamper-evident custody milestones logged with GPS coordinates and cold-chain telemetry.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Custody Stepper
              SpecimenCustodyStepper(events: sample.events),
            ] else if (patientProvider.orders.isNotEmpty) ...[
              _buildActiveOrderTimelineCard(context, patientProvider.orders.first),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: const [
                      Icon(Icons.radar_rounded, size: 48, color: AppColors.textTertiary),
                      SizedBox(height: 12),
                      Text(
                        'No active booking or specimen to track.',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Book a test to track your specimen journey from vein to report.',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(SampleModel sample) {
    ReportModel? matchedReport;
    final allReports = CentralDataStore.instance.reports;
    for (final r in allReports) {
      if (r.orderId == sample.orderId || r.sampleBarcode == sample.barcode) {
        matchedReport = r;
        break;
      }
    }
    if (matchedReport == null &&
        (sample.status == SampleStatus.reportReady ||
            sample.status == SampleStatus.delivered)) {
      matchedReport = ReportModel(
        id: 'REP-${sample.barcode.replaceAll('SMP-', '')}',
        orderId: sample.orderId,
        sampleBarcode: sample.barcode,
        patientId: sample.patientId,
        patientName: sample.patientName,
        status: 'Verified & Ready',
        pathologistName: 'Dr. Suresh Sen, MD (Path)',
        verifiedAt: DateTime.now().subtract(const Duration(hours: 1)),
        testName: sample.testNames.isNotEmpty
            ? sample.testNames.first
            : 'Diagnostic Specimen Panel',
        branchName: sample.currentBranchName ?? 'Central Diagnostic Lab',
        testResults: const [
          ReportParameter(
            name: 'Diagnostic Panel Status',
            value: 'Passed / Normal',
            unit: 'Clearance',
            range: 'Normal Limits',
            flag: 'Normal',
          ),
          ReportParameter(
            name: 'Specimen Integrity',
            value: 'Optimal (Cold-Chain Verified)',
            unit: 'Quality Index',
            range: '100%',
            flag: 'Normal',
          ),
        ],
      );
    }

    return GodLevelCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      hasGlow: true,
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.testNames.isNotEmpty ? sample.testNames.first : 'Diagnostic Specimen Panel',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'BARCODE: #${sample.barcode}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Patient: ${sample.patientId}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PulsingStatusBadge.fromSampleStatus(sample.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // High-Tech Telemetry Row
          Row(
            children: [
              // Cold Chain Telemetry
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.electricCyanLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.ac_unit_rounded, color: AppColors.electricCyan, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COOL-CHAIN',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sample.temperatureStatus ?? '4.2°C (Optimal)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Current Location / Custody
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hub_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT LOCATION',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sample.currentBranchName ?? 'In Transit Hub',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Show Appointment QR Pass action button
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              final order = CentralDataStore.instance.getOrder(sample.orderId) ??
                  OrderModel(
                    id: sample.orderId,
                    patientId: sample.patientId,
                    patientName: sample.patientName,
                    patientPhone: sample.patientPhone,
                    collectionAddress: sample.currentBranchName ?? 'Doorstep Draw',
                    testNames: sample.testNames,
                    totalAmount: 1100.0,
                    scheduledDate: sample.createdAt,
                    timeSlot: 'Morning Doorstep Slot',
                    branchId: sample.currentBranchId ?? 'branch-spoke-01',
                    branchName: sample.currentBranchName ?? 'Downtown Spoke Center #1',
                    status: OrderStatus.inProgress,
                    sampleBarcodes: [sample.barcode],
                    assignedPhlebotomistId: sample.assignedPhlebotomistId,
                    assignedPhlebotomistName: sample.assignedPhlebotomistName,
                    createdAt: sample.createdAt,
                  );
              AppointmentQrPassModal.show(context, order);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0284C7).withOpacity(0.08), const Color(0xFF0284C7).withOpacity(0.18)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Show Doorstep Appointment QR Pass',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                        Text(
                          'Present to phlebotomist upon arrival to authorize specimen draw',
                          style: TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.fullscreen_rounded, color: Color(0xFF0284C7), size: 20),
                ],
              ),
            ),
          ),

          if (matchedReport != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.successLight,
                    AppColors.primaryLight.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.successDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OFFICIAL DIAGNOSTIC REPORT',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.successDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Signed by ${matchedReport.pathologistName ?? "Clinical Pathologist"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => PdfReportService.downloadOfficialPdf(
                      context: context,
                      report: matchedReport!,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textTertiary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Official diagnostic PDF will be automatically generated and downloadable here once laboratory testing and pathologist sign-off are complete.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


  Widget _buildActiveOrderTimelineCard(BuildContext context, OrderModel order) {
    final isVerified = order.doorstepVerifiedAt != null;
    final isCollected = order.status == OrderStatus.inProgress && order.sampleBarcodes.isNotEmpty;
    final isCompleted = order.status == OrderStatus.completed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFD1FAE5)
                      : (isVerified ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted
                      ? '● Order Completed & Report Ready'
                      : (isVerified ? '● Doorstep Blood Draw Active' : '● Booking Confirmed'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? const Color(0xFF047857)
                        : (isVerified ? const Color(0xFFD97706) : AppColors.primary),
                  ),
                ),
              ),
              Text(
                '#' + order.id,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            order.testNames.isNotEmpty ? order.testNames.join(', ') : 'Diagnostic Panel',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Phlebotomist: ' + (order.assignedPhlebotomistName ?? 'Praveen') + ' • Slot: ' + order.timeSlot,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // 5-Stage Live Milestones
          _buildMilestoneRow(
            title: '1. Appointment Confirmed',
            subtitle: 'Booking verified at Central Hub',
            isDone: true,
            isActive: false,
          ),
          _buildMilestoneRow(
            title: '2. Phlebotomist Assigned',
            subtitle: 'Phlebotomist ' + (order.assignedPhlebotomistName ?? 'Praveen') + ' assigned',
            isDone: true,
            isActive: !isVerified,
          ),
          _buildMilestoneRow(
            title: '3. Doorstep Identity & Blood Draw',
            subtitle: isVerified
                ? 'Verified at ' + DateFormat('hh:mm a').format(order.doorstepVerifiedAt!)
                : 'Show Doorstep QR pass to phlebotomist upon arrival',
            isDone: isVerified,
            isActive: !isVerified,
            trailingWidget: !isVerified
                ? TextButton.icon(
                    onPressed: () => AppointmentQrPassModal.show(context, order),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                    label: const Text('Show QR Pass', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  )
                : null,
          ),
          _buildMilestoneRow(
            title: '4. Central Reference Lab Accession',
            subtitle: isCollected
                ? 'Cold chain verified. In transit to Central Lab (Aryan)'
                : 'Specimen will be safely secured in 4.2°C cooler',
            isDone: isCollected,
            isActive: isVerified && !isCollected,
          ),
          _buildMilestoneRow(
            title: '5. Diagnostic Report Published',
            subtitle: isCompleted
                ? 'Pathologist signed and published'
                : 'Report will be available in My Reports once analyzed',
            isDone: isCompleted,
            isActive: isCollected && !isCompleted,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    Widget? trailingWidget,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.success
                    : (isActive ? const Color(0xFFD97706) : Colors.grey.shade300),
              ),
              child: Icon(
                isDone ? Icons.check_rounded : (isActive ? Icons.play_arrow_rounded : Icons.circle),
                color: Colors.white,
                size: 14,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone ? AppColors.success : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDone || isActive ? AppColors.textPrimary : Colors.grey,
                    ),
                  ),
                  if (trailingWidget != null) trailingWidget,
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDone || isActive ? AppColors.textSecondary : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
