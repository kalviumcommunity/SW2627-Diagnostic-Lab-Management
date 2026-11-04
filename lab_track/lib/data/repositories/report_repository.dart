import 'dart:typed_data';
import '../models/report_model.dart';
import '../models/sample_model.dart';
import '../models/user_model.dart';
import '../services/central_data_store.dart';
import '../services/storage_service.dart';
import '../../shared/services/pdf/pdf_report_generator.dart';

/// Repository managing medical report creation, signing, PDF generation, and persistence.
class ReportRepository {
  final CentralDataStore _store;
  final StorageService _storageService;

  ReportRepository({
    CentralDataStore? store,
    StorageService? storageService,
  })  : _store = store ?? CentralDataStore.instance,
        _storageService = storageService ?? StorageService();

  /// Retrieves all reports for a specific patient.
  Future<List<ReportModel>> getReportsByPatientId(String patientId) async {
    return _store.reports.where((r) => r.patientId == patientId).toList();
  }

  /// Retrieves a report by its associated specimen barcode.
  Future<ReportModel?> getReportByBarcode(String barcode) async {
    try {
      return _store.reports.firstWhere(
        (r) => r.sampleBarcode.toUpperCase() == barcode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Generates the standard PDF document for a report and caches/uploads it.
  Future<Uint8List> generateReportPdf({
    required ReportModel report,
    SampleModel? sample,
    UserModel? patient,
    String? clinicalNotes,
  }) async {
    final pdfBytes = PdfReportGenerator.generateDiagnosticReport(
      report: report,
      sample: sample,
      patient: patient,
      clinicalNotes: clinicalNotes,
    );

    // Asynchronously upload to storage
    _storageService.uploadReportPdf(reportId: report.id, pdfBytes: pdfBytes);

    return pdfBytes;
  }

  /// Authorizes and signs a report, releasing it to patient & front desk.
  Future<ReportModel> authorizeAndSignReport({
    required String reportId,
    required String pathologistName,
    String? clinicalInterpretation,
  }) async {
    final signed = _store.authorizeAndSignReport(
      reportId: reportId,
      pathologistName: pathologistName,
      clinicalInterpretation: clinicalInterpretation,
    );
    return signed;
  }
}
