import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/sample_event_model.dart';
import '../../../data/models/report_model.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../domain/enums/user_role.dart';
import '../models/walk_in_requisition_request.dart';
import '../models/thermal_label_model.dart';
import '../models/frontdesk_search_item.dart';

class FrontDeskService {
  static final List<OrderModel> _orderStore = [];
  static final List<SampleModel> _sampleStore = [];
  static final List<ReportModel> _reportStore = [];
  static final List<ThermalLabelModel> _labelStore = [];
  static bool _initialized = false;

  FrontDeskService() {
    _ensureInitialized();
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();

    // 1. Order: John Doe (Active In-Transit & CBC Ready)
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
      assignedPhlebotomistId: 'PH-102',
      assignedPhlebotomistName: 'Rajeev Kumar',
      createdAt: now.subtract(const Duration(hours: 6)),
    );

    final sample1a = SampleModel(
      barcode: 'SMP-88390',
      orderId: 'ORD-84210',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      testNames: const ['Thyroid Panel (T3, T4, TSH)', 'HbA1c'],
      vialType: 'Gold Top (SST Serum Gel)',
      status: SampleStatus.inTransit,
      currentBranchId: 'branch-spoke-01',
      currentBranchName: 'Branch Spoke 01 Courier Relays',
      assignedPhlebotomistId: 'PH-102',
      assignedPhlebotomistName: 'Rajeev Kumar',
      collectionTime: now.subtract(const Duration(hours: 3)),
      temperatureStatus: '4.2°C (Cold Chain Normal)',
      notes: 'Sample picked up at home; sealed in cold-box courier pouch.',
      events: [
        SampleEventModel(
          id: 'EV-88390-1',
          sampleBarcode: 'SMP-88390',
          status: SampleStatus.collected,
          timestamp: now.subtract(const Duration(hours: 3)),
          actorId: 'PH-102',
          actorName: 'Rajeev Kumar (Phlebotomist)',
          actorRole: UserRole.phlebotomist,
          locationName: 'Patient Home (Sector 14)',
          temperatureCelsius: 4.0,
          notes: 'Vial drawn and sterile barcode affixed.',
        ),
        SampleEventModel(
          id: 'EV-88390-2',
          sampleBarcode: 'SMP-88390',
          status: SampleStatus.inTransit,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
          actorId: 'PH-102',
          actorName: 'Rajeev Kumar',
          actorRole: UserRole.phlebotomist,
          locationName: 'Transit to Downtown Spoke Center',
          temperatureCelsius: 4.2,
          notes: 'Temperature safe.',
        ),
        SampleEventModel(
          id: 'EV-88390-3',
          sampleBarcode: 'SMP-88390',
          status: SampleStatus.receivedAtBranch,
          timestamp: now.subtract(const Duration(minutes: 35)),
          actorId: 'FD-108',
          actorName: 'Priya Sharma (Front Desk)',
          actorRole: UserRole.frontDesk,
          locationName: 'Downtown Spoke Center Intake Desk',
          temperatureCelsius: 4.1,
          notes: 'Checked-in at front desk intake rack; routed for central lab courier.',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 6)),
    );

