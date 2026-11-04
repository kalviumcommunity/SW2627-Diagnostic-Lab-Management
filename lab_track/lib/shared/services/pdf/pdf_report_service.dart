import 'package:flutter/material.dart';
import '../../../../data/models/report_model.dart';
import '../../../../data/models/sample_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/theme/app_colors.dart';
import 'pdf_downloader.dart';
import 'pdf_report_generator.dart';

/// Clinical Report PDF Generation & Delivery Service.
/// Handles generating valid ISO-standard PDF documents, saving to file system
/// on Mobile/Desktop, or downloading via browser Blob on Web.
class PdfReportService {
  /// Generates the standard PDF bytes for a diagnostic report.
  static List<int> generateReportBytes({
    required ReportModel report,
    SampleModel? sample,
    UserModel? patient,
    String? clinicalNotes,
  }) {
    return PdfReportGenerator.generateDiagnosticReport(
      report: report,
      sample: sample,
      patient: patient,
      clinicalNotes: clinicalNotes,
    );
  }

  /// Generates and triggers download/save of the official PDF report.
  /// Shows a success SnackBar with the resulting file information.
  static Future<String?> downloadOfficialPdf({
    required BuildContext context,
    required ReportModel report,
    SampleModel? sample,
    UserModel? patient,
    String? clinicalNotes,
  }) async {
    try {
      final barcode = report.sampleBarcode.isNotEmpty
          ? report.sampleBarcode
          : (sample?.barcode ?? 'SMP-90214');
      final suffix =
          '${barcode}_${report.id}'.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final fileName = 'LabTrack_Report_$suffix.pdf';

      final pdfBytes = generateReportBytes(
        report: report,
        sample: sample,
        patient: patient,
        clinicalNotes: clinicalNotes,
      );

      final result = await downloadPdfBytes(pdfBytes, fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official PDF Generated: $fileName',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Text(
                        result != null && result.isNotEmpty
                            ? result
                            : 'Downloaded to device storage',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      return result;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }
}
