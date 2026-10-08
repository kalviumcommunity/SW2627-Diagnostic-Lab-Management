import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/report_model.dart';
import '../models/patient_booking_request.dart';
import '../services/patient_api_service.dart';

/// Patient Repository (acts like the controller/data-access layer in MERN)
class PatientRepository {
  final PatientApiService _apiService;

  PatientRepository({PatientApiService? apiService})
      : _apiService = apiService ?? PatientApiService();

  Future<OrderModel> bookTest(PatientBookingRequest request) =>
      _apiService.submitBooking(request);

  Future<SampleModel?> getActiveSample(String patientId) =>
      _apiService.getActiveSample(patientId);

  Future<SampleModel?> trackSample(String barcode) =>
      _apiService.trackSample(barcode);

  Future<List<ReportModel>> getReports(String patientId) =>
      _apiService.getPatientReports(patientId);

  SampleModel? getInitialSample(String patientId) =>
      _apiService.getInitialSample(patientId);

  List<ReportModel> getInitialReports(String patientId) =>
      _apiService.getInitialReports(patientId);
}