    final sample1b = SampleModel(
      barcode: 'SMP-77219',
      orderId: 'ORD-84210',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      testNames: const ['Complete Blood Count (CBC)'],
      vialType: 'Purple Top (K2 EDTA)',
      status: SampleStatus.reportReady,
      currentBranchId: 'branch-apex-hq',
      currentBranchName: 'Central Diagnostic Lab',
      collectionTime: now.subtract(const Duration(hours: 3)),
      temperatureStatus: '4.0°C (Normal)',
      notes: 'Analysis completed on Sysmex Automated Analyzer.',
      events: [
        SampleEventModel(
          id: 'EV-77219-1',
          sampleBarcode: 'SMP-77219',
          status: SampleStatus.collected,
          timestamp: now.subtract(const Duration(hours: 3)),
          actorId: 'PH-102',
          actorName: 'Rajeev Kumar',
          actorRole: UserRole.phlebotomist,
          locationName: 'Patient Home',
          temperatureCelsius: 4.0,
        ),
        SampleEventModel(
          id: 'EV-77219-2',
          sampleBarcode: 'SMP-77219',
          status: SampleStatus.receivedAtLab,
          timestamp: now.subtract(const Duration(hours: 2)),
          actorId: 'LAB-501',
          actorName: 'Sanjay Deshmukh (Lab Tech)',
          actorRole: UserRole.labTechnician,
          locationName: 'Central Diagnostic Lab - Hematology Rack #4',
        ),
        SampleEventModel(
          id: 'EV-77219-3',
          sampleBarcode: 'SMP-77219',
          status: SampleStatus.reportReady,
          timestamp: now.subtract(const Duration(minutes: 45)),
          actorId: 'PATH-01',
          actorName: 'Dr. Arvind Mehta (MD Pathologist)',
          actorRole: UserRole.admin,
          locationName: 'Central Diagnostic Lab',
          notes: 'Report verified and digitally signed.',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 6)),
    );

    final report1 = ReportModel(
      id: 'REP-91204',
      orderId: 'ORD-84210',
      patientId: 'PT-84210',
      sampleBarcode: 'SMP-77219',
      testName: 'Complete Blood Count (CBC)',
      branchName: 'Downtown Spoke Center #1',
      pathologistName: 'Dr. Arvind Mehta (MD Path, Reg: MCI-4421)',
      verificationDate: now.subtract(const Duration(minutes: 45)),
      isReady: true,
      status: 'Verified & Ready for Print',
      parameters: const [
        ReportParameter(name: 'Hemoglobin', value: '14.2', unit: 'g/dL', range: '13.0 - 17.0', flag: 'Normal'),
        ReportParameter(name: 'Total Leukocyte Count (WBC)', value: '7,400', unit: '/uL', range: '4,000 - 11,000', flag: 'Normal'),
        ReportParameter(name: 'Platelet Count', value: '245,000', unit: '/uL', range: '150,000 - 450,000', flag: 'Normal'),
        ReportParameter(name: 'RBC Count', value: '4.8', unit: 'mil/uL', range: '4.5 - 5.5', flag: 'Normal'),
        ReportParameter(name: 'Packed Cell Volume (PCV)', value: '42.5', unit: '%', range: '40.0 - 50.0', flag: 'Normal'),
        ReportParameter(name: 'Neutrophils', value: '62', unit: '%', range: '40 - 75', flag: 'Normal'),
        ReportParameter(name: 'Lymphocytes', value: '28', unit: '%', range: '20 - 45', flag: 'Normal'),
      ],
      createdAt: now.subtract(const Duration(hours: 3)),
    );

