import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/sample_model.dart';
import '../../../data/models/sample_event_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/sample_repository.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/sample_status.dart';
import '../../../domain/enums/user_role.dart';
import '../models/phlebotomist_collection_request.dart';

/// Phlebotomist Backend API Service (Collection, Vial Barcoding & Cold-Chain Intake)
/// Backed by Cloud Firestore via OrderRepository and SampleRepository.
class PhlebotomistService {
  final OrderRepository _orderRepository;
  final SampleRepository _sampleRepository;
  final FirebaseFirestore _firestore;

  final List<Map<String, dynamic>> _sensorLogs = [];

  PhlebotomistService({
    OrderRepository? orderRepository,
    SampleRepository? sampleRepository,
    FirebaseFirestore? firestore,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _sampleRepository = sampleRepository ?? SampleRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns all doorstep pickup orders assigned to the phlebotomist.
  Future<List<OrderModel>> getAssignedPickups(String phlebotomistId) async {
    return _orderRepository.watchPickupsForPhlebotomist(phlebotomistId).first;
  }

  /// Get specific order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    return _orderRepository.getOrder(orderId);
  }

  /// Get all vials currently in phlebotomist's custody
  Future<List<SampleModel>> getCollectedSamples(String phlebotomistId) async {
    final snap = await _firestore
        .collection('samples')
        .where('currentCustodianId', isEqualTo: phlebotomistId)
        .get();

    final samples = snap.docs
        .map((doc) => SampleModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
    samples.sort((a, b) =>
        (b.lastEventAt ?? b.createdAt).compareTo(a.lastEventAt ?? a.createdAt));
    return samples;
  }

  /// Checks if a barcode is already bound to an active sample
  Future<bool> isBarcodeAlreadyUsed(String barcode) async {
    final sample = await _sampleRepository.getSample(barcode.trim());
    return sample != null && sample.status != SampleStatus.booked;
  }

  /// Confirms on-site blood collection, binds barcode, logs GPS & cold box temperature
  Future<SampleModel> confirmCollection(PhlebotomistCollectionRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    final barcode = request.sampleBarcode.trim().toUpperCase();
    final existingSample = await _sampleRepository.getSample(barcode);

    if (existingSample != null &&
        existingSample.status != SampleStatus.booked &&
        existingSample.orderId != request.orderId) {
      throw Exception(
        'Barcode "$barcode" is already in use by another specimen. Please scan a fresh sterile tube.',
      );
    }

    final now = DateTime.now();

    // Find and update the order
    final existingOrder = await _orderRepository.getOrder(request.orderId);
    List<String> testNames = ['Blood Specimen'];

    if (existingOrder != null) {
      testNames = existingOrder.testNames;
      final updatedBarcodes = List<String>.from(existingOrder.sampleBarcodes);
      if (!updatedBarcodes.contains(barcode)) {
        updatedBarcodes.add(barcode);
      }
      final updatedOrder = existingOrder.copyWith(
        status: OrderStatus.inProgress,
        sampleBarcodes: updatedBarcodes,
        updatedAt: now,
      );
      await _orderRepository.updateOrder(updatedOrder);
    }

    SampleModel resultingSample;

    if (existingSample != null) {
      // Transition through state machine and write transactional event
      await _sampleRepository.transitionSample(
        barcode: barcode,
        newStatus: SampleStatus.collected,
        actorId: request.phlebotomistId,
        actorRole: UserRole.phlebotomist,
        actorName: request.phlebotomistName,
        branchId: 'BR-004',
        temperatureC: request.temperatureCelsius,
        note: request.notes ?? 'Doorstep specimen drawn & sealed in gel cold carrier.',
      );
      resultingSample = (await _sampleRepository.getSample(barcode))!;
    } else {
      // Create new sample in Firestore
      final initialEvent = SampleEventModel(
        id: 'EV-${DateTime.now().millisecondsSinceEpoch}',
        sampleBarcode: barcode,
        orderId: request.orderId,
        fromStatus: null,
        toStatus: SampleStatus.collected,
        timestamp: now,
        actorId: request.phlebotomistId,
        actorName: '${request.phlebotomistName} (Phlebotomist)',
        actorRole: UserRole.phlebotomist,
        branchId: request.locationAddress,
        latitude: request.latitude ?? 28.4595,
        longitude: request.longitude ?? 77.0266,
        temperatureC: request.temperatureCelsius,
        note: request.notes ?? 'Doorstep specimen drawn & sealed in gel cold box.',
      );

      final sample = SampleModel(
        barcode: barcode,
        orderId: request.orderId,
        patientId: request.patientId,
        patientName: request.patientName,
        tubeType: request.vialType,
        status: SampleStatus.collected,
        currentCustodianId: request.phlebotomistId,
        currentCustodianRole: UserRole.phlebotomist.name,
        currentBranchId: 'BR-004',
        currentBranchName: 'Field Phlebotomist Cool Box #08',
        assignedPhlebotomistName: request.phlebotomistName,
        collectedAt: now,
        temperatureC: request.temperatureCelsius,
        lastEventAt: now,
        createdAt: now,
        notes: request.notes,
        testNames: testNames,
        events: [initialEvent],
      );

      await _sampleRepository.createSample(sample);
      await _firestore.collection('sample_events').doc(initialEvent.id).set(initialEvent.toMap());
      resultingSample = sample;
    }

    // Record local sensor telemetry
    _sensorLogs.insert(0, {
      'timestamp': now,
      'temperature': request.temperatureCelsius,
      'actor': request.phlebotomistName,
      'notes': 'Specimen $barcode bound at doorstep.',
    });

    return resultingSample;
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
    for (final barcode in sampleBarcodes) {
      await _sampleRepository.transitionSample(
        barcode: barcode,
        newStatus: SampleStatus.inTransit,
        actorId: phlebotomistId,
        actorRole: UserRole.phlebotomist,
        actorName: receiverName,
        branchId: branchId,
        note: hubNotes ?? 'Batch courier intake verified at branch rack.',
      );
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
