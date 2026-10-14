import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/sample_event_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/central_data_store.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../domain/enums/user_role.dart';
import '../models/walk_in_requisition_request.dart';
import '../models/thermal_label_model.dart';
import '../models/frontdesk_search_item.dart';

/// Front Desk Service
/// Connected to CentralDataStore to search patient bookings,
/// register walk-in requisitions, and print thermal labels with real-time cross-role sync.
class FrontDeskService {
  final CentralDataStore _store = CentralDataStore.instance;
  static final List<ThermalLabelModel> _labelStore = [];
  static bool _labelsInitialized = false;

  FrontDeskService() {
    _ensureLabelsInitialized();
  }

  void _ensureLabelsInitialized() {
    if (_labelsInitialized) return;
    _labelsInitialized = true;

    final now = DateTime.now();
    _labelStore.addAll([
      ThermalLabelModel(
        barcode: 'SMP-88390',
        orderId: 'ORD-84210',
        patientName: 'John Doe',
        patientAgeGender: '38Y / M',
        testNames: const ['Thyroid Panel', 'HbA1c'],
        vialType: 'Gold Top (SST Serum Gel)',
        vialColorValue: 0xFFD97706,
        volumeRequired: '5.0 mL',
        branchId: 'branch-spoke-01',
        branchName: 'Downtown Spoke Center #1',
        timestamp: now.subtract(const Duration(hours: 4)),
        priority: 'Routine',
        isPrinted: true,
      ),
      ThermalLabelModel(
        barcode: 'SMP-90214',
        orderId: 'ORD-90214',
        patientName: 'Meena Gupta',
        patientAgeGender: '45Y / F',
        testNames: const ['Lipid Profile', 'HbA1c'],
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
        barcode: 'SMP-77401',
        orderId: 'ORD-77401',
        patientName: 'Arjun Kapoor',
        patientAgeGender: '52Y / M',
        testNames: const ['Complete Blood Count (CBC)'],
        vialType: 'Purple Top (K2 EDTA)',
        vialColorValue: 0xFF7C3AED,
        volumeRequired: '3.0 mL',
        branchId: 'branch-spoke-01',
        branchName: 'Downtown Spoke Center #1',
        timestamp: now.subtract(const Duration(hours: 1)),
        priority: 'Urgent STAT',
        isPrinted: true,
      ),
    ]);
  }

  List<OrderModel> get _orderStore => _store.orders;
  List<SampleModel> get _sampleStore => _store.samples;
  List<ReportModel> get _reportStore => _store.reports;

  /// Instant search matching phone number, order ID, barcode, or patient name.
  Future<List<FrontDeskSearchItem>> search({
    required String query,
    String filter = 'all', // 'all', 'ready', 'processing', 'inTransit'
  }) async {
    await Future.delayed(const Duration(milliseconds: 80)); // Sub-second search

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
    final validationError = request.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    await Future.delayed(const Duration(milliseconds: 250));

    final now = DateTime.now();
    final randomSuffix = (1000 + now.millisecond + _orderStore.length * 10).toString();
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

      int colorValue = 0xFF7E22CE; // purple
      String vol = '3.0 mL';
      if (vialType.contains('Gold')) {
        colorValue = 0xFFD97706; // gold
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
        patientPhone: request.patientPhone,
        testNames: testsForVial,
        tubeType: vialType,
        status: SampleStatus.collected,
        currentBranchId: request.branchId,
        currentBranchName: request.branchName,
        assignedPhlebotomistId: 'FD-108',
        assignedPhlebotomistName: 'Priya Sharma (Intake Counter)',
        collectedAt: now,
        temperatureC: 4.0,
        notes: 'Walk-in draw completed at front desk counter.',
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

    // Save into CentralDataStore (propagates across Patient, Phlebotomist, Lab, & Admin)
    _store.createOrder(order);
    for (final s in newSamples) {
      _store.saveSample(s);
    }
    for (final l in newLabels) {
      _labelStore.insert(0, l);
    }

    return newLabels;
  }

  /// Mark specific thermal labels as printed
  Future<void> markLabelsPrinted(List<String> barcodes) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (int i = 0; i < _labelStore.length; i++) {
      if (barcodes.contains(_labelStore[i].barcode)) {
        _labelStore[i] = _labelStore[i].copyWith(isPrinted: true);
      }
    }
  }

  /// Get recent thermal labels
  List<ThermalLabelModel> getRecentThermalLabels() {
    _ensureLabelsInitialized();
    return List.unmodifiable(_labelStore);
  }

  /// Get sample custody events
  SampleModel? getSampleByBarcode(String barcode) {
    return _store.getSample(barcode);
  }

  /// Get verified report by orderId
  ReportModel? getReportByOrderId(String orderId) {
    try {
      return _store.reports.firstWhere((r) => r.orderId == orderId);
    } catch (_) {
      return null;
    }
  }
}