    // 2. Order: Meena Gupta (Lipid Profile & Glucose Fasting, Verified)
    final order2 = OrderModel(
      id: 'ORD-84212',
      patientId: 'PT-91024',
      patientName: 'Meena Gupta',
      patientPhone: '+91 98112 34567',
      collectionAddress: 'House 142, Block C, Green Glen Layout, Sector 18',
      testNames: const ['Lipid Profile', 'Fasting Blood Sugar (FBS)'],
      totalAmount: 1800.0,
      scheduledDate: now.subtract(const Duration(hours: 2)),
      timeSlot: '08:45 AM - 09:30 AM',
      branchId: 'branch-spoke-01',
      branchName: 'Downtown Spoke Center #1',
      status: OrderStatus.completed,
      sampleBarcodes: const ['SMP-90214', 'SMP-90215'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      createdAt: now.subtract(const Duration(hours: 8)),
    );

    final sample2a = SampleModel(
      barcode: 'SMP-90214',
      orderId: 'ORD-84212',
      patientId: 'PT-91024',
      patientName: 'Meena Gupta',
      testNames: const ['Lipid Profile'],
      vialType: 'Gold Top (SST Serum Gel)',
      status: SampleStatus.reportReady,
      currentBranchId: 'branch-spoke-01',
      currentBranchName: 'Downtown Spoke Center #1',
      collectionTime: now.subtract(const Duration(hours: 3)),
      temperatureStatus: '3.8°C (Normal)',
      events: [
        SampleEventModel(
          id: 'EV-90214-1',
          sampleBarcode: 'SMP-90214',
          status: SampleStatus.reportReady,
          timestamp: now.subtract(const Duration(hours: 1)),
          actorId: 'PATH-02',
          actorName: 'Dr. Sunita Sen (Chief Pathologist)',
          actorRole: UserRole.admin,
          locationName: 'Central Diagnostic Lab',
          notes: 'Biochemistry panel verified with borderline high LDL.',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 8)),
    );

    final sample2b = SampleModel(
      barcode: 'SMP-90215',
      orderId: 'ORD-84212',
      patientId: 'PT-91024',
      patientName: 'Meena Gupta',
      testNames: const ['Fasting Blood Sugar (FBS)'],
      vialType: 'Grey Top (Sodium Fluoride)',
      status: SampleStatus.reportReady,
      currentBranchId: 'branch-spoke-01',
      currentBranchName: 'Downtown Spoke Center #1',
      collectionTime: now.subtract(const Duration(hours: 3)),
      temperatureStatus: '4.0°C (Normal)',
      createdAt: now.subtract(const Duration(hours: 8)),
    );

    final report2 = ReportModel(
      id: 'REP-89410',
      orderId: 'ORD-84212',
      patientId: 'PT-91024',
      sampleBarcode: 'SMP-90214',
      testName: 'Lipid Profile & Glucose Fasting',
      branchName: 'Downtown Spoke Center #1',
      pathologistName: 'Dr. Sunita Sen (Senior Clinical Pathologist)',
      verificationDate: now.subtract(const Duration(hours: 1)),
      isReady: true,
      status: 'Verified & Ready for Print',
      parameters: const [
        ReportParameter(name: 'Fasting Blood Sugar (FBS)', value: '94', unit: 'mg/dL', range: '70 - 100', flag: 'Normal'),
        ReportParameter(name: 'Total Cholesterol', value: '182', unit: 'mg/dL', range: '< 200', flag: 'Normal'),
        ReportParameter(name: 'Triglycerides', value: '145', unit: 'mg/dL', range: '< 150', flag: 'Normal'),
        ReportParameter(name: 'HDL (Good Cholesterol)', value: '48', unit: 'mg/dL', range: '> 40', flag: 'Normal'),
        ReportParameter(name: 'LDL (Bad Cholesterol)', value: '112', unit: 'mg/dL', range: '< 100', flag: 'Borderline High'),
        ReportParameter(name: 'VLDL Cholesterol', value: '22', unit: 'mg/dL', range: '< 30', flag: 'Normal'),
      ],
      createdAt: now.subtract(const Duration(hours: 5)),
    );

    // 3. Order: Rajesh Sharma (Walk-In Requisition, Testing in progress)
    final order3 = OrderModel(
      id: 'ORD-84215',
      patientId: 'PT-88190',
      patientName: 'Rajesh Sharma',
      patientPhone: '+91 99887 76655',
      collectionAddress: 'Walk-In Patient Counter, Spoke Center 01',
      testNames: const ['Liver Function Test (LFT)', 'Serum Creatinine & Urea (KFT)'],
      totalAmount: 1200.0,
      scheduledDate: now.subtract(const Duration(hours: 1)),
      timeSlot: 'Walk-In Immediate',
      branchId: 'branch-spoke-01',
      branchName: 'Downtown Spoke Center #1',
      status: OrderStatus.inProgress,
      sampleBarcodes: const ['SMP-94001'],
      assignedPhlebotomistId: 'FD-108',
      assignedPhlebotomistName: 'Priya Sharma (Counter Phlebo)',
      createdAt: now.subtract(const Duration(hours: 1)),
    );

    final sample3 = SampleModel(
      barcode: 'SMP-94001',
      orderId: 'ORD-84215',
      patientId: 'PT-88190',
      patientName: 'Rajesh Sharma',
      testNames: const ['Liver Function Test (LFT)', 'Serum Creatinine (KFT)'],
      vialType: 'Gold Top (SST Serum Gel)',
      status: SampleStatus.processing,
      currentBranchId: 'branch-apex-hq',
      currentBranchName: 'Central Diagnostic Lab - Clinical Chemistry Rack',
      collectionTime: now.subtract(const Duration(hours: 1)),
      temperatureStatus: '4.0°C (Normal)',
      notes: 'Walk-in phlebotomy collection done at Desk 1. Centrifuged and run on Cobas Analyzer.',
      events: [
        SampleEventModel(
          id: 'EV-94001-1',
          sampleBarcode: 'SMP-94001',
          status: SampleStatus.collected,
          timestamp: now.subtract(const Duration(hours: 1)),
          actorId: 'FD-108',
          actorName: 'Priya Sharma',
          actorRole: UserRole.frontDesk,
          locationName: 'Downtown Spoke Center #1 Phlebotomy Bay',
          temperatureCelsius: 4.0,
        ),
        SampleEventModel(
          id: 'EV-94001-2',
          sampleBarcode: 'SMP-94001',
          status: SampleStatus.processing,
          timestamp: now.subtract(const Duration(minutes: 20)),
          actorId: 'LAB-102',
          actorName: 'Kavita Roy (Bio-chemist)',
          actorRole: UserRole.labTechnician,
          locationName: 'Central Lab Chemistry Analyzer B-2',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 1)),
    );

    // Seed into stores
    _orderStore.addAll([order1, order2, order3]);
    _sampleStore.addAll([sample1a, sample1b, sample2a, sample2b, sample3]);
    _reportStore.addAll([report1, report2]);

    // Initial seed thermal labels
    _labelStore.addAll([
      ThermalLabelModel(
        barcode: 'SMP-90214',
        orderId: 'ORD-84212',
        patientName: 'Meena Gupta',
        patientAgeGender: '46Y / F',
        testNames: const ['Lipid Profile'],
        vialType: 'Gold Top (SST Serum Gel)',
        vialColorValue: 0xFFD97706,
        volumeRequired: '5.0 mL',
        branchId: 'branch-spoke-01',
        branchName: 'Downtown Spoke Center #1',
        timestamp: now.subtract(const Duration(hours: 3)),
        priority: 'Routine',
        isPrinted: true,
      ),
      ThermalLabelModel(
        barcode: 'SMP-90215',
        orderId: 'ORD-84212',
        patientName: 'Meena Gupta',
        patientAgeGender: '46Y / F',
        testNames: const ['Fasting Glucose'],
        vialType: 'Grey Top (Sodium Fluoride)',
        vialColorValue: 0xFF475569,
        volumeRequired: '2.0 mL',
        branchId: 'branch-spoke-01',
        branchName: 'Downtown Spoke Center #1',
        timestamp: now.subtract(const Duration(hours: 3)),
        priority: 'Routine',
        isPrinted: true,
      ),
      ThermalLabelModel(
        barcode: 'SMP-94001',
        orderId: 'ORD-84215',
        patientName: 'Rajesh Sharma',
        patientAgeGender: '52Y / M',
        testNames: const ['LFT + KFT'],
        vialType: 'Gold Top (SST Serum Gel)',
        vialColorValue: 0xFFD97706,
        volumeRequired: '5.0 mL',
        branchId: 'branch-spoke-01',
        branchName: 'Downtown Spoke Center #1',
        timestamp: now.subtract(const Duration(hours: 1)),
        priority: 'Urgent STAT',
        isPrinted: true,
      ),
    ]);
  }

