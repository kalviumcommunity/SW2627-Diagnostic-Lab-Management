import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/enums/sample_status.dart';
import 'sample_event_model.dart';

class SampleModel {
  final String barcode;
  final String orderId;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String tubeType;
  final SampleStatus status;
  final String? currentCustodianId;
  final String? currentCustodianRole;
  final String? currentBranchId;
  final String? currentBranchName;
  final String? assignedPhlebotomistName;
  final DateTime? collectedAt;
  final double? temperatureC;
  final DateTime? lastEventAt;
  final DateTime createdAt;
  final List<String> searchKeywords;

  // Compatibility and UI helper fields
  final List<String> testNames;
  final String? notes;
  final List<SampleEventModel> events;

  SampleModel({
    required this.barcode,
    required this.orderId,
    required this.patientId,
    required this.patientName,
    this.patientPhone = '',
    String? tubeType,
    String? vialType,
    this.status = SampleStatus.booked,
    String? currentCustodianId,
    String? assignedPhlebotomistId,
    this.currentCustodianRole,
    this.currentBranchId,
    this.currentBranchName,
    this.assignedPhlebotomistName,
    DateTime? collectedAt,
    DateTime? collectionTime,
    double? temperatureC,
    String? temperatureStatus,
    this.lastEventAt,
    DateTime? createdAt,
    this.searchKeywords = const [],
    this.testNames = const [],
    this.notes,
    this.events = const [],
  })  : tubeType = tubeType ?? vialType ?? 'Standard Collection Tube',
        currentCustodianId = currentCustodianId ?? assignedPhlebotomistId,
        collectedAt = collectedAt ?? collectionTime,
        temperatureC = temperatureC ?? _parseTemp(temperatureStatus),
        createdAt = createdAt ?? DateTime.now();

  static double? _parseTemp(String? tempStr) {
    if (tempStr == null) return null;
    final match = RegExp(r'([0-9]+\.?[0-9]*)').firstMatch(tempStr);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  // Non-breaking aliases for existing UI code
  String get vialType => tubeType;
  String? get assignedPhlebotomistId => currentCustodianId;
  DateTime? get collectionTime => collectedAt;
  String? get temperatureStatus {
    if (temperatureC != null) {
      return '${temperatureC!.toStringAsFixed(1)}°C (Cold Chain)';
    }
    return null;
  }

  static List<String> generateSearchKeywords({
    required String barcode,
    required String orderId,
    required String patientPhone,
    required String patientName,
  }) {
    final set = <String>{};
    if (barcode.trim().isNotEmpty) {
      set.add(barcode.trim().toLowerCase());
    }
    if (orderId.trim().isNotEmpty) {
      set.add(orderId.trim().toLowerCase());
    }
    if (patientPhone.trim().isNotEmpty) {
      set.add(patientPhone.trim().toLowerCase());
      final digits = patientPhone.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) set.add(digits);
    }
    if (patientName.trim().isNotEmpty) {
      set.add(patientName.trim().toLowerCase());
      final tokens = patientName.trim().toLowerCase().split(RegExp(r'\s+'));
      for (final t in tokens) {
        if (t.isNotEmpty) set.add(t);
      }
    }
    return set.toList();
  }

  SampleModel copyWith({
    String? barcode,
    String? orderId,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? tubeType,
    String? vialType,
    SampleStatus? status,
    String? currentCustodianId,
    String? assignedPhlebotomistId,
    String? currentCustodianRole,
    String? currentBranchId,
    String? currentBranchName,
    String? assignedPhlebotomistName,
    DateTime? collectedAt,
    DateTime? collectionTime,
    double? temperatureC,
    String? temperatureStatus,
    DateTime? lastEventAt,
    DateTime? createdAt,
    List<String>? searchKeywords,
    List<String>? testNames,
    String? notes,
    List<SampleEventModel>? events,
  }) {
    return SampleModel(
      barcode: barcode ?? this.barcode,
      orderId: orderId ?? this.orderId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      tubeType: tubeType ?? vialType ?? this.tubeType,
      status: status ?? this.status,
      currentCustodianId: currentCustodianId ?? assignedPhlebotomistId ?? this.currentCustodianId,
      currentCustodianRole: currentCustodianRole ?? this.currentCustodianRole,
      currentBranchId: currentBranchId ?? this.currentBranchId,
      currentBranchName: currentBranchName ?? this.currentBranchName,
      assignedPhlebotomistName: assignedPhlebotomistName ?? this.assignedPhlebotomistName,
      collectedAt: collectedAt ?? collectionTime ?? this.collectedAt,
      temperatureC: temperatureC ?? this.temperatureC,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      createdAt: createdAt ?? this.createdAt,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      testNames: testNames ?? this.testNames,
      notes: notes ?? this.notes,
      events: events ?? this.events,
    );
  }

