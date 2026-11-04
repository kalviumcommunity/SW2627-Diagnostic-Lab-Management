import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_mode.dart';
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
import '../../data/models/user_model.dart';
import '../../data/mock/seed_users.dart';
import 'cross_tab_sync.dart';
import 'scanner_service.dart';

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
  final List<UserModel> _users = [];

  bool _initialized = false;
  FirebaseFirestore? _firestore;
  bool _firestoreSyncStarted = false;
  bool _isFirestoreConnected = false;
  final List<StreamSubscription> _firestoreSubscriptions = [];

  CentralDataStore._internal() {
    _ensureInitialized();
  }

  bool get isFirestoreConnected => _isFirestoreConnected;

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
  List<UserModel> get users => List.unmodifiable(_users);
  List<UserModel> get patients => _users.where((u) => u.isPatient).toList();

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    _initFirestoreSync();
    _initCrossTabSync();

    // Synthetic fixtures must never be mixed with a live data source.
    if (!isDemoMode) return;

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

    // 2. Seed Presentation Users & Staff (Virender, Praveen, Aryan, Ritu mam)
    _users.addAll(kSeedUsers);

    for (final u in kSeedUsers) {
      if (!u.isPatient) {
        _staff.add(
          userToStaffAllocation(
            u,
            assignedBranchName: u.assignedBranchId == 'branch-spoke-01'
                ? 'Downtown Spoke Center #1'
                : 'Apex Central Reference Laboratory',
          ),
        );
      }
    }

    // 3. ZERO PREVIOUS ORDERS / SAMPLES / REPORTS (Clean Slate for Live Demonstration)
    // Orders, Samples, and Reports are populated dynamically in real-time when Virender books a test!

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

  /// Cancels all active Cloud Firestore listeners and resets sync state
  void cancelFirestoreSubscriptions() {
    for (final s in _firestoreSubscriptions) {
      s.cancel();
    }
    _firestoreSubscriptions.clear();
    _firestoreSyncStarted = false;
    _isFirestoreConnected = false;
  }

  void clearAllDataForTesting() {
    _orders.clear();
    _samples.clear();
    _reports.clear();
    notifyListeners();
  }

  /// Explicitly triggers or verifies Cloud Firestore connection
  void connectToFirestore() {
    _initFirestoreSync();
  }

  FirebaseFirestore? _getOrInitFirestore() {
    if (_firestore != null) return _firestore;
    try {
      _firestore = FirebaseFirestore.instance;
      if (!_firestoreSyncStarted) {
        _firestoreSyncStarted = true;
        _subscribeToFirestoreCollections();
      }
      return _firestore;
    } catch (e) {
      return null;
    }
  }

  void _initFirestoreSync() {
    try {
      _firestore = FirebaseFirestore.instance;
      if (!_firestoreSyncStarted) {
        _firestoreSyncStarted = true;
        _subscribeToFirestoreCollections();
      }
    } catch (e) {
      debugPrint('CentralDataStore: Firestore running in offline mode ($e)');
    }
  }

  void _subscribeToFirestoreCollections() {
    final fs = _firestore;
    if (fs == null) return;

    for (final s in _firestoreSubscriptions) {
      s.cancel();
    }
    _firestoreSubscriptions.clear();

    // 1. Orders collection real-time listener
    _firestoreSubscriptions.add(fs.collection('orders').snapshots().listen((snapshot) {
      for (final doc in snapshot.docs) {
        try {
          final order = OrderModel.fromMap(doc.data(), documentId: doc.id);
          final idx = _orders.indexWhere((o) => o.id == order.id);
          if (idx != -1) {
            _orders[idx] = order;
          } else {
            _orders.insert(0, order);
          }
        } catch (e) {
          debugPrint('CentralDataStore: Error parsing order ${doc.id}: $e');
        }
      }
      _isFirestoreConnected = true;
      notifyListeners();
    }, onError: (e) {
      debugPrint('CentralDataStore: Firestore orders listener notice: $e');
    }));

    // 2. Samples collection real-time listener
    _firestoreSubscriptions.add(fs.collection('samples').snapshots().listen((snapshot) {
      for (final doc in snapshot.docs) {
        try {
          final sample = SampleModel.fromMap(doc.data(), documentId: doc.id);
          final idx = _samples.indexWhere((s) => s.barcode.toUpperCase() == sample.barcode.toUpperCase());
          if (idx != -1) {
            _samples[idx] = sample;
          } else {
            _samples.insert(0, sample);
          }
        } catch (e) {
          debugPrint('CentralDataStore: Error parsing sample ${doc.id}: $e');
        }
      }
      _isFirestoreConnected = true;
      notifyListeners();
    }, onError: (e) {
      debugPrint('CentralDataStore: Firestore samples listener notice: $e');
    }));

    // 3. Reports collection real-time listener
    _firestoreSubscriptions.add(fs.collection('reports').snapshots().listen((snapshot) {
      for (final doc in snapshot.docs) {
        try {
          final report = ReportModel.fromMap(doc.data(), documentId: doc.id);
          final idx = _reports.indexWhere((r) => r.id == report.id);
          if (idx != -1) {
            _reports[idx] = report;
          } else {
            _reports.insert(0, report);
          }
        } catch (e) {
          debugPrint('CentralDataStore: Error parsing report ${doc.id}: $e');
        }
      }
      _isFirestoreConnected = true;
      notifyListeners();
    }, onError: (e) {
      debugPrint('CentralDataStore: Firestore reports listener notice: $e');
    }));

    // 4. Users collection real-time listener (Patients & Staff)
    _firestoreSubscriptions.add(fs.collection('users').snapshots().listen((snapshot) {
      for (final doc in snapshot.docs) {
        try {
          final user = UserModel.fromMap(doc.data(), documentId: doc.id);
          final idx = _users.indexWhere((u) => u.id == user.id || (user.email != null && user.email!.isNotEmpty && u.email == user.email));
          if (idx != -1) {
            _users[idx] = user;
          } else {
            _users.insert(0, user);
          }

          // Automatically sync staff roster so Admin updates in real-time
          final sIdx = _staff.indexWhere((s) => s.id == user.id || (user.email != null && user.email!.isNotEmpty && s.email == user.email));
          final staffMember = userToStaffAllocation(
            user,
            assignedBranchName: _branches.firstWhere(
              (b) => b.id == user.assignedBranchId,
              orElse: () => _branches.first,
            ).name,
          );
          if (sIdx != -1) {
            _staff[sIdx] = staffMember;
          } else {
            _staff.insert(0, staffMember);
          }
        } catch (e) {
          debugPrint('CentralDataStore: Error parsing user ${doc.id}: $e');
        }
      }
      _isFirestoreConnected = true;
      notifyListeners();
    }, onError: (e) {
      debugPrint('CentralDataStore: Firestore users listener notice: $e');
    }));

    // 5. Branches collection real-time listener
    _firestoreSubscriptions.add(fs.collection('branches').snapshots().listen((snapshot) {
      for (final doc in snapshot.docs) {
        try {
          final branch = BranchModel.fromMap(doc.data(), documentId: doc.id);
          final idx = _branches.indexWhere((b) => b.id == branch.id);
          if (idx != -1) {
            _branches[idx] = branch;
          } else {
            _branches.add(branch);
          }
        } catch (e) {
          debugPrint('CentralDataStore: Error parsing branch ${doc.id}: $e');
        }
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('CentralDataStore: Firestore branches listener notice: $e');
    }));
  }

  void _syncOrderToFirestore(OrderModel order) {
    final fs = _getOrInitFirestore();
    if (fs == null) return;
    try {
      fs.collection('orders').doc(order.id).set(order.toMap(), SetOptions(merge: true)).catchError((e) {
        debugPrint('Firestore order sync warning: $e');
      });
    } catch (e) {
      debugPrint('Firestore order sync error: $e');
    }
  }

  void _syncSampleToFirestore(SampleModel sample) {
    final fs = _getOrInitFirestore();
    if (fs == null) return;
    try {
      fs.collection('samples').doc(sample.barcode).set(sample.toMap(), SetOptions(merge: true)).catchError((e) {
        debugPrint('Firestore sample sync warning: $e');
      });
      // Also sync milestone events to immutable sample_events collection
      for (final event in sample.events) {
        fs.collection('sample_events').doc(event.id).set(event.toMap(), SetOptions(merge: true)).catchError((e) {
          debugPrint('Firestore sample event sync warning: $e');
        });
      }
    } catch (e) {
      debugPrint('Firestore sample sync error: $e');
    }
  }

  void _syncReportToFirestore(ReportModel report) {
    final fs = _getOrInitFirestore();
    if (fs == null) return;
    try {
      fs.collection('reports').doc(report.id).set(report.toMap(), SetOptions(merge: true)).catchError((e) {
        debugPrint('Firestore report sync warning: $e');
      });
    } catch (e) {
      debugPrint('Firestore report sync error: $e');
    }
  }

  // ==========================================================
  // Real-Time Cross-Tab Synchronization (Web Multi-Tab Demo)
  // ==========================================================

  void _initCrossTabSync() {
    try {
      CrossTabSync.init((data) {
        final type = data['type'] as String?;
        final payload = data['payload'] as Map<String, dynamic>?;
        if (payload == null) return;

        if (type == 'sync_order') {
          try {
            final order = OrderModel.fromMap(payload, documentId: payload['id']?.toString());
            final idx = _orders.indexWhere((o) => o.id == order.id);
            if (idx != -1) {
              _orders[idx] = order;
            } else {
              _orders.insert(0, order);
            }
            notifyListeners();
          } catch (e) {
            debugPrint('CentralDataStore cross-tab sync_order error: $e');
          }
        } else if (type == 'sync_sample') {
          try {
            final sample = SampleModel.fromMap(payload, documentId: payload['barcode']?.toString());
            final idx = _samples.indexWhere((s) => s.barcode.toUpperCase() == sample.barcode.toUpperCase());
            if (idx != -1) {
              _samples[idx] = sample;
            } else {
              _samples.insert(0, sample);
            }
            notifyListeners();
          } catch (e) {
            debugPrint('CentralDataStore cross-tab sync_sample error: $e');
          }
        } else if (type == 'sync_report') {
          try {
            final report = ReportModel.fromMap(payload, documentId: payload['id']?.toString());
            final idx = _reports.indexWhere((r) => r.id == report.id);
            if (idx != -1) {
              _reports[idx] = report;
            } else {
              _reports.insert(0, report);
            }
            notifyListeners();
          } catch (e) {
            debugPrint('CentralDataStore cross-tab sync_report error: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('CentralDataStore _initCrossTabSync error: $e');
    }
  }

  dynamic _deepCleanForJson(dynamic value) {
    if (value == null) return null;
    if (value is num || value is bool || value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is List) return value.map(_deepCleanForJson).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _deepCleanForJson(v)));
    }
    return value.toString();
  }

  Map<String, dynamic> _orderToSyncJson(OrderModel order) {
    final map = Map<String, dynamic>.from(_deepCleanForJson(order.toMap()) as Map);
    map['id'] = order.id;
    return map;
  }

  Map<String, dynamic> _sampleToSyncJson(SampleModel sample) {
    final map = Map<String, dynamic>.from(_deepCleanForJson(sample.toMap()) as Map);
    map['barcode'] = sample.barcode;
    return map;
  }

  Map<String, dynamic> _reportToSyncJson(ReportModel report) {
    final map = Map<String, dynamic>.from(_deepCleanForJson(report.toMap()) as Map);
    map['id'] = report.id;
    return map;
  }

  // ==========================================================
  // Cross-Role Mutation Methods (Auto-Synchronized across roles)
  // ==========================================================

  /// 1. Patient or Front Desk creates a new booking order
  void createOrder(OrderModel order) {
    _orders.insert(0, order);
    _syncOrderToFirestore(order);
    CrossTabSync.broadcast('sync_order', _orderToSyncJson(order));

    // If barcodes are specified or generate default sample
    for (final barcode in order.sampleBarcodes) {
      if (_samples.any((s) => s.barcode.toUpperCase() == barcode.toUpperCase())) continue;
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

  /// 1.5 Phlebotomist verifies the patient's doorstep appointment pass
  OrderModel? verifyPatientDoorstepPass({
    required String orderId,
    String phlebotomistId = 'PH-PRAVEEN',
    String phlebotomistName = 'Praveen',
  }) {
    final now = DateTime.now();
    String cleanOrderId = orderId.trim();
    if (ScannerService.isAppointmentQr(cleanOrderId)) {
      final parsed = ScannerService.parseAppointmentQr(cleanOrderId);
      if (parsed != null && parsed.orderId.isNotEmpty) {
        cleanOrderId = parsed.orderId;
      }
    } else {
      final orderRegex = RegExp(r'\b(ORD-[A-Z0-9]+(?:-[A-Z0-9]+)*)\b', caseSensitive: false);
      final match = orderRegex.firstMatch(cleanOrderId);
      if (match != null) {
        cleanOrderId = match.group(1)!.toUpperCase();
      }
    }

    var oIdx = _orders.indexWhere((o) => o.id.toUpperCase() == cleanOrderId.toUpperCase());
    if (oIdx == -1) {
      final parsed = ScannerService.parseAppointmentQr(orderId);
      if (parsed != null && parsed.patientId.isNotEmpty) {
        oIdx = _orders.indexWhere((o) => o.patientId.toUpperCase() == parsed.patientId.toUpperCase());
      }
    }
    if (oIdx == -1 && _orders.isNotEmpty) {
      oIdx = _orders.indexWhere((o) => o.status != OrderStatus.completed);
    }
    if (oIdx == -1) {
      return null;
    }

    final existing = _orders[oIdx];
    final updated = existing.copyWith(
      doorstepVerifiedAt: now,
      status: OrderStatus.inProgress,
      assignedPhlebotomistId: phlebotomistId,
      assignedPhlebotomistName: phlebotomistName,
      updatedAt: now,
    );

    _orders[oIdx] = updated;
    _syncOrderToFirestore(updated);

    CrossTabSync.broadcast('sync_order', _orderToSyncJson(updated));
    CrossTabSync.broadcast('doorstep_verified', {
      'orderId': updated.id,
      'patientId': updated.patientId,
      'patientName': updated.patientName,
      'phlebotomistId': phlebotomistId,
      'phlebotomistName': phlebotomistName,
      'verifiedAt': now.toIso8601String(),
    });

    notifyListeners();
    return updated;
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
    if (oIdx == -1) throw Exception('Order not found.');
    final existingSample = getSample(sampleBarcode);
    if (existingSample != null &&
        (existingSample.orderId != orderId || existingSample.status != SampleStatus.booked)) {
      throw Exception('Barcode is already assigned to another sample.');
    }
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
      _syncOrderToFirestore(_orders[oIdx]);
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
      _syncSampleToFirestore(_samples[sIdx]);
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
      _syncSampleToFirestore(newSample);
    }

    if (oIdx != -1) {
      CrossTabSync.broadcast('sync_order', _orderToSyncJson(_orders[oIdx]));
    }
    final sUpdatedIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == sampleBarcode.toUpperCase());
    if (sUpdatedIdx != -1) {
      CrossTabSync.broadcast('sync_sample', _sampleToSyncJson(_samples[sUpdatedIdx]));
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
        _syncSampleToFirestore(_samples[sIdx]);
        CrossTabSync.broadcast('sync_sample', _sampleToSyncJson(_samples[sIdx]));
      }
    }
    notifyListeners();
  }

  /// 4. Lab Tech accessions incoming specimen into Central Lab
  SampleModel? accessionSpecimen({
    required String barcode,
    String? rackId,
    String? notes,
    String technicianName = 'Aryan (#LAB-ARYAN)',
  }) {
    final now = DateTime.now();

    // Check if a batch handover QR code was scanned
    if (ScannerService.isHandoverQr(barcode)) {
      final handover = ScannerService.parseHandoverQr(barcode);
      if (handover != null && handover.sampleBarcodes.isNotEmpty) {
        SampleModel? lastAccessioned;
        for (final b in handover.sampleBarcodes) {
          try {
            lastAccessioned = accessionSpecimen(
              barcode: b,
              rackId: rackId,
              notes: notes ?? 'Handover from ' + handover.senderName + '. Temp: ' + (handover.temperatureC ?? 4.2).toString() + '°C',
              technicianName: technicianName,
            );
          } catch (_) {}
        }
        return lastAccessioned;
      }
    }

    String cleanBarcode = barcode.trim().toUpperCase();
    final directMatch = RegExp(r'\b(SMP-[A-Z0-9]+(?:-[A-Z0-9]+)*)\b', caseSensitive: false).firstMatch(cleanBarcode);
    if (directMatch != null) {
      cleanBarcode = directMatch.group(1)!.toUpperCase();
    }

    var sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == cleanBarcode);
    if (sIdx == -1) {
      sIdx = _samples.indexWhere((s) => s.orderId.toUpperCase() == cleanBarcode);
    }
    if (sIdx == -1) {
      throw Exception('Sample "$barcode" not found in custody queue.');
    }
    if (_samples[sIdx].status == SampleStatus.rejected ||
        _samples[sIdx].status == SampleStatus.reportReady ||
        _samples[sIdx].status == SampleStatus.delivered) {
      throw Exception('This sample cannot be accessioned.');
    }

    final s = _samples[sIdx];
    final actualBarcode = s.barcode;

    final milestone = SampleEventModel(
      id: 'EV-ACC-$actualBarcode-${now.millisecondsSinceEpoch}',
      sampleBarcode: actualBarcode,
      toStatus: SampleStatus.receivedAtLab,
      actorId: 'LAB-ARYAN',
      actorName: technicianName,
      actorRole: UserRole.labTechnician,
      timestamp: now,
      branchId: 'Apex Central Reference Laboratory',
      temperatureC: s.temperatureC ?? 4.2,
      note: notes ?? 'Received from Phlebotomist Praveen. Cold chain verified intact.',
    );

    final events = List<SampleEventModel>.from(s.events)..add(milestone);
    final updatedSample = s.copyWith(
      status: SampleStatus.receivedAtLab,
      currentCustodianId: 'LAB-ARYAN',
      currentCustodianRole: 'Lab Technician',
      currentBranchId: 'branch-apex-hq',
      currentBranchName: 'Apex Central Reference Laboratory',
      temperatureC: s.temperatureC ?? 4.2,
      notes: notes ?? s.notes,
      events: events,
      lastEventAt: now,
    );

    _samples[sIdx] = updatedSample;
    _syncSampleToFirestore(updatedSample);
    CrossTabSync.broadcast('sync_sample', _sampleToSyncJson(updatedSample));
    CrossTabSync.broadcast('sample_accessioned', {
      'barcode': actualBarcode,
      'orderId': updatedSample.orderId,
      'patientName': updatedSample.patientName,
      'technicianName': technicianName,
      'temperatureC': updatedSample.temperatureC,
      'accessionedAt': now.toIso8601String(),
    });

    if (rackId != null && rackId.isNotEmpty) {
      assignToRack(barcode: actualBarcode, rackId: rackId);
    } else {
      notifyListeners();
    }

    return updatedSample;
  }

  /// 5. Assign sample to automated analyzer rack (Status: Processing)
  void assignToRack({
    required String barcode,
    required String rackId,
  }) {
    final now = DateTime.now();
    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == barcode.toUpperCase());
    final rIdx = _racks.indexWhere((r) => r.id == rackId);
    if (sIdx == -1 || rIdx == -1) throw Exception('Sample or rack not found.');
    if (_samples[sIdx].status != SampleStatus.receivedAtLab &&
        _samples[sIdx].status != SampleStatus.processing) {
      throw Exception('Only accessioned samples can be assigned to a rack.');
    }
    if (!_racks[rIdx].sampleBarcodes.contains(barcode.toUpperCase()) &&
        _racks[rIdx].sampleBarcodes.length >= _racks[rIdx].capacity) {
      throw Exception('Rack is full.');
    }
    if (_racks.any((rack) => rack.id != rackId && rack.sampleBarcodes.contains(barcode.toUpperCase()))) {
      throw Exception('Sample is already assigned to another rack.');
    }
    if (sIdx != -1) {
      final s = _samples[sIdx];
      final milestone = SampleEventModel(
        id: 'EV-RACK-$barcode-${now.millisecondsSinceEpoch}',
        sampleBarcode: barcode,
        toStatus: SampleStatus.processing,
        actorId: 'LAB-ARYAN',
        actorName: 'Aryan',
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
      _syncSampleToFirestore(_samples[sIdx]);
    }

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
    if (sIdx == -1) throw Exception('Sample not found.');
    final sample = _samples[sIdx];
    if (sample.status == SampleStatus.rejected) throw Exception('Rejected samples cannot be reported.');
    if (parameters.isEmpty || parameters.any((p) => p.name.trim().isEmpty || p.value.trim().isEmpty)) {
      throw Exception('Each result needs a parameter name and measured value.');
    }

    final effectiveTestName = testName ?? (sample.testNames.isNotEmpty ? sample.testNames.first : 'Diagnostic Panel');
    final patientId = sample.patientId;
    final patientName = sample.patientName;
    final orderId = sample.orderId;

    final rIdx = _reports.indexWhere((r) => r.sampleBarcode.toUpperCase() == sampleBarcode.toUpperCase() && r.testName == effectiveTestName);
    ReportModel savedReport;
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
        uploadedById: 'Aryan (#LAB-ARYAN)',
        pathologistName: existing.pathologistName,
        status: 'Pending Authorization',
        isReady: false,
        testResults: parameters,
        createdAt: existing.createdAt,
      );
      _reports[rIdx] = updated;
      _syncReportToFirestore(updated);
      CrossTabSync.broadcast('sync_report', _reportToSyncJson(updated));
      savedReport = updated;
    } else {
      final newReport = ReportModel(
        id: 'REP-${now.millisecondsSinceEpoch}',
        orderId: orderId,
        sampleBarcode: sampleBarcode.toUpperCase(),
        patientId: patientId,
        patientName: patientName,
        testName: effectiveTestName,
        branchName: 'Apex Central Reference Laboratory',
        uploadedById: 'Aryan (#LAB-ARYAN)',
        status: 'Pending Authorization',
        isReady: false,
        testResults: parameters,
        createdAt: now,
      );
      _reports.insert(0, newReport);
      _syncReportToFirestore(newReport);
      CrossTabSync.broadcast('sync_report', _reportToSyncJson(newReport));
      savedReport = newReport;
    }

    final s = _samples[sIdx];
    final milestone = SampleEventModel(
      id: 'EV-RES-$sampleBarcode-${now.millisecondsSinceEpoch}',
      sampleBarcode: sampleBarcode,
      toStatus: SampleStatus.processing,
      actorId: 'LAB-ARYAN',
      actorName: 'Aryan (#LAB-ARYAN)',
      actorRole: UserRole.labTechnician,
      timestamp: now,
      branchId: 'Apex Central Reference Laboratory',
      note: 'Analytical findings recorded for $effectiveTestName (${parameters.length} parameters). Forwarded for Pathologist review.',
    );
    final events = List<SampleEventModel>.from(s.events)..add(milestone);
    _samples[sIdx] = s.copyWith(
      status: SampleStatus.processing,
      events: events,
      lastEventAt: now,
    );
    _syncSampleToFirestore(_samples[sIdx]);
    CrossTabSync.broadcast('sync_sample', _sampleToSyncJson(_samples[sIdx]));

    notifyListeners();
    return savedReport;
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
    final sample = getSample(rep.sampleBarcode);
    if (sample == null || sample.status == SampleStatus.rejected) {
      throw Exception('A rejected or missing sample cannot be authorized.');
    }
    if (pathologistName.trim().isEmpty) throw Exception('A verifier name is required.');
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
    _syncReportToFirestore(verified);
    CrossTabSync.broadcast('sync_report', _reportToSyncJson(verified));

    // Transition Sample to reportReady
    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == rep.sampleBarcode.toUpperCase());
    if (sIdx != -1 && _samples[sIdx].testNames.every((name) =>
        _reports.any((report) => report.sampleBarcode.toUpperCase() == rep.sampleBarcode.toUpperCase() &&
            report.testName == name && report.isReady))) {
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
      _syncSampleToFirestore(_samples[sIdx]);
    }

    // Transition Order to completed
    final oIdx = _orders.indexWhere((o) => o.id == rep.orderId);
    if (oIdx != -1 && _orders[oIdx].sampleBarcodes.every((barcode) =>
        _samples.any((sample) => sample.barcode.toUpperCase() == barcode.toUpperCase() && sample.status == SampleStatus.reportReady))) {
      _orders[oIdx] = _orders[oIdx].copyWith(status: OrderStatus.completed);
      _syncOrderToFirestore(_orders[oIdx]);
    }

    if (sIdx != -1) {
      CrossTabSync.broadcast('sync_sample', _sampleToSyncJson(_samples[sIdx]));
    }
    if (oIdx != -1) {
      CrossTabSync.broadcast('sync_order', _orderToSyncJson(_orders[oIdx]));
    }

    notifyListeners();
    return verified;
  }

  /// 8. QC Specimen Rejection (Flags failure & triggers recollection)
  QcInspectionModel recordQcRejection({
    required String barcode,
    required String rejectionReason,
    String? clinicalNotes,
    String technicianName = 'Aryan (#LAB-ARYAN)',
  }) {
    final now = DateTime.now();
    String patientName = 'Patient';
    String testName = 'Diagnostic Panel';

    final sIdx = _samples.indexWhere((s) => s.barcode.toUpperCase() == barcode.toUpperCase());
    if (sIdx == -1) throw Exception('Sample not found.');
    if (_samples[sIdx].status == SampleStatus.rejected ||
        _samples[sIdx].status == SampleStatus.reportReady ||
        _samples[sIdx].status == SampleStatus.delivered) {
      throw Exception('This sample cannot be rejected.');
    }
    final originalOrder = getOrder(_samples[sIdx].orderId);
    if (sIdx != -1) {
      final s = _samples[sIdx];
      patientName = s.patientName;
      testName = s.testNames.isNotEmpty ? s.testNames.first : 'Test Panel';

      final milestone = SampleEventModel(
        id: 'EV-REJ-$barcode-${now.millisecondsSinceEpoch}',
        sampleBarcode: barcode,
        toStatus: SampleStatus.rejected,
        actorId: 'LAB-ARYAN',
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
      _syncSampleToFirestore(_samples[sIdx]);
    }

    final qc = QcInspectionModel(
      id: 'QC-${now.millisecondsSinceEpoch}',
      sampleBarcode: barcode.toUpperCase(),
      patientName: patientName,
      testName: testName,
      rejectionReason: rejectionReason,
      technicianId: 'LAB-ARYAN',
      technicianName: technicianName,
      rejectedAt: now,
      clinicalNotes: clinicalNotes,
      recollectionTriggered: true,
    );
    _qcRejections.insert(0, qc);

    // Create automatic recollection pickup order for phlebotomist & front desk
    final recollectionOrder = OrderModel(
      id: 'ORD-REC-${const Uuid().v4().replaceAll('-', '').toUpperCase()}',
      patientId: sIdx != -1 ? _samples[sIdx].patientId : 'PT-REC',
      patientName: patientName,
      patientPhone: sIdx != -1 ? _samples[sIdx].patientPhone : '',
      collectionAddress: originalOrder?.collectionAddress ?? '',
      testNames: _samples[sIdx].testNames,
      totalAmount: 0.0, // Free recollection due to lab QC
      scheduledDate: now.add(const Duration(hours: 2)),
      timeSlot: 'STAT RECOLLECTION: $rejectionReason',
      branchId: originalOrder?.branchId ?? '',
      branchName: originalOrder?.branchName ?? '',
      status: OrderStatus.inProgress,
      sampleBarcodes: ['SMP-${const Uuid().v4().replaceAll('-', '').toUpperCase()}'],
      assignedPhlebotomistId: originalOrder?.assignedPhlebotomistId,
      assignedPhlebotomistName: originalOrder?.assignedPhlebotomistName,
      specialInstructions: 'STAT RE-DRAW: Previous specimen failed QC ($rejectionReason).',
      createdAt: now,
    );
    createOrder(recollectionOrder);

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
    _syncSampleToFirestore(sample);
    CrossTabSync.broadcast('sync_sample', _sampleToSyncJson(sample));
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

  /// Immediately registers/updates a user locally and pushes to Firestore
  void registerOrUpdateUser(UserModel user) {
    final idx = _users.indexWhere((u) => u.id == user.id || (user.email != null && user.email!.isNotEmpty && u.email == user.email));
    if (idx != -1) {
      _users[idx] = user;
    } else {
      _users.insert(0, user);
    }

    // Also update staff roster
    final sIdx = _staff.indexWhere((s) => s.id == user.id || (user.email != null && user.email!.isNotEmpty && s.email == user.email));
    final staffMember = userToStaffAllocation(
      user,
      assignedBranchName: _branches.firstWhere(
        (b) => b.id == user.assignedBranchId,
        orElse: () => _branches.first,
      ).name,
    );
    if (sIdx != -1) {
      _staff[sIdx] = staffMember;
    } else {
      _staff.insert(0, staffMember);
    }

    _syncUserToFirestore(user);
    notifyListeners();
  }

  void _syncUserToFirestore(UserModel user) {
    final fs = _getOrInitFirestore();
    if (fs == null) return;
    try {
      fs.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true)).catchError((e) {
        debugPrint('Firestore user sync warning: $e');
      });
    } catch (e) {
      debugPrint('Firestore user sync error: $e');
    }
  }

  void toggleStaffDuty(String staffId) {
    final sIdx = _staff.indexWhere((s) => s.id == staffId);
    if (sIdx != -1) {
      final cur = _staff[sIdx];
      _staff[sIdx] = cur.copyWith(isOnDuty: !cur.isOnDuty);
      notifyListeners();
    }
  }

  void reallocateStaff({
    required String staffId,
    required String targetBranchId,
    required String targetBranchName,
  }) {
    final sIdx = _staff.indexWhere((s) => s.id == staffId);
    if (sIdx != -1) {
      final cur = _staff[sIdx];
      _staff[sIdx] = cur.copyWith(
        assignedBranchId: targetBranchId,
        assignedBranchName: targetBranchName,
      );
      final uIdx = _users.indexWhere((u) => u.id == staffId);
      if (uIdx != -1) {
        final updatedUser = _users[uIdx].copyWith(assignedBranchId: targetBranchId);
        _users[uIdx] = updatedUser;
        _syncUserToFirestore(updatedUser);
      }
      notifyListeners();
    }
  }

  void addStaffMember(StaffAllocationModel staff) {
    final sIdx = _staff.indexWhere((s) => s.id == staff.id);
    if (sIdx != -1) {
      _staff[sIdx] = staff;
    } else {
      _staff.insert(0, staff);
    }
    final user = UserModel(
      id: staff.id,
      name: staff.name,
      phoneNumber: staff.phoneNumber,
      email: staff.email,
      role: staff.role,
      assignedBranchId: staff.assignedBranchId,
      createdAt: DateTime.now(),
    );
    final uIdx = _users.indexWhere((u) => u.id == staff.id);
    if (uIdx != -1) {
      _users[uIdx] = user;
    } else {
      _users.insert(0, user);
    }
    _syncUserToFirestore(user);
    notifyListeners();
  }
}

