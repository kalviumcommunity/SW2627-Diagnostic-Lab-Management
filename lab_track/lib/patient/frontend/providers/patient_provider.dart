import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/report_model.dart';
import '../../backend/models/patient_booking_request.dart';
import '../../backend/repositories/patient_repository.dart';

/// Patient State Manager (acts like React Context / Redux Store in MERN frontend)
class PatientProvider extends ChangeNotifier {
  final PatientRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  SampleModel? _activeSample;
  List<OrderModel> _orders = [];
  List<ReportModel> _reports = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SampleModel? get activeSample => _activeSample;
  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<ReportModel> get reports => List.unmodifiable(_reports);

  PatientProvider({PatientRepository? repository})
      : _repository = repository ?? PatientRepository() {
    refreshPatientData('PT-84210');
  }

  Future<void> refreshPatientData(String patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final sample = await _repository.getActiveSample(patientId);
      final reportList = await _repository.getReports(patientId);
      _activeSample = sample;
      _reports = reportList;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new home collection booking
  Future<OrderModel?> createBooking(PatientBookingRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _repository.bookTest(request);
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
    return _repository.trackSample(barcode);
  }
}
