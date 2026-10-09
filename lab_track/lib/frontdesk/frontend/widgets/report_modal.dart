import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/report_model.dart';
import '../../../shared/theme/app_colors.dart';

class ReportModal extends StatelessWidget {
  final ReportModel report;
  final String? patientName;
  final String? patientPhone;

  const ReportModal({
    super.key,
    required this.report,
    this.patientName,
    this.patientPhone,
  });

  static void show(
    BuildContext context, {
    required ReportModel report,
    String? patientName,
    String? patientPhone,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportModal(
        report: report,
        patientName: patientName,
        patientPhone: patientPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
        maxWidth: 680,
      ),
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.success,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verified Diagnostic Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Report #${report.id} • Barcode: ${report.sampleBarcode}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lab Details Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              report.testName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                report.status,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              report.branchName,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              report.verificationDate != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(report.verificationDate!)
                                  : 'Today',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if (patientName != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Patient: $patientName ${patientPhone != null ? "($patientPhone)" : ""}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Clinical Parameters Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CLINICAL PARAMETERS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${report.parameters.length} Analyzed',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Table of Parameters
                  if (report.parameters.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Text('No parameters recorded yet for this panel.'),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // Header row
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                            ),
                            child: Row(
                              children: const [
                                Expanded(flex: 4, child: Text('Test Parameter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                Expanded(flex: 3, child: Text('Result', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                Expanded(flex: 3, child: Text('Bio Reference', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                SizedBox(width: 70, child: Text('Status', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Data rows
                          ...report.parameters.map((param) {
                            final isAbnormal = param.isAbnormal;
                            final flag = param.flag.toLowerCase();
                            Color flagBg = AppColors.successLight;
                            Color flagText = AppColors.success;

                            if (flag.contains('high') || flag.contains('critical')) {
                              flagBg = AppColors.errorLight;
                              flagText = AppColors.error;
                            } else if (flag.contains('low') || flag.contains('borderline')) {
                              flagBg = AppColors.warningLight;
                              flagText = AppColors.warning;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.divider)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          param.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        if (param.unit != null)
                                          Text(
                                            'Unit: ${param.unit}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${param.value} ${param.unit ?? ""}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: isAbnormal ? flagText : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      param.range,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: flagBg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          param.flag,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: flagText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Pathologist Signoff Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFDCFCE7),
                          child: Icon(Icons.draw_rounded, color: AppColors.success, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.pathologistName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              const Text(
                                'Electronically Verified & Signed • Valid Digital Clinical Record',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thermal summary slip sent to desk printer!'),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Print Slip'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Downloading official PDF diagnostic report...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Print Full PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
}
