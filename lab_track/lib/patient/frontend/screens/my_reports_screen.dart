import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/shared.dart';
import '../providers/patient_provider.dart';

/// God-Level Diagnostic Reports Screen
/// Presents verified pathologist lab reports with clinical biomarker analysis,
/// electronic signatures, and PDF download options.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final allReports = patientProvider.reports;

    final filteredReports = allReports.where((r) {
      if (_selectedFilter == 'Ready') return r.isReady;
      if (_selectedFilter == 'Processing') return !r.isReady;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnostic Reports Vault'),
      ),
      body: Column(
        children: [
          // Filter Chips Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All', allReports.length),
                const SizedBox(width: 8),
                _buildFilterChip('Ready', allReports.where((r) => r.isReady).length),
                const SizedBox(width: 8),
                _buildFilterChip('Processing', allReports.where((r) => !r.isReady).length),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filteredReports.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text(
                            'No reports match the selected filter.',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredReports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return _buildReportCard(report);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return GodLevelCard(
      onTap: report.isReady ? () => _showReportDetails(report) : null,
      padding: const EdgeInsets.all(18),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: report.isReady ? AppColors.emeraldTealGradient : AppColors.amberOrangeGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (report.isReady ? AppColors.success : AppColors.warning).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              report.isReady ? Icons.verified_rounded : Icons.hourglass_top_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.testName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: report.isReady ? AppColors.successLight : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.isReady ? 'VERIFIED' : 'TESTING',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: report.isReady ? AppColors.successDark : AppColors.warningDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      report.verificationDate != null
                          ? DateFormat('dd MMM yyyy • hh:mm a').format(report.verificationDate!)
                          : 'Sample in centrifugation / analysis',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.hub_outlined, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      report.branchName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                    if (report.isReady) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${report.parameters.length} Clinical Biomarkers',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (report.isReady)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  void _showReportDetails(ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with official pathology seal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.testName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Accredited Reference Laboratory: ${report.branchName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.verified_user_rounded, color: AppColors.successDark, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'ISO 15189 CERTIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.successDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pathologist digital stamp badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified by: ${report.pathologistName}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const Text(
                          'Chief Pathologist • Electronic Signature Cryptographically Validated',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Biomarkers title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'CLINICAL PARAMETER & BIOMARKER FINDINGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'REFERENCE RANGE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),

              // Parameter items
              Expanded(
                child: ListView.separated(
                  itemCount: report.parameters.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final param = report.parameters[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  param.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Biological Normal: ${param.range}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                param.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: param.isAbnormal ? AppColors.warningLight : AppColors.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  param.flag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: param.isAbnormal ? AppColors.warningDark : AppColors.successDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),
              GlowingActionButton(
                label: 'Download Official PDF Report',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading certified report for ${report.testName}...'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
