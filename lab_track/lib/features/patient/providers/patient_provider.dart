import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/sample_event_model.dart';
import '../../../data/models/report_model.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../domain/enums/user_role.dart';

class PatientProvider extends ChangeNotifier {
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

  PatientProvider() {
    _loadInitialMockData();
  }

  void _loadInitialMockData() {
    final now = DateTime.now();

    // Default sample in-transit for John Doe
    _activeSample = SampleModel(
      barcode: 'SMP-88390',
      orderId: 'ORD-84210',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      testNames: ['Thyroid & HbA1c Panel'],
      vialType: 'EDTA + SST Vacutainer',
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

    // Initial reports
    _reports = [
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
    ];
  }

  /// Create a new home collection booking
  Future<OrderModel> createBooking({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String address,
    required List<String> testNames,
    required double totalAmount,
    required DateTime date,
    required String timeSlot,
    required String branchName,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final sampleBarcode = 'SMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final newOrder = OrderModel(
      id: orderId,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      collectionAddress: address,
      testNames: testNames,
      totalAmount: totalAmount,
      scheduledDate: date,
      timeSlot: timeSlot,
      branchId: 'BR-CENTRAL',
      branchName: branchName,
      status: OrderStatus.confirmed,
      sampleBarcodes: [sampleBarcode],
      specialInstructions: notes,
      createdAt: DateTime.now(),
    );

    _orders.insert(0, newOrder);
    _isLoading = false;
    notifyListeners();
    return newOrder;
  }
}
