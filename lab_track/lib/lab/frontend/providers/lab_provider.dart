import 'package:flutter/foundation.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../domain/enums/sample_status.dart';
import '../../backend/models/analyzer_equipment_model.dart';
import '../../backend/models/lab_rack_model.dart';
import '../../backend/models/qc_inspection_model.dart';
import '../../backend/services/lab_service.dart';
import '../../../data/services/central_data_store.dart';

/// State Management Provider for the Laboratory Technician & Pathologist Portal.
class LabProvider extends ChangeNotifier {
  final LabService _labService;

  List<SampleModel> _samples = [];
  List<ReportModel> _reports = [];
  List<LabRackModel> _racks = [];
  List<AnalyzerEquipmentModel> _analyzers = [];
  List<QcInspectionModel> _qcRejections = [];
  Map<String, dynamic> _summary = {};

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedDepartment = 'All';

  LabProvider({LabService? labService}) : _labService = labService ?? LabService() {
    loadAllData();
    CentralDataStore.instance.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    loadAllData();
  }

  @override
  void dispose() {
    CentralDataStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  Map<String, dynamic> get summary => _summary;

  List<LabRackModel> get racks => _racks;
  List<AnalyzerEquipmentModel> get analyzers => _analyzers;
  List<QcInspectionModel> get qcRejections => _qcRejections;

  /// Filtered specimens based on search and active department
  List<SampleModel> get filteredSpecimens {
    return _samples.where((s) {
      // 1. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchBarcode = s.barcode.toLowerCase().contains(q);
        final matchPatient = s.patientName.toLowerCase().contains(q);
        final matchOrder = s.orderId.toLowerCase().contains(q);
        final matchTest = s.testNames.any((t) => t.toLowerCase().contains(q));
        if (!matchBarcode && !matchPatient && !matchOrder && !matchTest) {
          return false;
        }
      }

      // 2. Department filter
      if (_selectedDepartment != 'All') {
        if (_selectedDepartment == 'Hematology') {
          return s.tubeType.toLowerCase().contains('edta') ||
              s.tubeType.toLowerCase().contains('purple') ||
              s.testNames.any((t) => t.toLowerCase().contains('blood') || t.toLowerCase().contains('cbc'));
        } else if (_selectedDepartment == 'Biochemistry') {
          return s.tubeType.toLowerCase().contains('sst') ||
              s.tubeType.toLowerCase().contains('gold') ||
              s.testNames.any((t) => t.toLowerCase().contains('metabolic') || t.toLowerCase().contains('lipid'));
        } else if (_selectedDepartment == 'QC Rejections') {
          return s.status == SampleStatus.rejected;
        }
      }

      return true;
    }).toList();
  }

  List<SampleModel> get incomingCouriers =>
      _samples.where((s) => s.status == SampleStatus.inTransitToCentralLab || s.status == SampleStatus.receivedAtBranch).toList();

  List<SampleModel> get accessionedSpecimens =>
      _samples.where((s) => s.status == SampleStatus.receivedAtLab).toList();

  List<SampleModel> get inAnalyzerSpecimens =>
      _samples.where((s) => s.status == SampleStatus.processing).toList();

  List<ReportModel> get awaitingSignOffReports =>
      _reports.where((r) => !r.isReady).toList();

  List<ReportModel> get verifiedReports =>
      _reports.where((r) => r.isReady).toList();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDepartmentFilter(String dept) {
    _selectedDepartment = dept;
    notifyListeners();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _labService.getSpecimens(),
        _labService.getReports(),
        _labService.getRacks(),
        _labService.getAnalyzers(),
        _labService.getQcRejections(),
        _labService.getOperationalSummary(),
      ]);

      _samples = results[0] as List<SampleModel>;
      _reports = results[1] as List<ReportModel>;
      _racks = results[2] as List<LabRackModel>;
      _analyzers = results[3] as List<AnalyzerEquipmentModel>;
      _qcRejections = results[4] as List<QcInspectionModel>;
      _summary = results[5] as Map<String, dynamic>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> refresh() => loadAllData();

  /// Accession incoming courier vial into Central Lab
  Future<bool> accessionSpecimen({
    required String barcode,
    String? rackId,
    String? notes,
  }) async {
    try {
      await _labService.accessionSpecimen(barcode: barcode, rackId: rackId, notes: notes);
      await loadAllData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Assign accessioned specimen to an automated analyzer rack
  Future<bool> assignToRack({
    required String barcode,
    required String rackId,
  }) async {
    try {
      await _labService.assignToRack(barcode: barcode, rackId: rackId);
      await loadAllData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Record pre-analytical QC specimen rejection
  Future<bool> recordQcRejection({
    required String barcode,
    required String reason,
    String? clinicalNotes,
  }) async {
    try {
      await _labService.recordQcRejection(
        barcode: barcode,
        rejectionReason: reason,
        clinicalNotes: clinicalNotes,
      );
      await loadAllData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Save parameter values for a diagnostic test
  Future<bool> enterTestResults({
    required String sampleBarcode,
    required List<ReportParameter> parameters,
    String? testName,
    String? notes,
  }) async {
    try {
      await _labService.enterTestResults(
        sampleBarcode: sampleBarcode,
        parameters: parameters,
        testName: testName,
        notes: notes,
      );
      await loadAllData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Pathologist electronic verification and digital sign-off
  Future<bool> authorizeAndSignReport({
    required String reportId,
    required String pathologistName,
    String? clinicalInterpretation,
  }) async {
    try {
      await _labService.authorizeAndSignReport(
        reportId: reportId,
        pathologistName: pathologistName,
        clinicalInterpretation: clinicalInterpretation,
      );
      await loadAllData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
