import '../../../data/models/order_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/sample_event_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/services/central_data_store.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../domain/enums/user_role.dart';
import '../models/patient_booking_request.dart';

/// Patient Backend API Service
/// Connected to CentralDataStore to enable seamless cross-role data sync
/// (Patient bookings immediately visible to Phlebotomist, Front Desk, Lab, & Admin).
class PatientApiService {
  final CentralDataStore _store = CentralDataStore.instance;

  PatientApiService();

  /// POST /api/patient/bookings
  Future<OrderModel> submitBooking(PatientBookingRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay

    final now = DateTime.now();
    final orderId = 'ORD-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final sampleBarcode = 'SMP-${now.millisecondsSinceEpoch.toString().substring(8)}';

    final order = OrderModel(
      id: orderId,
      patientId: request.patientId,
      patientName: request.patientName,
      patientPhone: request.patientPhone,
      collectionAddress: request.address,
      testNames: request.selectedTestNames,
      totalAmount: request.totalAmount,
      scheduledDate: request.scheduledDate,
      timeSlot: request.timeSlot,
      branchId: 'branch-spoke-01',
      branchName: request.branchName.isNotEmpty ? request.branchName : 'Downtown Spoke Center #1',
      status: OrderStatus.confirmed,
      sampleBarcodes: [sampleBarcode],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      specialInstructions: request.notes,
      createdAt: now,
    );

    // Initial sample registered in chain of custody
    final sample = SampleModel(
      barcode: sampleBarcode,
      orderId: orderId,
      patientId: request.patientId,
      patientName: request.patientName,
      patientPhone: request.patientPhone,
      testNames: request.selectedTestNames,
      tubeType: 'EDTA Purple Top + SST Gold Top',
      status: SampleStatus.booked,
      currentBranchName: request.branchName.isNotEmpty ? request.branchName : 'Downtown Spoke Center #1',
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      createdAt: now,
      events: [
        SampleEventModel(
          id: 'EV-${now.millisecondsSinceEpoch}',
          sampleBarcode: sampleBarcode,
          status: SampleStatus.booked,
          timestamp: now,
          actorId: request.patientId,
          actorName: request.patientName,
          actorRole: UserRole.patient,
          locationName: request.address,
          notes: 'Home collection appointment booked online.',
        ),
      ],
    );

    _store.createOrder(order);
    _store.saveSample(sample);

    return order;
  }

  /// GET /api/patient/sample/:barcode
  Future<SampleModel?> trackSample(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final clean = barcode.trim().toLowerCase();
    try {
      return _store.samples.firstWhere((s) => s.barcode.toLowerCase() == clean);
    } catch (_) {
      return null;
    }
  }

  /// GET /api/patient/reports?patientId=...
  Future<List<ReportModel>> getPatientReports(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _store.reports.where((r) => r.patientId == patientId).toList();
  }

  /// Synchronous retrieval of initial reports for instant UI hydration
  List<ReportModel> getInitialReports(String patientId) {
    return _store.reports.where((r) => r.patientId == patientId).toList();
  }

  /// GET /api/patient/active-sample?patientId=...
  Future<SampleModel?> getActiveSample(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final samples = _store.samples.where((s) => s.patientId == patientId && s.status != SampleStatus.delivered).toList();
    if (samples.isNotEmpty) return samples.first;
    return null;
  }

  /// Synchronous retrieval of initial active sample for instant UI hydration
  SampleModel? getInitialSample(String patientId) {
    final samples = _store.samples.where((s) => s.patientId == patientId && s.status != SampleStatus.delivered).toList();
    if (samples.isNotEmpty) return samples.first;
    return null;
  }
}
