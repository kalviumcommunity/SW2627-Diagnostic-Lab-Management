import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/enums/sample_status.dart';
import '../models/order_model.dart';
import '../models/sample_model.dart';
import '../models/report_model.dart';

class OrderRepository {
  final FirebaseFirestore? _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<List<OrderModel>> watchOrdersForPatient(String patientId) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(<OrderModel>[]);
    }
    return firestore
        .collection('orders')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<OrderModel>> watchPickupsForPhlebotomist(String phlebotomistId) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(<OrderModel>[]);
    }
    return firestore.collection('orders').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), documentId: doc.id))
          .where((order) =>
              order.assignedPhlebotomistId == phlebotomistId ||
              order.assignedPhlebotomistId == null ||
              order.assignedPhlebotomistId!.isEmpty)
          .toList();
      list.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      return list;
    });
  }

  Future<String> createOrder(OrderModel order) async {
    final orderId = order.id.isNotEmpty
        ? order.id
        : 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final firestore = _firestore;
    if (firestore == null) {
      return orderId;
    }

    final finalOrder = order.copyWith(id: orderId);
    await firestore
        .collection('orders')
        .doc(orderId)
        .set(finalOrder.toMap());

    // Register initial sample documents if barcodes are present
    for (final barcode in finalOrder.sampleBarcodes) {
      final sampleRef = firestore.collection('samples').doc(barcode);
      final snap = await sampleRef.get();
      if (!snap.exists) {
        final sample = SampleModel(
          barcode: barcode,
          orderId: orderId,
          patientId: finalOrder.patientId,
          patientName: finalOrder.patientName,
          patientPhone: finalOrder.patientPhone,
          tubeType: 'Standard Collection Tube',
          status: SampleStatus.booked,
          currentBranchId: finalOrder.branchId,
          currentBranchName: finalOrder.branchName,
          assignedPhlebotomistName: finalOrder.assignedPhlebotomistName,
          createdAt: finalOrder.createdAt,
          testNames: finalOrder.testNames,
        );
        await sampleRef.set(sample.toMap());
      }
    }

    return orderId;
  }

  Future<List<SampleModel>> searchSamples(String query) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      final snap = await firestore.collection('samples').limit(30).get();
      final list = snap.docs
          .map((doc) => SampleModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) =>
          (b.lastEventAt ?? b.createdAt).compareTo(a.lastEventAt ?? a.createdAt));
      return list;
    }

    final snap = await firestore
        .collection('samples')
        .where('searchKeywords', arrayContains: clean)
        .limit(30)
        .get();

    final list = snap.docs
        .map((doc) => SampleModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
    list.sort((a, b) =>
        (b.lastEventAt ?? b.createdAt).compareTo(a.lastEventAt ?? a.createdAt));
    return list;
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    final snap = await firestore.collection('orders').doc(orderId).get();
    if (!snap.exists || snap.data() == null) return null;
    return OrderModel.fromMap(snap.data()!, documentId: snap.id);
  }

  Future<void> updateOrder(OrderModel order) async {
    final firestore = _firestore;
    if (firestore == null) return;

    await firestore.collection('orders').doc(order.id).set(
          order.toMap(),
          SetOptions(merge: true),
        );
  }

  Stream<List<ReportModel>> watchReportsForPatient(String patientId) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(<ReportModel>[]);
    }

    return firestore
        .collection('reports')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
      list.sort((a, b) => (b.uploadedAt ?? b.createdAt).compareTo(a.uploadedAt ?? a.createdAt));
      return list;
    });
  }

  Future<ReportModel?> getReportByOrderId(String orderId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    final snap = await firestore
        .collection('reports')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ReportModel.fromMap(snap.docs.first.data(), documentId: snap.docs.first.id);
  }
}
