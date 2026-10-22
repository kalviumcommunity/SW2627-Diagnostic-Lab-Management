import 'package:flutter/foundation.dart';
import '../../admin/backend/models/sla_metric_model.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/report_model.dart';
import '../../data/models/sample_event_model.dart';
import '../../data/models/sample_model.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/sample_status.dart';
import '../../domain/enums/user_role.dart';
import '../../lab/backend/models/analyzer_equipment_model.dart';
import '../../lab/backend/models/lab_rack_model.dart';
import '../../lab/backend/models/qc_inspection_model.dart';

/// Central Unified Diagnostic Lab Data Store
/// Serves as the single source of truth across all 5 user roles:
/// Patient ⇄ Phlebotomist ⇄ Front Desk ⇄ Lab Tech / Pathologist ⇄ Admin.
class CentralDataStore extends ChangeNotifier {
  static final CentralDataStore _instance = CentralDataStore._internal();
  static CentralDataStore get instance => _instance;

  final List<OrderModel> _orders = [];
  final List<SampleModel> _samples = [];
  final List<ReportModel> _reports = [];
  final List<LabRackModel> _racks = [];
  final List<AnalyzerEquipmentModel> _analyzers = [];
  final List<QcInspectionModel> _qcRejections = [];
  final List<BranchModel> _branches = [];
  final List<StaffAllocationModel> _staff = [];

  bool _initialized = false;

  CentralDataStore._internal() {
    _ensureInitialized();
  }

  // ==========================================
  // Public Accessors (Read-Only Views)
  // ==========================================
  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<SampleModel> get samples => List.unmodifiable(_samples);
  List<ReportModel> get reports => List.unmodifiable(_reports);
  List<LabRackModel> get racks => List.unmodifiable(_racks);
  List<AnalyzerEquipmentModel> get analyzers => List.unmodifiable(_analyzers);
  List<QcInspectionModel> get qcRejections => List.unmodifiable(_qcRejections);
  List<BranchModel> get branches => List.unmodifiable(_branches);
  List<StaffAllocationModel> get staff => List.unmodifiable(_staff);

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();

    // 1. Seed Network Branches
    _branches.addAll([
      const BranchModel(
        id: 'branch-apex-hq',
        name: 'Apex Central Reference Laboratory',
        address: 'Plot 42, Institutional Area, Sector 32, Gurugram',
        city: 'Gurugram',
        hasTestingLab: true,
        phoneNumber: '+91 124 456 7890',
      ),
      const BranchModel(
        id: 'branch-spoke-01',
        name: 'Downtown Spoke Center #1',
        address: 'B-12, Ground Floor, Connaught Place, New Delhi',
        city: 'New Delhi',
        hasTestingLab: false,
        phoneNumber: '+91 11 2341 5678',
      ),
      const BranchModel(
        id: 'BR-004',
        name: 'Central Diagnostic Hub 4',
        address: 'Shop 14-16, Galleria Arcade, Sector 29, Gurugram',
        city: 'Gurugram',
        hasTestingLab: true,
        phoneNumber: '+91 124 998 1122',
      ),
      const BranchModel(
        id: 'branch-noida-02',
        name: 'Noida Sector 18 Express Collection Center',
        address: 'Tower A, Commercial Complex, Sector 18, Noida',
        city: 'Noida',
        hasTestingLab: false,
        phoneNumber: '+91 120 455 6789',
      ),
      const BranchModel(
        id: 'branch-southdelhi-03',
        name: 'South Extension Specialized Pathology',
        address: 'D-44, Ring Road, South Extension Part II, New Delhi',
        city: 'New Delhi',
        hasTestingLab: false,
        phoneNumber: '+91 11 4164 2233',
      ),
    ]);

    // 2. Seed Staff Allocations
    _staff.addAll([
      const StaffAllocationModel(
        id: 'PH-204',
        name: 'Rahul Verma',
        email: 'rahul.phlebo@labtrack.com',
        phoneNumber: '+91 98765 11111',
        role: UserRole.phlebotomist,
        assignedBranchId: 'branch-spoke-01',
        assignedBranchName: 'Downtown Spoke Center #1',
        isOnDuty: true,
        todayCompletedTasks: 7,
        pendingTasks: 3,
        avgRating: 4.9,
      ),
      const StaffAllocationModel(
        id: 'FD-108',
        name: 'Priya Sharma',
        email: 'priya.frontdesk@labtrack.com',
        phoneNumber: '+91 98765 22222',
        role: UserRole.frontDesk,
        assignedBranchId: 'branch-spoke-01',
        assignedBranchName: 'Downtown Spoke Center #1',
        isOnDuty: true,
        todayCompletedTasks: 15,
        pendingTasks: 12,
        avgRating: 4.8,
      ),
      const StaffAllocationModel(
        id: 'LAB-501',
        name: 'Dr. Sarah Chen',
        email: 'sarah.lab@labtrack.com',
        phoneNumber: '+91 98765 55555',
        role: UserRole.labTechnician,
        assignedBranchId: 'branch-apex-hq',
        assignedBranchName: 'Apex Central Reference Laboratory',
        isOnDuty: true,
        todayCompletedTasks: 34,
        pendingTasks: 28,
        avgRating: 4.95,
      ),
      const StaffAllocationModel(
        id: 'PATH-01',
        name: 'Dr. Arvind Mehta (MD Path)',
        email: 'arvind.path@labtrack.com',
        phoneNumber: '+91 98765 44444',
        role: UserRole.labTechnician,
        assignedBranchId: 'branch-apex-hq',
        assignedBranchName: 'Apex Central Reference Laboratory',
        isOnDuty: true,
        todayCompletedTasks: 12,
        pendingTasks: 5,
        avgRating: 4.98,
      ),
    ]);

