import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/shared.dart';
import '../providers/patient_provider.dart';

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
        title: const Text('My Diagnostic Reports'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Ready'),
                const SizedBox(width: 8),
                _buildFilterChip('Processing'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filteredReports.isEmpty
                ? const Center(child: Text('No reports match the selected filter.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredReports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: report.isReady ? () => _showReportDetails(report) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: report.isReady ? AppColors.successLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  report.isReady ? Icons.assignment_turned_in_rounded : Icons.hourglass_top_rounded,
                  color: report.isReady ? AppColors.success : AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.testName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.verificationDate != null
                          ? DateFormat('dd MMM yyyy').format(report.verificationDate!)
                          : 'Sample in testing',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.branchName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              if (report.isReady)
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('In Lab', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
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
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(report.testName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('Verified by: ${report.pathologistName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Clinical Parameters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: report.parameters.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final param = report.parameters[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(param.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('Normal: ${param.range}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(param.value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: param.isAbnormal ? AppColors.warningLight : AppColors.successLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  param.flag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: param.isAbnormal ? AppColors.warning : AppColors.success,
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading verified PDF report...')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download Signed PDF Report'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
