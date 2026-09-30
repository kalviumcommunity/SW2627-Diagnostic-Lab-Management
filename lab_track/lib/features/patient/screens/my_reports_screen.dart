import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'REP-91204',
      'testName': 'Complete Blood Count (CBC)',
      'date': '28 Sep 2026',
      'branch': 'Central Diagnostic Lab - Sector 5',
      'pathologist': 'Dr. Arvind Mehta (MD Path)',
      'isReady': true,
      'status': 'Verified & Ready',
      'parameters': [
        {'name': 'Hemoglobin', 'value': '14.2 g/dL', 'range': '13.0 - 17.0', 'flag': 'Normal'},
        {'name': 'Total Leukocyte Count (WBC)', 'value': '7,200 /uL', 'range': '4,000 - 11,000', 'flag': 'Normal'},
        {'name': 'Platelet Count', 'value': '245,000 /uL', 'range': '150,000 - 450,000', 'flag': 'Normal'},
        {'name': 'Packed Cell Volume (PCV)', 'value': '42.5 %', 'range': '40.0 - 50.0', 'flag': 'Normal'},
      ],
    },
    {
      'id': 'REP-89410',
      'testName': 'Lipid Profile & Glucose Fasting',
      'date': '15 Sep 2026',
      'branch': 'Apollo Hub Diagnostic Center',
      'pathologist': 'Dr. Sunita Sen (Senior Pathologist)',
      'isReady': true,
      'status': 'Verified & Ready',
      'parameters': [
        {'name': 'Fasting Blood Sugar', 'value': '94 mg/dL', 'range': '70 - 100', 'flag': 'Normal'},
        {'name': 'Total Cholesterol', 'value': '182 mg/dL', 'range': '< 200', 'flag': 'Normal'},
        {'name': 'Triglycerides', 'value': '145 mg/dL', 'range': '< 150', 'flag': 'Normal'},
        {'name': 'HDL (Good Cholesterol)', 'value': '48 mg/dL', 'range': '> 40', 'flag': 'Normal'},
        {'name': 'LDL (Bad Cholesterol)', 'value': '105 mg/dL', 'range': '< 100', 'flag': 'Borderline High'},
      ],
    },
    {
      'id': 'REP-98311',
      'testName': 'Thyroid Panel (T3, T4, TSH) & HbA1c',
      'date': '30 Sep 2026 (Today)',
      'branch': 'Central Diagnostic Lab - Sector 5',
      'pathologist': 'Pending Laboratory Analysis',
      'isReady': false,
      'status': 'Processing in Lab',
      'parameters': [],
    },
  ];

  List<Map<String, dynamic>> get _filteredReports {
    if (_selectedFilter == 'Ready') {
      return _reports.where((r) => r['isReady'] == true).toList();
    } else if (_selectedFilter == 'Processing') {
      return _reports.where((r) => r['isReady'] == false).toList();
    }
    return _reports;
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final parameters = report['parameters'] as List<dynamic>;
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
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['testName'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Report ID: #${report['id']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Verified By: ${report['pathologist']}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              const Text(
                'Clinical Test Parameters',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.separated(
                  itemCount: parameters.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final param = parameters[index] as Map<String, dynamic>;
                    final isBorderline = param['flag'] != 'Normal';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  param['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  'Ref: ${param['range']}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              param['value'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isBorderline ? AppColors.warning : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isBorderline ? AppColors.warningLight : AppColors.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              param['flag'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isBorderline ? AppColors.warning : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading official PDF for ${report['id']}...')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Official PDF Report'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Diagnostic Reports'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Ready', 'Processing'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Reports List
          Expanded(
            child: _filteredReports.isEmpty
                ? const Center(
                    child: Text('No reports found', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      final isReady = report['isReady'] as bool;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${report['id']}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isReady ? AppColors.successLight : AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      report['status'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isReady ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report['testName'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${report['date']} • ${report['branch']}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),

                              if (isReady)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showReportDetails(report),
                                        icon: const Icon(Icons.visibility_outlined, size: 16),
                                        label: const Text('View Results'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Downloading ${report['id']} PDF...')),
                                          );
                                        },
                                        icon: const Icon(Icons.download_rounded, size: 16),
                                        label: const Text('Download PDF'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: const [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Lab analysis in progress. Verified report will be ready by 06:00 PM.',
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
