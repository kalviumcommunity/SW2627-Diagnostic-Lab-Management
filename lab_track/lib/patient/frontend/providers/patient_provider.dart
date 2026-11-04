import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/central_data_store.dart';
import '../../backend/models/patient_booking_request.dart';
import '../../backend/repositories/patient_repository.dart';

/// Patient State Manager
/// Auto-syncs live updates from Phlebotomist, Front Desk, Lab, and Pathologist.
class PatientProvider extends ChangeNotifier {
  final PatientRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  SampleModel? _activeSample;
  final List<OrderModel> _orders = [];
  List<ReportModel> _reports = [];
  String? _patientId;
  int _refreshGeneration = 0;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SampleModel? get activeSample => _activeSample;
  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<ReportModel> get reports => List.unmodifiable(_reports);

  PatientProvider({PatientRepository? repository})
      : _repository = repository ?? PatientRepository() {
    _patientId = 'PT-VIRENDER';
    _orders.addAll(_repository.getInitialOrders('PT-VIRENDER'));
    _activeSample = _repository.getInitialSample('PT-VIRENDER');
    _reports = _repository.getInitialReports('PT-VIRENDER');
    CentralDataStore.instance.addListener(_onStoreChanged);
  }

  void setPatient(String? patientId) {
    final effectiveId = (patientId != null && patientId.isNotEmpty) ? patientId : 'PT-VIRENDER';
    if (_patientId == effectiveId && _orders.isNotEmpty) return;
    _patientId = effectiveId;
    _refreshGeneration++;
    _activeSample = null;
    _reports = [];
    _orders.clear();
    _orders.addAll(_repository.getInitialOrders(effectiveId));
    _activeSample = _repository.getInitialSample(effectiveId);
    _reports = _repository.getInitialReports(effectiveId);
    refreshPatientData(effectiveId);
  }

  void _onStoreChanged() {
    final patientId = _patientId ?? 'PT-VIRENDER';
    _activeSample = _repository.getInitialSample(patientId);
    _reports = _repository.getInitialReports(patientId);
    final updatedOrders = _repository.getInitialOrders(patientId);
    _orders.clear();
    _orders.addAll(updatedOrders);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshGeneration++;
    CentralDataStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  Future<void> refreshPatientData(String patientId) async {
    final generation = ++_refreshGeneration;
    _isLoading = true;
    notifyListeners();

    try {
      final sample = await _repository.getActiveSample(patientId);
      final reportList = await _repository.getReports(patientId);
      final orderList = await _repository.getOrders(patientId);
      if (_disposed || generation != _refreshGeneration || patientId != _patientId) return;
      _activeSample = sample;
      _reports = reportList;
      _orders.clear();
      _orders.addAll(orderList);
      _errorMessage = null;
    } catch (e) {
      if (_disposed || generation != _refreshGeneration) return;
      _errorMessage = e.toString();
    } finally {
      if (!_disposed && generation == _refreshGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Create a new home collection booking
  Future<OrderModel?> createBooking(PatientBookingRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _repository.bookTest(request);
      _orders.removeWhere((o) => o.id == order.id);
      _orders.insert(0, order);
      await refreshPatientData(request.patientId);
      return order;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Track any sample by barcode in real time
  Future<SampleModel?> trackSample(String barcode) async {
    final sample = await _repository.trackSample(barcode);
    return sample?.patientId == _patientId ? sample : null;
  }
}
