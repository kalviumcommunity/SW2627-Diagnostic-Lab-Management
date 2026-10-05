import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/sample_event_model.dart';
import '../../../data/models/report_model.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../domain/enums/user_role.dart';
import '../models/patient_booking_request.dart';

/// Patient Backend API Service (acts like Express router/controller in MERN stack)
/// Exposes patient-specific data operations with Firestore & fallback mock stores.
class PatientApiService {
  // In-memory persistent state across session
  static final List<OrderModel> _orderStore = [];
  static final List<SampleModel> _sampleStore = [];
  static final List<ReportModel> _reportStore = [];

  static bool _initialized = false;

  PatientApiService() {
    _ensureInitialized();
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();

    // Default sample in transit
    final sample = SampleModel(
      barcode: 'SMP-88390',
      orderId: 'ORD-84210',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      testNames: ['Thyroid & HbA1c Panel'],
      vialType: 'EDTA (Purple Top) + SST (Yellow Top)',
      status: SampleStatus.inTransit,
      currentBranchId: 'BR-004',
      currentBranchName: 'Branch Hub 4 - Courier Bag #12',
      assignedPhlebotomistId: 'PH-102',
      assignedPhlebotomistName: 'Rajeev Kumar',
      collectionTime: now.subtract(const Duration(hours: 3)),
      temperatureStatus: '4.2°C (Cool Chain Intact)',
      notes: 'Phlebotomist transferred vial to Branch Hub 4. Expected testing at 5:00 PM.',
      events: [
        SampleEventModel(
          id: 'EV-01',
          sampleBarcode: 'SMP-88390',
          status: SampleStatus.collected,
          timestamp: now.subtract(const Duration(hours: 3)),
          actorId: 'PH-102',
          actorName: 'Rajeev Kumar (Phlebotomist)',
          actorRole: UserRole.phlebotomist,
          locationName: 'Patient Home (Sector 14)',
          temperatureCelsius: 4.0,
          notes: 'Home collection completed. Sterile barcodes affixed.',
        ),
        SampleEventModel(
          id: 'EV-02',
          sampleBarcode: 'SMP-88390',
          status: SampleStatus.inTransit,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
          actorId: 'PH-102',
          actorName: 'Rajeev Kumar',
          actorRole: UserRole.phlebotomist,
          locationName: 'Transit to Hub 4',
          temperatureCelsius: 4.2,
          notes: 'Cold gel box temperature monitored.',
        ),
        SampleEventModel(
          id: 'EV-03',
          sampleBarcode: 'SMP-88390',
          status: SampleStatus.receivedAtBranch,
          timestamp: now.subtract(const Duration(minutes: 40)),
          actorId: 'FD-204',
          actorName: 'Priya Sharma (Intake Desk)',
          actorRole: UserRole.frontDesk,
          locationName: 'Branch Hub 4 Receiving Rack',
          temperatureCelsius: 4.1,
          notes: 'Barcode verified at intake desk without error.',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 6)),
    );

    _sampleStore.add(sample);

    // Initial reports
    _reportStore.addAll([
      ReportModel(
        id: 'REP-91204',
        orderId: 'ORD-81002',
        patientId: 'PT-84210',
        sampleBarcode: 'SMP-77219',
        testName: 'Complete Blood Count (CBC)',
        branchName: 'Central Diagnostic Lab - Sector 5',
        pathologistName: 'Dr. Arvind Mehta (MD Path)',
        verificationDate: now.subtract(const Duration(days: 7)),
        isReady: true,
        status: 'Verified & Ready',
        parameters: const [
          ReportParameter(name: 'Hemoglobin', value: '14.2 g/dL', range: '13.0 - 17.0', flag: 'Normal'),
          ReportParameter(name: 'Total Leukocyte Count (WBC)', value: '7,200 /uL', range: '4,000 - 11,000', flag: 'Normal'),
          ReportParameter(name: 'Platelet Count', value: '245,000 /uL', range: '150,000 - 450,000', flag: 'Normal'),
          ReportParameter(name: 'Packed Cell Volume (PCV)', value: '42.5 %', range: '40.0 - 50.0', flag: 'Normal'),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      ReportModel(
        id: 'REP-89410',
        orderId: 'ORD-79441',
        patientId: 'PT-84210',
        sampleBarcode: 'SMP-65103',
        testName: 'Lipid Profile & Glucose Fasting',
        branchName: 'Apollo Hub Diagnostic Center',
        pathologistName: 'Dr. Sunita Sen (Senior Pathologist)',
        verificationDate: now.subtract(const Duration(days: 20)),
        isReady: true,
        status: 'Verified & Ready',
        parameters: const [
          ReportParameter(name: 'Fasting Blood Sugar', value: '94 mg/dL', range: '70 - 100', flag: 'Normal'),
          ReportParameter(name: 'Total Cholesterol', value: '182 mg/dL', range: '< 200', flag: 'Normal'),
          ReportParameter(name: 'Triglycerides', value: '145 mg/dL', range: '< 150', flag: 'Normal'),
          ReportParameter(name: 'HDL (Good Cholesterol)', value: '48 mg/dL', range: '> 40', flag: 'Normal'),
          ReportParameter(name: 'LDL (Bad Cholesterol)', value: '105 mg/dL', range: '< 100', flag: 'Borderline High'),
        ],
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      ReportModel(
        id: 'REP-98311',
        orderId: 'ORD-84210',
        patientId: 'PT-84210',
        sampleBarcode: 'SMP-88390',
        testName: 'Thyroid Panel (T3, T4, TSH) & HbA1c',
        branchName: 'Central Diagnostic Lab - Sector 5',
        pathologistName: 'Pending Laboratory Analysis',
        verificationDate: null,
        isReady: false,
        status: 'Processing in Lab',
        parameters: const [],
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ]);
  }

  /// POST /api/patient/bookings
  Future<OrderModel> submitBooking(PatientBookingRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate async API delay

    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final sampleBarcode = 'SMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

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
      branchId: 'BR-CENTRAL',
      branchName: request.branchName,
      status: OrderStatus.confirmed,
      sampleBarcodes: [sampleBarcode],
      specialInstructions: request.notes,
      createdAt: DateTime.now(),
    );

    // Also register the sample in the diagnostic tracking system
    final sample = SampleModel(
      barcode: sampleBarcode,
      orderId: orderId,
      patientId: request.patientId,
      patientName: request.patientName,
      testNames: request.selectedTestNames,
      vialType: 'Standard Collection Kit',
      status: SampleStatus.booked,
      currentBranchName: request.branchName,
      createdAt: DateTime.now(),
      events: [
        SampleEventModel(
          id: 'EV-${DateTime.now().millisecondsSinceEpoch}',
          sampleBarcode: sampleBarcode,
          status: SampleStatus.booked,
          timestamp: DateTime.now(),
          actorId: request.patientId,
          actorName: request.patientName,
          actorRole: UserRole.patient,
          locationName: request.address,
          notes: 'Home collection appointment booked online.',
        ),
      ],
    );

    _orderStore.insert(0, order);
    _sampleStore.insert(0, sample);

    return order;
  }

  /// GET /api/patient/sample/:barcode
  Future<SampleModel?> trackSample(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final match = _sampleStore.where((s) => s.barcode.toLowerCase() == barcode.toLowerCase()).toList();
    if (match.isNotEmpty) return match.first;
    return null;
  }

  /// GET /api/patient/reports?patientId=...
  Future<List<ReportModel>> getPatientReports(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reportStore.where((r) => r.patientId == patientId).toList();
  }

  /// GET /api/patient/active-sample?patientId=...
  Future<SampleModel?> getActiveSample(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final samples = _sampleStore.where((s) => s.patientId == patientId && s.status != SampleStatus.delivered).toList();
    if (samples.isNotEmpty) return samples.first;
    return null;
  }
}
