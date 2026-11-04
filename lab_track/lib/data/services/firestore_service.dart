import 'package:cloud_firestore/cloud_firestore.dart';

/// Database service wrapping Firebase Cloud Firestore collections.
class FirestoreService {
  final FirebaseFirestore? _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get firestore => _firestore;

  CollectionReference<Map<String, dynamic>>? get ordersRef =>
      _firestore?.collection('orders');

  CollectionReference<Map<String, dynamic>>? get samplesRef =>
      _firestore?.collection('samples');

  CollectionReference<Map<String, dynamic>>? get reportsRef =>
      _firestore?.collection('reports');

  CollectionReference<Map<String, dynamic>>? get usersRef =>
      _firestore?.collection('users');

  CollectionReference<Map<String, dynamic>>? get branchesRef =>
      _firestore?.collection('branches');
}
