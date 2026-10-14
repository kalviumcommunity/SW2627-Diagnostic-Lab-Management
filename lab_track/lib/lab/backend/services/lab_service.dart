import '../../../data/models/report_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/services/central_data_store.dart';
import '../../../domain/enums/sample_status.dart';
import '../models/analyzer_equipment_model.dart';
import '../models/lab_rack_model.dart';
import '../models/qc_inspection_model.dart';

/// Clinical Laboratory Backend API Service
/// Connected to CentralDataStore for unified cross-role data sync.
class LabService {
  final CentralDataStore _store = CentralDataStore.instance;

  LabService();

  Future<List<SampleModel>> getSpecimens() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _store.samples;
  }

  Future<List<LabRackModel>> getRacks() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _store.racks;
  }

  Future<List<AnalyzerEquipmentModel>> getAnalyzers() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _store.analyzers;
  }

  Future<List<ReportModel>> getReports() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _store.reports;
  }

  Future<List<QcInspectionModel>> getQcRejections() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _store.qcRejections;
  }

  /// 1. Accession incoming courier specimen into central lab
  Future<SampleModel> accessionSpecimen({
    required String barcode,
    String? rackId,
    String? notes,
    String technicianName = 'Dr. Sarah Chen (#LAB-501)',
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _store.accessionSpecimen(
      barcode: barcode,
      rackId: rackId,
      notes: notes,
      technicianName: technicianName,
    );
    return _store.getSample(barcode)!;
  }

  /// 2. Assign accessioned specimen to an automated analyzer rack
  Future<void> assignToRack({
    required String barcode,
    required String rackId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _store.assignToRack(barcode: barcode, rackId: rackId);
  }

  /// 3. Flag pre-analytical quality failure (triggers recollection)
  Future<QcInspectionModel> recordQcRejection({
    required String barcode,
    required String rejectionReason,
    String? clinicalNotes,
    String technicianName = 'Dr. Sarah Chen (#LAB-501)',
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _store.recordQcRejection(
      barcode: barcode,
      rejectionReason: rejectionReason,
      clinicalNotes: clinicalNotes,
      technicianName: technicianName,
    );
  }

  /// 4. Save analytical test parameters entered by technician or analyzer
  Future<ReportModel> enterTestResults({
    required String sampleBarcode,
    required List<ReportParameter> parameters,
    String? testName,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _store.saveTestResults(
      sampleBarcode: sampleBarcode,
      parameters: parameters,
      testName: testName,
      notes: notes,
    );
  }

  /// 5. Pathologist Clinical Verification & Digital Signature Sign-Off
  Future<ReportModel> authorizeAndSignReport({
    required String reportId,
    required String pathologistName,
    String? clinicalInterpretation,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _store.authorizeAndSignReport(
      reportId: reportId,
      pathologistName: pathologistName,
      clinicalInterpretation: clinicalInterpretation,
    );
  }

  /// 6. Operational summary for top KPI widgets
  Future<Map<String, dynamic>> getOperationalSummary() async {
    await Future.delayed(const Duration(milliseconds: 60));

    final totalSpecimens = _store.samples.length;
    final inLabAccessioned = _store.samples.where((s) => s.status == SampleStatus.receivedAtLab).length;
    final inTestingRacks = _store.samples.where((s) => s.status == SampleStatus.processing).length;
    final pendingSignOff = _store.reports.where((r) => !r.isReady).length;
    final completedReports = _store.reports.where((r) => r.isReady).length;
    final qcRejections = _store.qcRejections.length;

    return {
      'totalSpecimens': totalSpecimens,
      'inLabAccessioned': inLabAccessioned,
      'inTestingRacks': inTestingRacks,
      'pendingSignOff': pendingSignOff,
      'completedReports': completedReports,
      'qcRejections': qcRejections,
      'activeRacksCount': _store.racks.where((r) => r.status != 'completed').length,
    };
  }
}
