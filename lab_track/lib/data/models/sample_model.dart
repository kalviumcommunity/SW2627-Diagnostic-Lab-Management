import '../../domain/enums/sample_status.dart';
import 'sample_event_model.dart';

class SampleModel {
  final String barcode;
  final String orderId;
  final String patientId;
  final String patientName;
  final List<String> testNames;
  final String vialType;
  final SampleStatus status;
  final String? currentBranchId;
  final String? currentBranchName;
  final String? assignedPhlebotomistId;
  final String? assignedPhlebotomistName;
  final DateTime? collectionTime;
  final String? temperatureStatus;
  final String? notes;
  final List<SampleEventModel> events;
  final DateTime createdAt;

  const SampleModel({
    required this.barcode,
    required this.orderId,
    required this.patientId,
    required this.patientName,
    required this.testNames,
    required this.vialType,
    this.status = SampleStatus.booked,
    this.currentBranchId,
    this.currentBranchName,
    this.assignedPhlebotomistId,
    this.assignedPhlebotomistName,
    this.collectionTime,
    this.temperatureStatus,
    this.notes,
    this.events = const [],
    required this.createdAt,
  });

  SampleModel copyWith({
    String? barcode,
    String? orderId,
    String? patientId,
    String? patientName,
    List<String>? testNames,
    String? vialType,
    SampleStatus? status,
    String? currentBranchId,
    String? currentBranchName,
    String? assignedPhlebotomistId,
    String? assignedPhlebotomistName,
    DateTime? collectionTime,
    String? temperatureStatus,
    String? notes,
    List<SampleEventModel>? events,
    DateTime? createdAt,
  }) {
    return SampleModel(
      barcode: barcode ?? this.barcode,
      orderId: orderId ?? this.orderId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      testNames: testNames ?? this.testNames,
      vialType: vialType ?? this.vialType,
      status: status ?? this.status,
      currentBranchId: currentBranchId ?? this.currentBranchId,
      currentBranchName: currentBranchName ?? this.currentBranchName,
      assignedPhlebotomistId: assignedPhlebotomistId ?? this.assignedPhlebotomistId,
      assignedPhlebotomistName: assignedPhlebotomistName ?? this.assignedPhlebotomistName,
      collectionTime: collectionTime ?? this.collectionTime,
      temperatureStatus: temperatureStatus ?? this.temperatureStatus,
      notes: notes ?? this.notes,
      events: events ?? this.events,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'orderId': orderId,
      'patientId': patientId,
      'patientName': patientName,
      'testNames': testNames,
      'vialType': vialType,
      'status': status.toValue(),
      'currentBranchId': currentBranchId,
      'currentBranchName': currentBranchName,
      'assignedPhlebotomistId': assignedPhlebotomistId,
      'assignedPhlebotomistName': assignedPhlebotomistName,
      'collectionTime': collectionTime?.toIso8601String(),
      'temperatureStatus': temperatureStatus,
      'notes': notes,
      'events': events.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SampleModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawEvents = map['events'];
    List<SampleEventModel> eventList = [];
    if (rawEvents is List) {
      eventList = rawEvents
          .map((e) => SampleEventModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return SampleModel(
      barcode: documentId ?? map['barcode']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      testNames: (map['testNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      vialType: map['vialType']?.toString() ?? 'Standard EDTA',
      status: SampleStatus.fromString(map['status']?.toString()),
      currentBranchId: map['currentBranchId']?.toString(),
      currentBranchName: map['currentBranchName']?.toString(),
      assignedPhlebotomistId: map['assignedPhlebotomistId']?.toString(),
      assignedPhlebotomistName: map['assignedPhlebotomistName']?.toString(),
      collectionTime: map['collectionTime'] != null
          ? DateTime.tryParse(map['collectionTime'].toString())
          : null,
      temperatureStatus: map['temperatureStatus']?.toString(),
      notes: map['notes']?.toString(),
      events: eventList,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