    // 3. Seed Diagnostic Orders
    final order1 = OrderModel(
      id: 'ORD-84210',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      patientPhone: '+91 98765 43210',
      collectionAddress: 'Apartment 4B, Sunrise Residency, Sector 14, Gurugram',
      testNames: const ['Thyroid Panel (T3, T4, TSH)', 'HbA1c Glycated Hemoglobin', 'Complete Blood Count (CBC)'],
      totalAmount: 1450.0,
      scheduledDate: now.subtract(const Duration(hours: 4)),
      timeSlot: '07:30 AM - 08:30 AM',
      branchId: 'branch-spoke-01',
      branchName: 'Downtown Spoke Center #1',
      status: OrderStatus.inProgress,
      sampleBarcodes: const ['SMP-88390', 'SMP-77219'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      createdAt: now.subtract(const Duration(hours: 6)),
    );

    final order2 = OrderModel(
      id: 'ORD-90214',
      patientId: 'PT-90214',
      patientName: 'Meena Gupta',
      patientPhone: '+91 98765 77777',
      collectionAddress: 'Villa 12, Palm Meadows, DLF Phase 2, Gurugram',
      testNames: const ['Lipid Profile', 'HbA1c Glycated Hemoglobin'],
      totalAmount: 980.0,
      scheduledDate: now.subtract(const Duration(hours: 2)),
      timeSlot: '08:30 AM - 09:30 AM',
      branchId: 'branch-apex-hq',
      branchName: 'Apex Central Reference Laboratory',
      status: OrderStatus.inProgress,
      sampleBarcodes: const ['SMP-90214'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      createdAt: now.subtract(const Duration(hours: 4)),
    );

    final order3 = OrderModel(
      id: 'ORD-77401',
      patientId: 'PT-33109',
      patientName: 'Arjun Kapoor',
      patientPhone: '+91 98765 88990',
      collectionAddress: 'B-404, Pinnacle Tower, Golf Course Road, Gurugram',
      testNames: const ['Complete Blood Count (CBC) with Differential'],
      totalAmount: 450.0,
      scheduledDate: now.subtract(const Duration(hours: 1)),
      timeSlot: '09:30 AM - 10:30 AM',
      branchId: 'branch-apex-hq',
      branchName: 'Apex Central Reference Laboratory',
      status: OrderStatus.inProgress,
      sampleBarcodes: const ['SMP-77401'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      createdAt: now.subtract(const Duration(hours: 3)),
    );

    final order4 = OrderModel(
      id: 'ORD-84215',
      patientId: 'PT-84215',
      patientName: 'Rajesh Sharma',
      patientPhone: '+91 98765 33344',
      collectionAddress: 'Shop 12, Main Market, Connaught Place, New Delhi',
      testNames: const ['Lipid Profile', 'Liver Function Test (LFT)'],
      totalAmount: 1850.0,
      scheduledDate: now.subtract(const Duration(hours: 3)),
      timeSlot: '08:00 AM - 09:00 AM',
      branchId: 'branch-spoke-01',
      branchName: 'Downtown Spoke Center #1',
      status: OrderStatus.inProgress,
      sampleBarcodes: const ['SMP-94001'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      createdAt: now.subtract(const Duration(hours: 3)),
    );

    _orders.addAll([order1, order2, order3, order4]);

    // 4. Seed Physical Diagnostic Samples
    _samples.addAll([
      // Sample 1: John Doe - Collected by Rahul, in transit to lab
      SampleModel(
        barcode: 'SMP-88390',
        orderId: 'ORD-84210',
        patientId: 'PT-84210',
        patientName: 'John Doe',
        patientPhone: '+91 98765 43210',
        tubeType: 'Purple Top (K2 EDTA) + Gold Top (SST)',
        status: SampleStatus.inTransit,
        currentCustodianId: 'PH-204',
        currentCustodianRole: 'Phlebotomist',
        currentBranchId: 'branch-spoke-01',
        currentBranchName: 'Transit to Central Lab',
        assignedPhlebotomistId: 'PH-204',
        assignedPhlebotomistName: 'Rahul Verma',
        temperatureC: 4.2,
        testNames: const ['Thyroid Panel (T3, T4, TSH)', 'HbA1c', 'Complete Blood Count (CBC)'],
        notes: 'Cold chain verified. Home draw completed successfully.',
        events: [
          SampleEventModel(
            id: 'EV-88390-1',
            sampleBarcode: 'SMP-88390',
            toStatus: SampleStatus.collected,
            actorId: 'PH-204',
            actorName: 'Rahul Verma',
            actorRole: UserRole.phlebotomist,
            timestamp: now.subtract(const Duration(hours: 3)),
            branchId: 'Patient Home (Sector 14)',
            temperatureC: 4.0,
            note: 'Blood drawn sterile. Barcodes affixed.',
          ),
          SampleEventModel(
            id: 'EV-88390-2',
            sampleBarcode: 'SMP-88390',
            toStatus: SampleStatus.inTransit,
            actorId: 'PH-204',
            actorName: 'Rahul Verma',
            actorRole: UserRole.phlebotomist,
            timestamp: now.subtract(const Duration(hours: 1)),
            branchId: 'In Transit to Central Reference Lab',
            temperatureC: 4.2,
            note: 'Cold gel box temperature monitored.',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 4)),
      ),

      // Sample 2: Meena Gupta - Arrived at Central Lab courier receiving
      SampleModel(
        barcode: 'SMP-90214',
        orderId: 'ORD-90214',
        patientId: 'PT-90214',
        patientName: 'Meena Gupta',
        patientPhone: '+91 98765 77777',
        tubeType: 'Gold Top (SST Serum Gel)',
        status: SampleStatus.inTransitToCentralLab,
        currentCustodianId: 'COURIER-09',
        currentCustodianRole: 'Logistics Courier',
        currentBranchId: 'branch-apex-hq',
        currentBranchName: 'Apex Central Reference Lab Receiving Bay',
        temperatureC: 4.2,
        testNames: const ['Lipid Profile', 'HbA1c Glycated Hemoglobin'],
        notes: 'Arrived at Central Lab receiving desk.',
        events: [
          SampleEventModel(
            id: 'EV-90214-1',
            sampleBarcode: 'SMP-90214',
            toStatus: SampleStatus.collected,
            actorId: 'PH-204',
            actorName: 'Rahul Verma',
            actorRole: UserRole.phlebotomist,
            timestamp: now.subtract(const Duration(hours: 3)),
            branchId: 'Downtown Spoke Center #1',
            temperatureC: 4.0,
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
      ),

      // Sample 3: Arjun Kapoor - In Central Lab Accessioning
      SampleModel(
        barcode: 'SMP-77401',
        orderId: 'ORD-77401',
        patientId: 'PT-33109',
        patientName: 'Arjun Kapoor',
        patientPhone: '+91 98765 88990',
        tubeType: 'Purple Top (K2 EDTA)',
        status: SampleStatus.receivedAtLab,
        currentCustodianId: 'LAB-501',
        currentCustodianRole: 'Lab Technician',
        currentBranchId: 'branch-apex-hq',
        currentBranchName: 'Apex Central Reference Lab - Specimen Intake',
        temperatureC: 4.0,
        testNames: const ['Complete Blood Count (CBC) with Differential'],
        notes: 'Specimen checked in. Tube integrity verified.',
        events: [
          SampleEventModel(
            id: 'EV-77401-1',
            sampleBarcode: 'SMP-77401',
            toStatus: SampleStatus.receivedAtLab,
            actorId: 'LAB-501',
            actorName: 'Dr. Sarah Chen',
            actorRole: UserRole.labTechnician,
            timestamp: now.subtract(const Duration(minutes: 50)),
            branchId: 'Central Reference Lab - Bench A1',
            temperatureC: 4.0,
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),

      // Sample 4: Completed Sample for John Doe (CBC already verified)
      SampleModel(
        barcode: 'SMP-77219',
        orderId: 'ORD-84210',
        patientId: 'PT-84210',
        patientName: 'John Doe',
        patientPhone: '+91 98765 43210',
        tubeType: 'Purple Top (K2 EDTA)',
        status: SampleStatus.reportReady,
        currentCustodianId: 'PATH-01',
        currentCustodianRole: 'Pathologist',
        currentBranchId: 'branch-apex-hq',
        currentBranchName: 'Apex Central Reference Laboratory',
        temperatureC: 4.0,
        testNames: const ['Complete Blood Count (CBC)'],
        notes: 'Testing complete. Electronically signed by Dr. Arvind Mehta.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),

      // Sample 5: Rajesh Sharma - Collected & In Transit
      SampleModel(
        barcode: 'SMP-94001',
        orderId: 'ORD-84215',
        patientId: 'PT-84215',
        patientName: 'Rajesh Sharma',
        patientPhone: '+91 98765 33344',
        tubeType: 'Gold Top (SST Serum Gel)',
        status: SampleStatus.inTransit,
        currentCustodianId: 'PH-204',
        currentCustodianRole: 'Phlebotomist',
        currentBranchId: 'branch-spoke-01',
        currentBranchName: 'Downtown Spoke Center #1',
        temperatureC: 4.1,
        testNames: const ['Lipid Profile', 'Liver Function Test (LFT)'],
        notes: 'Cold chain verified. Home draw completed.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ]);

    // 5. Seed Diagnostic Reports
    _reports.addAll([
      // Report 1: Ready for Pathologist Review
      ReportModel(
        id: 'REP-84210',
        orderId: 'ORD-84210',
        sampleBarcode: 'SMP-88390',
        patientId: 'PT-84210',
        patientName: 'John Doe',
        testName: 'Complete Blood Count (CBC) with Differential',
        branchName: 'Apex Central Reference Laboratory',
        pathologistName: null,
        uploadedById: 'LAB-501',
        status: 'Pending Authorization',
        isReady: false,
        testResults: const [
          ReportParameter(name: 'Hemoglobin', value: '14.8', unit: 'g/dL', range: '13.0 - 17.0', flag: 'Normal'),
          ReportParameter(name: 'Total Leukocyte Count (WBC)', value: '11,800', unit: '/uL', range: '4,000 - 11,000', flag: 'High'),
          ReportParameter(name: 'Platelet Count', value: '265,000', unit: '/uL', range: '150,000 - 450,000', flag: 'Normal'),
          ReportParameter(name: 'Packed Cell Volume (PCV)', value: '44.2', unit: '%', range: '40.0 - 50.0', flag: 'Normal'),
          ReportParameter(name: 'Neutrophils', value: '74', unit: '%', range: '40 - 70', flag: 'High'),
          ReportParameter(name: 'Lymphocytes', value: '20', unit: '%', range: '20 - 40', flag: 'Normal'),
        ],
        createdAt: now.subtract(const Duration(minutes: 35)),
      ),

      // Report 2: Fully Verified and Signed
      ReportModel(
        id: 'REP-91204',
        orderId: 'ORD-81002',
        sampleBarcode: 'SMP-77219',
        patientId: 'PT-84210',
        patientName: 'John Doe',
        testName: 'Liver Function Panel (LFT)',
        branchName: 'Apex Central Reference Laboratory',
        pathologistName: 'Dr. Arvind Mehta (MD Path, Reg: MCI-4421)',
        uploadedById: 'LAB-501',
        status: 'Verified & Ready',
        isReady: true,
        verificationDate: now.subtract(const Duration(days: 1)),
        testResults: const [
          ReportParameter(name: 'Serum Bilirubin (Total)', value: '0.9', unit: 'mg/dL', range: '0.2 - 1.2', flag: 'Normal'),
          ReportParameter(name: 'SGOT (AST)', value: '28', unit: 'U/L', range: '10 - 40', flag: 'Normal'),
          ReportParameter(name: 'SGPT (ALT)', value: '32', unit: 'U/L', range: '7 - 56', flag: 'Normal'),
          ReportParameter(name: 'Alkaline Phosphatase (ALP)', value: '88', unit: 'U/L', range: '44 - 147', flag: 'Normal'),
          ReportParameter(name: 'Serum Albumin', value: '4.4', unit: 'g/dL', range: '3.5 - 5.5', flag: 'Normal'),
        ],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // 6. Seed Quality Control Rejection Log
    _qcRejections.add(
      QcInspectionModel(
        id: 'QC-88390',
        sampleBarcode: 'SMP-88390',
        patientName: 'John Doe',
        testName: 'Complete Blood Count (CBC) with Differential',
        rejectionReason: 'Hemolyzed Specimen (Free Hb > 500mg/dL)',
        technicianId: 'LAB-501',
        technicianName: 'Dr. Sarah Chen (#LAB-501)',
        rejectedAt: now.subtract(const Duration(hours: 1)),
        clinicalNotes: 'Specimen rejected during pre-analytical inspection.',
      ),
    );

    // 7. Seed Analyzer Racks
    _racks.addAll([
      LabRackModel(
        id: 'RACK-HEM-01',
        name: 'Rack A1 (K2 EDTA Whole Blood)',
        department: 'Hematology',
        analyzerName: 'Sysmex XN-1000 Hematology Workcell',
        capacity: 24,
        sampleBarcodes: ['SMP-77401', 'SMP-88390'],
        status: 'in_analyzer',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      LabRackModel(
        id: 'RACK-BIO-02',
        name: 'Rack B2 (SST Yellow Cap Serum)',
        department: 'Biochemistry',
        analyzerName: 'Roche Cobas 8000 Clinical Chemistry',
        capacity: 30,
        sampleBarcodes: ['SMP-90214'],
        status: 'in_analyzer',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);

    // 8. Seed Connected Analyzers
    _analyzers.addAll([
      AnalyzerEquipmentModel(
        id: 'EQ-SYS-01',
        name: 'Sysmex XN-1000 Hematology System',
        modelNumber: 'XN-1000-Automated-CBC',
        department: 'Hematology',
        status: 'Online & Calibrated',
        samplesProcessedToday: 184,
        temperatureC: 21.4,
        lastCalibrationTime: now.subtract(const Duration(hours: 6)),
        reagentLevel: 'Optimal (92%)',
      ),
      AnalyzerEquipmentModel(
        id: 'EQ-ROCHE-02',
        name: 'Roche Cobas 8000 Clinical Chemistry',
        modelNumber: 'Cobas-c702-Pro',
        department: 'Biochemistry',
        status: 'Analyzing Batch',
        samplesProcessedToday: 320,
        temperatureC: 22.0,
        lastCalibrationTime: now.subtract(const Duration(hours: 12)),
        reagentLevel: 'Adequate (76%)',
      ),
      AnalyzerEquipmentModel(
        id: 'EQ-IMMUNO-03',
        name: 'Abbott Architect i2000SR Immunoassay',
        modelNumber: 'Architect-i2000SR',
        department: 'Immunology',
        status: 'Online & Calibrated',
        samplesProcessedToday: 96,
        temperatureC: 22.1,
        lastCalibrationTime: now.subtract(const Duration(hours: 9)),
        reagentLevel: 'Optimal (88%)',
      ),
      AnalyzerEquipmentModel(
        id: 'EQ-COAG-04',
        name: 'Stago STA Compact Max Coagulation',
        modelNumber: 'STA-Compact-Max',
        department: 'Coagulation',
        status: 'Standby - Ready',
        samplesProcessedToday: 74,
        temperatureC: 21.8,
        lastCalibrationTime: now.subtract(const Duration(hours: 4)),
        reagentLevel: 'Adequate (71%)',
      ),
    ]);
  }

  // ==========================================================
  // Cross-Role Mutation Methods (Auto-Synchronized across roles)
  // ==========================================================

  /// 1. Patient or Front Desk creates a new booking order
  void createOrder(OrderModel order) {
    _orders.insert(0, order);

    // If barcodes are specified or generate default sample
    for (final barcode in order.sampleBarcodes) {
      final sample = SampleModel(
        barcode: barcode,
        orderId: order.id,
        patientId: order.patientId,
        patientName: order.patientName,
        patientPhone: order.patientPhone,
        tubeType: 'Standard Collection Tube',
        status: SampleStatus.booked,
        currentBranchId: order.branchId,
        currentBranchName: order.branchName,
        assignedPhlebotomistId: order.assignedPhlebotomistId,
        assignedPhlebotomistName: order.assignedPhlebotomistName,
        testNames: order.testNames,
        createdAt: order.createdAt,
      );
      saveSample(sample);
    }

    notifyListeners();
  }

  /// 2. Phlebotomist confirms sample draw & binds barcode
  void confirmPhlebotomistCollection({
    required String orderId,
    required String sampleBarcode,
    required String tubeType,
    required double temperature,
    required String phlebotomistId,
    required String phlebotomistName,
    String? locationName,
    String? notes,
  }) {
    final now = DateTime.now();

    // 1. Update Order
    final oIdx = _orders.indexWhere((o) => o.id == orderId);
    if (oIdx != -1) {
      final existing = _orders[oIdx];
      final barcodes = List<String>.from(existing.sampleBarcodes);
      if (!barcodes.contains(sampleBarcode)) barcodes.add(sampleBarcode);
      _orders[oIdx] = existing.copyWith(
        status: OrderStatus.inProgress,
        sampleBarcodes: barcodes,
        assignedPhlebotomistId: phlebotomistId,
        assignedPhlebotomistName: phlebotomistName,
      );
    }

    // 2. Insert / Update Sample
    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == sampleBarcode.toUpperCase());
    final milestone = SampleEventModel(
      id: 'EV-$sampleBarcode-${now.millisecondsSinceEpoch}',
      sampleBarcode: sampleBarcode,
      toStatus: SampleStatus.collected,
      actorId: phlebotomistId,
      actorName: phlebotomistName,
      actorRole: UserRole.phlebotomist,
      timestamp: now,
      branchId: locationName ?? 'Doorstep Draw',
      temperatureC: temperature,
      note: notes ?? 'Specimen drawn sterile. Sterile thermal barcode affixed.',
    );

    if (sIdx != -1) {
      final s = _samples[sIdx];
      final events = List<SampleEventModel>.from(s.events)..add(milestone);
      _samples[sIdx] = s.copyWith(
        tubeType: tubeType,
        status: SampleStatus.inTransit,
        currentCustodianId: phlebotomistId,
        currentCustodianRole: 'Phlebotomist',
        temperatureC: temperature,
        collectedAt: now,
        notes: notes,
        events: events,
        lastEventAt: now,
      );
    } else {
      final patientName = oIdx != -1 ? _orders[oIdx].patientName : 'Patient';
      final patientPhone = oIdx != -1 ? _orders[oIdx].patientPhone : '';
      final testNames = oIdx != -1 ? _orders[oIdx].testNames : <String>[];

      final newSample = SampleModel(
        barcode: sampleBarcode,
        orderId: orderId,
        patientId: oIdx != -1 ? _orders[oIdx].patientId : 'PT-UNKNOWN',
        patientName: patientName,
        patientPhone: patientPhone,
        tubeType: tubeType,
        status: SampleStatus.inTransit,
        currentCustodianId: phlebotomistId,
        currentCustodianRole: 'Phlebotomist',
        assignedPhlebotomistId: phlebotomistId,
        assignedPhlebotomistName: phlebotomistName,
        temperatureC: temperature,
        collectedAt: now,
        testNames: testNames,
        notes: notes,
        events: [milestone],
        createdAt: now,
      );
      _samples.insert(0, newSample);
    }

    notifyListeners();
  }

  /// 3. Phlebotomist hands over batch to spoke hub or central lab
  void handoverBatchToHub({
    required List<String> barcodes,
    required String branchId,
    required String branchName,
    required String receiverName,
  }) {
    final now = DateTime.now();
    for (final barcode in barcodes) {
      final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == barcode.toUpperCase());
      if (sIdx != -1) {
        final s = _samples[sIdx];
        final milestone = SampleEventModel(
          id: 'EV-HUB-$barcode-${now.millisecondsSinceEpoch}',
          sampleBarcode: barcode,
          toStatus: SampleStatus.receivedAtBranch,
          actorId: 'FD-HUB',
          actorName: receiverName,
          actorRole: UserRole.frontDesk,
          timestamp: now,
          branchId: branchName,
          temperatureC: s.temperatureC,
          note: 'Handed over to $branchName. Verified by $receiverName.',
        );
        final events = List<SampleEventModel>.from(s.events)..add(milestone);
        _samples[sIdx] = s.copyWith(
          status: SampleStatus.receivedAtBranch,
          currentBranchId: branchId,
          currentBranchName: branchName,
          currentCustodianId: 'HUB-$branchId',
          currentCustodianRole: 'Hub Desk',
          events: events,
          lastEventAt: now,
        );
      }
    }
    notifyListeners();
  }

  /// 4. Lab Tech accessions incoming specimen into Central Lab
  void accessionSpecimen({
    required String barcode,
    String? rackId,
    String? notes,
    String technicianName = 'Dr. Sarah Chen (#LAB-501)',
  }) {
    final now = DateTime.now();
    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == barcode.toUpperCase());

    final milestone = SampleEventModel(
      id: 'EV-ACC-$barcode-${now.millisecondsSinceEpoch}',
      sampleBarcode: barcode,
      toStatus: SampleStatus.receivedAtLab,
      actorId: 'LAB-501',
      actorName: technicianName,
      actorRole: UserRole.labTechnician,
      timestamp: now,
      branchId: 'Apex Central Reference Laboratory',
      temperatureC: 4.0,
      note: notes ?? 'Accessioned into Central Lab. Barcode verified.',
    );

    if (sIdx != -1) {
      final s = _samples[sIdx];
      final events = List<SampleEventModel>.from(s.events)..add(milestone);
      _samples[sIdx] = s.copyWith(
        status: SampleStatus.receivedAtLab,
        currentCustodianId: 'LAB-501',
        currentCustodianRole: 'Lab Technician',
        currentBranchId: 'branch-apex-hq',
        currentBranchName: 'Apex Central Reference Laboratory',
        temperatureC: 4.0,
        notes: notes ?? s.notes,
        events: events,
        lastEventAt: now,
      );
    }

    if (rackId != null && rackId.isNotEmpty) {
      assignToRack(barcode: barcode, rackId: rackId);
    } else {
      notifyListeners();
    }
  }

  /// 5. Assign sample to automated analyzer rack (Status: Processing)
  void assignToRack({
    required String barcode,
    required String rackId,
  }) {
    final now = DateTime.now();
    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == barcode.toUpperCase());
    if (sIdx != -1) {
      final s = _samples[sIdx];
      final milestone = SampleEventModel(
        id: 'EV-RACK-$barcode-${now.millisecondsSinceEpoch}',
        sampleBarcode: barcode,
        toStatus: SampleStatus.processing,
        actorId: 'LAB-501',
        actorName: 'Dr. Sarah Chen',
        actorRole: UserRole.labTechnician,
        timestamp: now,
        branchId: 'Analyzer Rack: $rackId',
        note: 'Loaded into analyzer rack $rackId for photometric testing.',
      );
      final events = List<SampleEventModel>.from(s.events)..add(milestone);
      _samples[sIdx] = s.copyWith(
        status: SampleStatus.processing,
        events: events,
        lastEventAt: now,
      );
    }

    final rIdx = _racks.indexWhere((r) => r.id == rackId);
    if (rIdx != -1) {
      final rack = _racks[rIdx];
      if (!rack.sampleBarcodes.contains(barcode.toUpperCase())) {
        final barcodes = List<String>.from(rack.sampleBarcodes)..add(barcode.toUpperCase());
        _racks[rIdx] = rack.copyWith(
          sampleBarcodes: barcodes,
          status: barcodes.length >= rack.capacity ? 'in_analyzer' : 'loading',
        );
      }
    }

    notifyListeners();
  }

  /// 6. Save Analytical Test Results
  ReportModel saveTestResults({
    required String sampleBarcode,
    required List<ReportParameter> parameters,
    String? testName,
    String? notes,
  }) {
    final now = DateTime.now();
    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == sampleBarcode.toUpperCase());
    var sample = sIdx != -1 ? _samples[sIdx] : null;
    if (sample == null) {
      sample = SampleModel(
        barcode: sampleBarcode.toUpperCase(),
        orderId: 'ORD-LAB-${now.millisecondsSinceEpoch}',
        patientId: 'PT-UNKNOWN',
        patientName: 'Patient',
        currentBranchId: 'branch-apex-hq',
        currentBranchName: 'Apex Central Reference Laboratory',
        status: SampleStatus.receivedAtLab,
        testNames: testName == null ? const [] : [testName],
        createdAt: now,
      );
      _samples.insert(0, sample);
    }

    final effectiveTestName = testName ?? (sample.testNames.isNotEmpty ? sample.testNames.first : 'Diagnostic Panel');
    final patientId = sample.patientId;
    final patientName = sample.patientName;
    final orderId = sample.orderId;

    final rIdx = _reports.indexWhere((r) => r.sampleBarcode.toUpperCase() == sampleBarcode.toUpperCase());
    if (rIdx != -1) {
      final existing = _reports[rIdx];
      final updated = ReportModel(
        id: existing.id,
        orderId: existing.orderId,
        sampleBarcode: existing.sampleBarcode,
        patientId: existing.patientId,
        patientName: existing.patientName,
        testName: effectiveTestName,
        branchName: 'Apex Central Reference Laboratory',
        uploadedById: 'Dr. Sarah Chen (#LAB-501)',
        pathologistName: existing.pathologistName,
        status: 'Pending Authorization',
        isReady: false,
        testResults: parameters,
        createdAt: existing.createdAt,
      );
      _reports[rIdx] = updated;
      notifyListeners();
      return updated;
    } else {
      final newReport = ReportModel(
        id: 'REP-${now.millisecondsSinceEpoch}',
        orderId: orderId,
        sampleBarcode: sampleBarcode.toUpperCase(),
        patientId: patientId,
        patientName: patientName,
        testName: effectiveTestName,
        branchName: 'Apex Central Reference Laboratory',
        uploadedById: 'Dr. Sarah Chen (#LAB-501)',
        status: 'Pending Authorization',
        isReady: false,
        testResults: parameters,
        createdAt: now,
      );
      _reports.insert(0, newReport);
      notifyListeners();
      return newReport;
    }
  }

  /// 7. Pathologist Digital Verification & Signature (Transitions to Report Ready)
  ReportModel authorizeAndSignReport({
    required String reportId,
    required String pathologistName,
    String? clinicalInterpretation,
  }) {
    final now = DateTime.now();
    final rIdx = _reports.indexWhere((r) => r.id == reportId);
    if (rIdx == -1) {
      throw Exception('Report $reportId not found.');
    }

    final rep = _reports[rIdx];
    final verified = ReportModel(
      id: rep.id,
      orderId: rep.orderId,
      sampleBarcode: rep.sampleBarcode,
      patientId: rep.patientId,
      patientName: rep.patientName,
      testName: rep.testName,
      branchName: rep.branchName,
      uploadedById: rep.uploadedById,
      pathologistName: pathologistName,
      status: 'Verified & Ready',
      isReady: true,
      verifiedAt: now,
      testResults: rep.testResults,
      createdAt: rep.createdAt,
    );
    _reports[rIdx] = verified;

    // Transition Sample to reportReady
    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == rep.sampleBarcode.toUpperCase());
    if (sIdx != -1) {
      final s = _samples[sIdx];
      final milestone = SampleEventModel(
        id: 'EV-SIGN-${rep.sampleBarcode}-${now.millisecondsSinceEpoch}',
        sampleBarcode: rep.sampleBarcode,
        toStatus: SampleStatus.reportReady,
        actorId: 'PATH-01',
        actorName: pathologistName,
        actorRole: UserRole.labTechnician,
        timestamp: now,
        branchId: 'Apex Central Reference Laboratory',
        note: 'Report authorized and signed. Ready for patient download.',
      );
      final events = List<SampleEventModel>.from(s.events)..add(milestone);
      _samples[sIdx] = s.copyWith(
        status: SampleStatus.reportReady,
        events: events,
        lastEventAt: now,
      );
    }

    // Transition Order to completed
    final oIdx = _orders.indexWhere((o) => o.id == rep.orderId);
    if (oIdx != -1) {
      _orders[oIdx] = _orders[oIdx].copyWith(status: OrderStatus.completed);
    }

    notifyListeners();
    return verified;
  }

  /// 8. QC Specimen Rejection (Flags failure & triggers recollection)
  QcInspectionModel recordQcRejection({
    required String barcode,
    required String rejectionReason,
    String? clinicalNotes,
    String technicianName = 'Dr. Sarah Chen (#LAB-501)',
  }) {
    final now = DateTime.now();
    String patientName = 'Patient';
    String testName = 'Diagnostic Panel';

    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == barcode.toUpperCase());
    if (sIdx != -1) {
      final s = _samples[sIdx];
      patientName = s.patientName;
      testName = s.testNames.isNotEmpty ? s.testNames.first : 'Test Panel';

      final milestone = SampleEventModel(
        id: 'EV-REJ-$barcode-${now.millisecondsSinceEpoch}',
        sampleBarcode: barcode,
        toStatus: SampleStatus.rejected,
        actorId: 'LAB-501',
        actorName: technicianName,
        actorRole: UserRole.labTechnician,
        timestamp: now,
        branchId: 'Central Lab QC Reject Station',
        note: 'REJECTED: $rejectionReason. ${clinicalNotes ?? ""}'.trim(),
      );
      final events = List<SampleEventModel>.from(s.events)..add(milestone);
      _samples[sIdx] = s.copyWith(
        status: SampleStatus.rejected,
        notes: 'REJECTED: $rejectionReason',
        events: events,
        lastEventAt: now,
      );
    }

    final qc = QcInspectionModel(
      id: 'QC-${now.millisecondsSinceEpoch}',
      sampleBarcode: barcode.toUpperCase(),
      patientName: patientName,
      testName: testName,
      rejectionReason: rejectionReason,
      technicianId: 'LAB-501',
      technicianName: technicianName,
      rejectedAt: now,
      clinicalNotes: clinicalNotes,
      recollectionTriggered: true,
    );
    _qcRejections.insert(0, qc);

    // Create automatic recollection pickup order for phlebotomist & front desk
    final recollectionOrder = OrderModel(
      id: 'ORD-REC-${now.millisecondsSinceEpoch.toString().substring(7)}',
      patientId: sIdx != -1 ? _samples[sIdx].patientId : 'PT-REC',
      patientName: patientName,
      patientPhone: sIdx != -1 ? _samples[sIdx].patientPhone : '',
      collectionAddress: 'Patient Home (Priority Recollection)',
      testNames: [testName],
      totalAmount: 0.0, // Free recollection due to lab QC
      scheduledDate: now.add(const Duration(hours: 2)),
      timeSlot: 'STAT RECOLLECTION: $rejectionReason',
      branchId: 'branch-spoke-01',
      branchName: 'Downtown Spoke Center #1',
      status: OrderStatus.inProgress,
      sampleBarcodes: ['SMP-REC-${now.millisecondsSinceEpoch.toString().substring(8)}'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      specialInstructions: 'STAT RE-DRAW: Previous specimen failed QC ($rejectionReason).',
      createdAt: now,
    );
    _orders.insert(0, recollectionOrder);

    notifyListeners();
    return qc;
  }

  void saveSample(SampleModel sample) {
    final idx = _samples.indexWhere((s) => s.barcode.toUpperCase() == sample.barcode.toUpperCase());
    if (idx != -1) {
      _samples[idx] = sample;
    } else {
      _samples.insert(0, sample);
    }
    notifyListeners();
  }

  SampleModel? getSample(String barcode) {
    try {
      return _samples.firstWhere((s) => s.barcode.toUpperCase() == barcode.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  OrderModel? getOrder(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id.toUpperCase() == orderId.toUpperCase());
    } catch (_) {
      return null;
    }
  }
}
