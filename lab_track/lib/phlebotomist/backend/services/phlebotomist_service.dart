import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/sample_repository.dart';
import '../../../data/services/central_data_store.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../domain/enums/user_role.dart';
import '../models/phlebotomist_collection_request.dart';

/// Phlebotomist Backend API Service (Collection, Vial Barcoding & Cold-Chain Intake)
/// Connected to CentralDataStore to ensure real-time synchronization with Patient, Front Desk, Lab, & Admin.
class PhlebotomistService {
  final CentralDataStore _store = CentralDataStore.instance;
  final OrderRepository _orderRepository;
  final SampleRepository _sampleRepository;
  final FirebaseFirestore? _firestore;

  final List<Map<String, dynamic>> _sensorLogs = [];

  PhlebotomistService({
    OrderRepository? orderRepository,
    SampleRepository? sampleRepository,
    FirebaseFirestore? firestore,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _sampleRepository = sampleRepository ?? SampleRepository(),
        _firestore = firestore;

  /// Returns all doorstep pickup orders assigned to the phlebotomist.
  Future<List<OrderModel>> getAssignedPickups(String phlebotomistId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final matching = _store.orders.where((o) =>
        o.assignedPhlebotomistId == phlebotomistId ||
        o.assignedPhlebotomistId == null ||
        o.assignedPhlebotomistId!.isEmpty).toList();

    if (matching.isNotEmpty) return matching;

    // Fallback to repository if central store has no matching
    try {
      return await _orderRepository.watchPickupsForPhlebotomist(phlebotomistId).first;
    } catch (_) {
      return matching;
    }
  }

  /// Get specific order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    final o = _store.getOrder(orderId);
    if (o != null) return o;
    try {
      return await _orderRepository.getOrder(orderId);
    } catch (_) {
      return null;
    }
  }

  /// Get all vials currently in phlebotomist's custody
  Future<List<SampleModel>> getCollectedSamples(String phlebotomistId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final local = _store.samples.where((s) => s.currentCustodianId == phlebotomistId).toList();
    if (local.isNotEmpty) return local;

    if (_firestore != null) {
      try {
        final snap = await _firestore
            .collection('samples')
            .where('currentCustodianId', isEqualTo: phlebotomistId)
            .get();
        final list = snap.docs.map((doc) => SampleModel.fromMap(doc.data(), documentId: doc.id)).toList();
        return list;
      } catch (_) {}
    }
    return local;
  }

  /// Checks if a barcode is already bound to an active sample
  Future<bool> isBarcodeAlreadyUsed(String barcode) async {
    final s = _store.getSample(barcode.trim());
    if (s != null && s.status != SampleStatus.booked) return true;
    try {
      final sample = await _sampleRepository.getSample(barcode.trim());
      return sample != null && sample.status != SampleStatus.booked;
    } catch (_) {
      return false;
    }
  }

  /// Confirms on-site blood collection, binds barcode, logs GPS & cold box temperature
  Future<SampleModel> confirmCollection(PhlebotomistCollectionRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    final barcode = request.sampleBarcode.trim().toUpperCase();
    final now = DateTime.now();

    // Update CentralDataStore (propagates to Patient, Front Desk, Lab, & Admin)
    _store.confirmPhlebotomistCollection(
      orderId: request.orderId,
      sampleBarcode: barcode,
      tubeType: request.vialType,
      temperature: request.temperatureCelsius,
      phlebotomistId: request.phlebotomistId,
      phlebotomistName: request.phlebotomistName,
      locationName: request.locationAddress,
      notes: request.notes,
    );

    // Record local sensor telemetry
    _sensorLogs.insert(0, {
      'timestamp': now,
      'temperature': request.temperatureCelsius,
      'actor': request.phlebotomistName,
      'notes': 'Specimen $barcode bound at doorstep.',
    });

    // Background write to Firestore if available
    try {
      _sampleRepository.transitionSample(
        barcode: barcode,
        newStatus: SampleStatus.collected,
        actorId: request.phlebotomistId,
        actorRole: UserRole.phlebotomist,
        actorName: request.phlebotomistName,
        temperatureC: request.temperatureCelsius,
        note: request.notes,
      );
    } catch (_) {}

    return _store.getSample(barcode)!;
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
    _store.handoverBatchToHub(
      barcodes: sampleBarcodes,
      branchId: branchId,
      branchName: branchName,
      receiverName: receiverName,
    );

    // Background sync to Firestore
    for (final barcode in sampleBarcodes) {
      try {
        _sampleRepository.transitionSample(
          barcode: barcode,
          newStatus: SampleStatus.receivedAtBranch,
          actorId: phlebotomistId,
          actorRole: UserRole.phlebotomist,
          actorName: receiverName,
          branchId: branchId,
          note: hubNotes,
        );
      } catch (_) {}
    }
  }

  /// Log cold box temperature
  Future<void> logColdBoxTemperature({
    required String phlebotomistId,
    required double temperature,
    required String notes,
  }) async {
    _sensorLogs.insert(0, {
      'timestamp': DateTime.now(),
      'temperature': temperature,
      'actor': 'Phlebotomist ($phlebotomistId)',
      'notes': notes,
    });
  }

  /// Retrieve temperature logs
  List<Map<String, dynamic>> getTemperatureLogs() => List.unmodifiable(_sensorLogs);
}