  /// Instant search matching phone number, order ID, barcode, or patient name.
  Future<List<FrontDeskSearchItem>> search({
    required String query,
    String filter = 'all', // 'all', 'ready', 'processing', 'inTransit'
  }) async {
    _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 100)); // Fast sub-second search

    final cleanQuery = query.trim().toLowerCase();
    final digitsQuery = cleanQuery.replaceAll(RegExp(r'[^0-9]'), '');

    // 1. Filter orders matching query
    final matchedOrders = _orderStore.where((order) {
      if (cleanQuery.isEmpty) return true;

      // Match Order ID
      if (order.id.toLowerCase().contains(cleanQuery)) return true;

      // Match Patient Name
      if (order.patientName.toLowerCase().contains(cleanQuery)) return true;

      // Match Phone
      final orderDigits = order.patientPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsQuery.isNotEmpty && orderDigits.contains(digitsQuery)) return true;

      // Match Sample Barcode
      if (order.sampleBarcodes.any((b) => b.toLowerCase().contains(cleanQuery))) return true;

      return false;
    }).toList();

    // 2. Assemble search items
    final List<FrontDeskSearchItem> items = [];
    for (final order in matchedOrders) {
      final samples = _sampleStore.where((s) => s.orderId == order.id).toList();
      final reports = _reportStore.where((r) => r.orderId == order.id).toList();

      final item = FrontDeskSearchItem(
        order: order,
        samples: samples,
        reports: reports,
      );

      // Apply tab filter
      if (filter == 'ready' && !item.hasReadyReport && item.aggregateStatus != SampleStatus.reportReady) {
        continue;
      }
      if (filter == 'processing' && item.aggregateStatus != SampleStatus.processing) {
        continue;
      }
      if (filter == 'inTransit' &&
          item.aggregateStatus != SampleStatus.inTransit &&
          item.aggregateStatus != SampleStatus.receivedAtBranch) {
        continue;
      }

      items.add(item);
    }

    return items;
  }

  /// Walk-In Patient Requisition: Auto-allocates tube types, generates barcodes & thermal labels
  Future<List<ThermalLabelModel>> createWalkInRequisition(WalkInRequisitionRequest request) async {
    _ensureInitialized();
    final validationError = request.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    await Future.delayed(const Duration(milliseconds: 350));

    final now = DateTime.now();
    final randomSuffix = (1000 + DateTime.now().millisecond + _orderStore.length * 10).toString();
    final orderId = 'ORD-FD-$randomSuffix';

    // Clinical Tube Allocation Logic based on selected panels
    final Map<String, List<String>> tubeAllocation = {};
    for (final test in request.selectedTestNames) {
      final t = test.toLowerCase();
      if (t.contains('cbc') || t.contains('hba1c') || t.contains('hemoglobin') || t.contains('esr') || t.contains('blood group')) {
        tubeAllocation.putIfAbsent('Purple Top (K2 EDTA)', () => []).add(test);
      } else if (t.contains('glucose') || t.contains('sugar') || t.contains('ppbs') || t.contains('fbs')) {
        tubeAllocation.putIfAbsent('Grey Top (Sodium Fluoride)', () => []).add(test);
      } else if (t.contains('coagulation') || t.contains('pt') || t.contains('inr') || t.contains('d-dimer')) {
        tubeAllocation.putIfAbsent('Light Blue (Sodium Citrate)', () => []).add(test);
      } else {
        // Serum SST for Thyroid, LFT, KFT, Lipids, Vitamins, Dengue, Electrolytes
        tubeAllocation.putIfAbsent('Gold Top (SST Serum Gel)', () => []).add(test);
      }
    }

    final List<String> generatedBarcodes = [];
    final List<SampleModel> newSamples = [];
    final List<ThermalLabelModel> newLabels = [];

    int barcodeIndex = 1;
    tubeAllocation.forEach((vialType, testsForVial) {
      final barcode = 'SMP-${10000 + _sampleStore.length + barcodeIndex}';
      generatedBarcodes.add(barcode);
      barcodeIndex++;

      int colorValue = 0xFF7E22CE; // default purple
      String vol = '3.0 mL';
      if (vialType.contains('Gold')) {
        colorValue = 0xFFD97706; // amber/gold
        vol = '5.0 mL';
      } else if (vialType.contains('Grey')) {
        colorValue = 0xFF475569; // slate grey
        vol = '2.0 mL';
      } else if (vialType.contains('Blue')) {
        colorValue = 0xFF0284C7; // sky blue
        vol = '2.7 mL';
      }

      // Create Sample Model
      final sample = SampleModel(
        barcode: barcode,
        orderId: orderId,
        patientId: 'PT-WALKIN-$randomSuffix',
        patientName: request.patientName,
        testNames: testsForVial,
        vialType: vialType,
        status: SampleStatus.collected,
        currentBranchId: request.branchId,
        currentBranchName: request.branchName,
        assignedPhlebotomistId: 'FD-108',
        assignedPhlebotomistName: 'Priya Sharma (Intake Counter)',
        collectionTime: now,
        temperatureStatus: '4.0°C (Normal)',
        notes: 'Walk-in sample collection at front desk counter. ${request.clinicalNotes ?? ""}'.trim(),
        events: [
          SampleEventModel(
            id: 'EV-$barcode-1',
            sampleBarcode: barcode,
            status: SampleStatus.collected,
            timestamp: now,
            actorId: 'FD-108',
            actorName: 'Priya Sharma',
            actorRole: UserRole.frontDesk,
            locationName: '${request.branchName} - Counter #1',
            temperatureCelsius: 4.0,
            notes: 'Walk-in draw completed. Sterile thermal barcode sticker affixed.',
          ),
        ],
        createdAt: now,
      );

      // Create Thermal Label Model
      final label = ThermalLabelModel(
        barcode: barcode,
        orderId: orderId,
        patientName: request.patientName,
        patientAgeGender: '${request.age}Y / ${request.gender[0].toUpperCase()}',
        testNames: testsForVial,
        vialType: vialType,
        vialColorValue: colorValue,
        volumeRequired: vol,
        branchId: request.branchId,
        branchName: request.branchName,
        timestamp: now,
        priority: request.priority,
        isPrinted: false,
      );

      newSamples.add(sample);
      newLabels.add(label);
    });

    // Create Order Model
    final order = OrderModel(
      id: orderId,
      patientId: 'PT-WALKIN-$randomSuffix',
      patientName: request.patientName,
      patientPhone: request.patientPhone,
      collectionAddress: request.address.isEmpty ? 'Walk-In at ${request.branchName}' : request.address,
      testNames: request.selectedTestNames,
      totalAmount: (request.selectedTestNames.length * 450.0),
      scheduledDate: now,
      timeSlot: 'Walk-In Immediate',
      branchId: request.branchId,
      branchName: request.branchName,
      status: OrderStatus.inProgress,
      sampleBarcodes: generatedBarcodes,
      assignedPhlebotomistId: 'FD-108',
      assignedPhlebotomistName: 'Priya Sharma',
      specialInstructions: 'Priority: ${request.priority}. ${request.clinicalNotes ?? ""}',
      createdAt: now,
    );

    // Save into in-memory store
    _orderStore.insert(0, order);
    for (final s in newSamples) {
      _sampleStore.insert(0, s);
    }
    for (final l in newLabels) {
      _labelStore.insert(0, l);
    }

    return newLabels;
  }

  /// Mark specific thermal labels as printed
  Future<void> markLabelsPrinted(List<String> barcodes) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < _labelStore.length; i++) {
      if (barcodes.contains(_labelStore[i].barcode)) {
        _labelStore[i] = _labelStore[i].copyWith(isPrinted: true);
      }
    }
  }

  /// Get recent thermal labels
  List<ThermalLabelModel> getRecentThermalLabels() {
    _ensureInitialized();
    return List.unmodifiable(_labelStore);
  }

  /// Get sample custody events
  SampleModel? getSampleByBarcode(String barcode) {
    _ensureInitialized();
    final match = _sampleStore.where((s) => s.barcode.toLowerCase() == barcode.toLowerCase()).toList();
    return match.isNotEmpty ? match.first : null;
  }

  /// Get verified report by orderId
  ReportModel? getReportByOrderId(String orderId) {
    _ensureInitialized();
    final match = _reportStore.where((r) => r.orderId == orderId).toList();
    return match.isNotEmpty ? match.first : null;
  }
}