  Map<String, dynamic> toMap() {
    final keywords = searchKeywords.isNotEmpty
        ? searchKeywords
        : generateSearchKeywords(
            barcode: barcode,
            orderId: orderId,
            patientPhone: patientPhone,
            patientName: patientName,
          );

    return {
      'orderId': orderId,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'tubeType': tubeType,
      'status': status.name,
      'currentCustodianId': currentCustodianId,
      'currentCustodianRole': currentCustodianRole,
      'currentBranchId': currentBranchId,
      'collectedAt': collectedAt != null ? Timestamp.fromDate(collectedAt!) : null,
      'temperatureC': temperatureC,
      'lastEventAt': lastEventAt != null
          ? Timestamp.fromDate(lastEventAt!)
          : Timestamp.fromDate(createdAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'searchKeywords': keywords,
      if (testNames.isNotEmpty) 'testNames': testNames,
      if (currentBranchName != null) 'currentBranchName': currentBranchName,
      if (assignedPhlebotomistName != null) 'assignedPhlebotomistName': assignedPhlebotomistName,
      if (notes != null) 'notes': notes,
    };
  }

  factory SampleModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawEvents = map['events'];
    List<SampleEventModel> eventList = [];
    if (rawEvents is List) {
      eventList = rawEvents
          .map((e) => SampleEventModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final rawKeywords = map['searchKeywords'];
    List<String> keywords = [];
    if (rawKeywords is List) {
      keywords = rawKeywords.map((e) => e.toString()).toList();
    }

    double? parseTemp(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) {
        final numPart = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(val)?.group(0);
        return numPart != null ? double.tryParse(numPart) : null;
      }
      return null;
    }

    final barcode = documentId ?? map['barcode']?.toString() ?? '';
    final orderId = map['orderId']?.toString() ?? '';
    final patientId = map['patientId']?.toString() ?? '';
    final patientName = map['patientName']?.toString() ?? '';
    final patientPhone = map['patientPhone']?.toString() ?? '';

    if (keywords.isEmpty) {
      keywords = generateSearchKeywords(
        barcode: barcode,
        orderId: orderId,
        patientPhone: patientPhone,
        patientName: patientName,
      );
    }

    return SampleModel(
      barcode: barcode,
      orderId: orderId,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      tubeType: map['tubeType']?.toString() ?? map['vialType']?.toString() ?? 'Standard EDTA',
      status: SampleStatus.fromString(map['status']?.toString()),
      currentCustodianId: map['currentCustodianId']?.toString() ?? map['assignedPhlebotomistId']?.toString(),
      currentCustodianRole: map['currentCustodianRole']?.toString(),
      currentBranchId: map['currentBranchId']?.toString(),
      currentBranchName: map['currentBranchName']?.toString(),
      assignedPhlebotomistName: map['assignedPhlebotomistName']?.toString(),
      collectedAt: parseDate(map['collectedAt']) ?? parseDate(map['collectionTime']),
      temperatureC: parseTemp(map['temperatureC']) ?? parseTemp(map['temperatureStatus']),
      lastEventAt: parseDate(map['lastEventAt']),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      searchKeywords: keywords,
      testNames: (map['testNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      notes: map['notes']?.toString(),
      events: eventList,
    );
  }
}
