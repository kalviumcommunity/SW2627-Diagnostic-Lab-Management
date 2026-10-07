import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/sample_event_model.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../domain/enums/user_role.dart';
import '../models/phlebotomist_collection_request.dart';

/// Phlebotomist Backend API Service (Collection, Vial Barcoding & Cold-Chain Intake)
/// Supports real-time doorstep operations, barcode binding, and custody logging.
class PhlebotomistService {
  static final List<OrderModel> _orderStore = [];
  static final List<SampleModel> _sampleStore = [];
  static final List<Map<String, dynamic>> _tempLogs = [];
  static bool _initialized = false;

  PhlebotomistService() {
    _ensureInitialized();
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();

    // Seed realistic doorstep pickup orders assigned to Phlebotomist PH-204
    _orderStore.addAll([
      OrderModel(
        id: 'ORD-84210',
        patientId: 'PT-84210',
        patientName: 'John Doe',
        patientPhone: '+91 98765 43210',
        collectionAddress: 'Apartment 4B, Sunrise Residency, Sector 14, Gurugram',
        testNames: const ['Thyroid Panel (T3, T4, TSH)', 'HbA1c Glycated Hemoglobin'],
        totalAmount: 1450.0,
        scheduledDate: now,
        timeSlot: '07:30 AM - 08:30 AM (Urgent Fasting)',
        branchId: 'BR-004',
        branchName: 'Branch Hub 4 - Central',
        status: OrderStatus.confirmed,
        sampleBarcodes: const [],
        assignedPhlebotomistId: 'PH-204',
        assignedPhlebotomistName: 'Rahul Verma',
        specialInstructions: 'Patient is diabetic; 10-hour fasting sample required. Ring apartment bell 4B.',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      OrderModel(
        id: 'ORD-84212',
        patientId: 'PT-91024',
        patientName: 'Meena Gupta',
        patientPhone: '+91 98112 34567',
        collectionAddress: 'House 142, Block C, Green Glen Layout, Sector 18',
        testNames: const ['Lipid Profile', 'Fasting Blood Sugar (FBS)', 'Serum Creatinine'],
        totalAmount: 1800.0,
        scheduledDate: now,
        timeSlot: '08:45 AM - 09:30 AM (Fasting)',
        branchId: 'BR-004',
        branchName: 'Branch Hub 4 - Central',
        status: OrderStatus.confirmed,
        sampleBarcodes: const [],
        assignedPhlebotomistId: 'PH-204',
        assignedPhlebotomistName: 'Rahul Verma',
        specialInstructions: 'Senior citizen (68 yrs). Difficulty walking; draw blood sitting in living room.',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      OrderModel(
        id: 'ORD-84215',
        patientId: 'PT-77312',
        patientName: 'Amit Shah',
        patientPhone: '+91 98223 88990',
        collectionAddress: 'Flat 901, Tower 2, DLF Phase 5, Golf Course Road',
        testNames: const ['Complete Blood Count (CBC)', 'Liver Function Test (LFT)'],
        totalAmount: 1200.0,
        scheduledDate: now,
        timeSlot: '10:00 AM - 11:00 AM (Routine)',
        branchId: 'BR-004',
        branchName: 'Branch Hub 4 - Central',
        status: OrderStatus.confirmed,
        sampleBarcodes: const [],
        assignedPhlebotomistId: 'PH-204',
        assignedPhlebotomistName: 'Rahul Verma',
        specialInstructions: 'Routine checkup. Non-fasting is acceptable. Gated security pass required.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      OrderModel(
        id: 'ORD-84201',
        patientId: 'PT-66401',
        patientName: 'Sunita Rao',
        patientPhone: '+91 99887 11223',
        collectionAddress: 'Villa 12, Palm Meadows, Sector 11',
        testNames: const ['Vitamin D-3 (25-OH)', 'Vitamin B12'],
        totalAmount: 2100.0,
        scheduledDate: now,
        timeSlot: '06:45 AM - 07:15 AM (Early Morning)',
        branchId: 'BR-004',
        branchName: 'Branch Hub 4 - Central',
        status: OrderStatus.completed,
        sampleBarcodes: const ['SMP-77102'],
        assignedPhlebotomistId: 'PH-204',
        assignedPhlebotomistName: 'Rahul Verma',
        specialInstructions: 'Completed earlier today. In cool box.',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ]);

    // Initial collected sample in cool box
    _sampleStore.add(
      SampleModel(
        barcode: 'SMP-77102',
        orderId: 'ORD-84201',
        patientId: 'PT-66401',
        patientName: 'Sunita Rao',
        testNames: const ['Vitamin D-3 (25-OH)', 'Vitamin B12'],
        vialType: 'SST (Gold Top Serum Gel)',
        status: SampleStatus.collected,
        currentBranchId: 'BR-004',
        currentBranchName: 'Field Phlebotomist Cool Box #08',
        assignedPhlebotomistId: 'PH-204',
        assignedPhlebotomistName: 'Rahul Verma',
        collectionTime: now.subtract(const Duration(hours: 2)),
        temperatureStatus: '3.8°C (Cold Chain Intact)',
        notes: 'Sterile draw successful on first attempt. Placed in gel cold box.',
        events: [
          SampleEventModel(
            id: 'EV-INIT-01',
            sampleBarcode: 'SMP-77102',
            status: SampleStatus.collected,
            timestamp: now.subtract(const Duration(hours: 2)),
            actorId: 'PH-204',
            actorName: 'Rahul Verma (Phlebotomist)',
            actorRole: UserRole.phlebotomist,
            locationName: 'Villa 12, Palm Meadows, Sector 11',
            temperatureCelsius: 3.8,
            notes: 'Doorstep collection completed. Gel box sealed.',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    );

    // Initial temperature log
    _tempLogs.add({
      'timestamp': now.subtract(const Duration(hours: 1)),
      'temperature': 3.8,
      'actor': 'Rahul Verma',
      'notes': 'Periodic sensor ping from portable cold carrier box.',
    });
  }

  /// Returns all doorstep pickup orders assigned to the phlebotomist.
  Future<List<OrderModel>> getAssignedPickups(String phlebotomistId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _orderStore
        .where((o) =>
            o.assignedPhlebotomistId == phlebotomistId ||
            o.assignedPhlebotomistId == null)
        .toList();
  }

  /// Get specific order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final match = _orderStore.where((o) => o.id == orderId).toList();
    return match.isNotEmpty ? match.first : null;
  }

  /// Get all vials currently in phlebotomist's cold box
  Future<List<SampleModel>> getCollectedSamples(String phlebotomistId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sampleStore
        .where((s) => s.assignedPhlebotomistId == phlebotomistId)
        .toList();
  }

  /// Checks if a barcode is already bound to an active sample
  Future<bool> isBarcodeAlreadyUsed(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final clean = barcode.trim().toLowerCase();
    return _sampleStore.any((s) => s.barcode.toLowerCase() == clean);
  }

  /// Confirms on-site blood collection, binds barcode, logs GPS & cold box temperature
  Future<SampleModel> confirmCollection(PhlebotomistCollectionRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    await Future.delayed(const Duration(milliseconds: 400));

    final now = DateTime.now();

    // Check duplicate barcode
    final isDuplicate = _sampleStore.any((s) =>
        s.barcode.toLowerCase() == request.sampleBarcode.trim().toLowerCase());
    if (isDuplicate) {
      throw Exception(
        'Barcode "${request.sampleBarcode}" is already in use by another specimen. Please scan a fresh sterile tube.',
      );
    }

    // Find and update the order
    final orderIndex = _orderStore.indexWhere((o) => o.id == request.orderId);
    List<String> testNames = ['Blood Specimen'];
    if (orderIndex != -1) {
      final existingOrder = _orderStore[orderIndex];
      testNames = existingOrder.testNames;
      final updatedBarcodes = List<String>.from(existingOrder.sampleBarcodes)
        ..add(request.sampleBarcode.trim().toUpperCase());
      _orderStore[orderIndex] = existingOrder.copyWith(
        status: OrderStatus.completed,
        sampleBarcodes: updatedBarcodes,
      );
    }

    // Create the milestone event
    final event = SampleEventModel(
      id: 'EV-${DateTime.now().millisecondsSinceEpoch}',
      sampleBarcode: request.sampleBarcode.trim().toUpperCase(),
      status: SampleStatus.collected,
      timestamp: now,
      actorId: request.phlebotomistId,
      actorName: '${request.phlebotomistName} (Phlebotomist)',
      actorRole: UserRole.phlebotomist,
      locationName: request.locationAddress,
      latitude: request.latitude ?? 28.4595,
      longitude: request.longitude ?? 77.0266,
      temperatureCelsius: request.temperatureCelsius,
      notes: request.notes ?? 'Doorstep specimen drawn & sealed in gel cold box.',
    );

    // Create new sample in custody
    final sample = SampleModel(
      barcode: request.sampleBarcode.trim().toUpperCase(),
      orderId: request.orderId,
      patientId: request.patientId,
      patientName: request.patientName,
      testNames: testNames,
      vialType: request.vialType,
      status: SampleStatus.collected,
      currentBranchId: 'BR-004',
      currentBranchName: 'Field Phlebotomist Cool Box #08',
      assignedPhlebotomistId: request.phlebotomistId,
      assignedPhlebotomistName: request.phlebotomistName,
      collectionTime: now,
      temperatureStatus: '${request.temperatureCelsius.toStringAsFixed(1)}°C (Cold Chain Intact)',
      notes: request.notes,
      events: [event],
      createdAt: now,
    );

    _sampleStore.insert(0, sample);

    // Also record temperature history
    _tempLogs.insert(0, {
      'timestamp': now,
      'temperature': request.temperatureCelsius,
      'actor': request.phlebotomistName,
      'notes': 'Specimen ${sample.barcode} bound at doorstep.',
    });

    return sample;
  }

  /// Batch hand-off from phlebotomist to central branch reception / courier bag
  Future<void> handoverBatchToHub({
    required String phlebotomistId,
    required String branchId,
    required String branchName,
    required List<String> sampleBarcodes,
    required String receiverName,
    String? hubNotes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();

    for (final barcode in sampleBarcodes) {
      final idx = _sampleStore.indexWhere(
          (s) => s.barcode.toLowerCase() == barcode.toLowerCase());
      if (idx != -1) {
        final existing = _sampleStore[idx];
        final event = SampleEventModel(
          id: 'EV-${DateTime.now().millisecondsSinceEpoch}',
          sampleBarcode: barcode,
          status: SampleStatus.receivedAtBranch,
          timestamp: now,
          actorId: phlebotomistId,
          actorName: receiverName,
          actorRole: UserRole.frontDesk,
          locationName: branchName,
          temperatureCelsius: 4.0,
          notes: hubNotes ?? 'Batch courier intake verified at branch rack.',
        );

        _sampleStore[idx] = existing.copyWith(
          status: SampleStatus.receivedAtBranch,
          currentBranchId: branchId,
          currentBranchName: branchName,
          events: [...existing.events, event],
        );
      }
    }
  }

  /// Log cold box temperature
  Future<void> logColdBoxTemperature({
    required String phlebotomistId,
    required double temperature,
    required String notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tempLogs.insert(0, {
      'timestamp': DateTime.now(),
      'temperature': temperature,
      'actor': 'Phlebotomist ($phlebotomistId)',
      'notes': notes,
    });
  }

  /// Retrieve temperature logs
  List<Map<String, dynamic>> getTemperatureLogs() => List.unmodifiable(_tempLogs);
}
