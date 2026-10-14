import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/enums/sample_status.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/state_machine/sample_state_machine.dart';
import '../models/sample_model.dart';
import '../models/sample_event_model.dart';

class SampleRepository {
  final FirebaseFirestore _firestore;

  SampleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<SampleModel>> watchSamplesByStatus(
    List<SampleStatus> statuses, {
    String? branchId,
  }) {
    if (statuses.isEmpty) {
      return Stream.value(<SampleModel>[]);
    }

    Query<Map<String, dynamic>> query = _firestore.collection('samples');

    if (statuses.length == 1) {
      query = query.where('status', isEqualTo: statuses.first.name);
    } else {
      query = query.where(
        'status',
        whereIn: statuses.take(10).map((s) => s.name).toList(),
      );
    }

    if (branchId != null && branchId.isNotEmpty) {
      query = query.where('currentBranchId', isEqualTo: branchId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SampleModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.lastEventAt ?? a.createdAt;
        final bDate = b.lastEventAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  Stream<SampleModel?> watchSample(String barcode) {
    return _firestore
        .collection('samples')
        .doc(barcode)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return SampleModel.fromMap(snapshot.data()!, documentId: snapshot.id);
    });
  }

  Stream<List<SampleEventModel>> watchEvents(String barcode) {
    return _firestore
        .collection('sample_events')
        .where('sampleBarcode', isEqualTo: barcode)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SampleEventModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  Future<SampleModel?> getSample(String barcode) async {
    final snapshot = await _firestore.collection('samples').doc(barcode).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return SampleModel.fromMap(snapshot.data()!, documentId: snapshot.id);
  }

  Future<void> createSample(SampleModel sample) async {
    await _firestore
        .collection('samples')
        .doc(sample.barcode)
        .set(sample.toMap());
  }

  Future<void> transitionSample({
    required String barcode,
    required SampleStatus newStatus,
    required String actorId,
    required UserRole actorRole,
    required String actorName,
    String? branchId,
    double? temperatureC,
    String? note,
  }) async {
    final sampleRef = _firestore.collection('samples').doc(barcode);
    final eventRef = _firestore.collection('sample_events').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sampleRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Sample with barcode "$barcode" does not exist in Firestore.');
      }

      final data = snapshot.data()!;
      final currentStatus = SampleStatus.fromString(data['status']?.toString());

      if (!SampleStateMachine.canTransition(currentStatus, newStatus)) {
        throw InvalidTransitionException(
          'Illegal state transition for sample $barcode: cannot move from "${currentStatus.name}" to "${newStatus.name}".',
        );
      }

      final sampleUpdates = <String, dynamic>{
        'status': newStatus.name,
        'currentCustodianId': actorId,
        'currentCustodianRole': actorRole.name,
        'lastEventAt': FieldValue.serverTimestamp(),
      };

      if (branchId != null && branchId.isNotEmpty) {
        sampleUpdates['currentBranchId'] = branchId;
      }
      if (temperatureC != null) {
        sampleUpdates['temperatureC'] = temperatureC;
      }
      if (newStatus == SampleStatus.collected && data['collectedAt'] == null) {
        sampleUpdates['collectedAt'] = FieldValue.serverTimestamp();
      }

      final eventData = <String, dynamic>{
        'sampleBarcode': barcode,
        'orderId': data['orderId']?.toString() ?? '',
        'fromStatus': currentStatus.name,
        'toStatus': newStatus.name,
        'actorId': actorId,
        'actorRole': actorRole.name,
        'actorName': actorName,
        'timestamp': FieldValue.serverTimestamp(),
        'branchId': branchId ?? data['currentBranchId']?.toString(),
        if (temperatureC != null) 'temperatureC': temperatureC,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      transaction.update(sampleRef, sampleUpdates);
      transaction.set(eventRef, eventData);
    });
  }
}
