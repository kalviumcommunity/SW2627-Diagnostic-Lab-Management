import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/enums/order_status.dart';

class OrderModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String collectionAddress;
  final List<String> testNames;
  final double totalAmount;
  final DateTime scheduledDate;
  final String timeSlot;
  final String branchId;
  final String branchName;
  final OrderStatus status;
  final List<String> sampleBarcodes;
  final String? assignedPhlebotomistId;
  final String? assignedPhlebotomistName;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.collectionAddress,
    required this.testNames,
    required this.totalAmount,
    required this.scheduledDate,
    required this.timeSlot,
    required this.branchId,
    required this.branchName,
    this.status = OrderStatus.confirmed,
    this.sampleBarcodes = const [],
    this.assignedPhlebotomistId,
    this.assignedPhlebotomistName,
    this.specialInstructions,
    required this.createdAt,
    this.updatedAt,
  });

  OrderModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? collectionAddress,
    List<String>? testNames,
    double? totalAmount,
    DateTime? scheduledDate,
    String? timeSlot,
    String? branchId,
    String? branchName,
    OrderStatus? status,
    List<String>? sampleBarcodes,
    String? assignedPhlebotomistId,
    String? assignedPhlebotomistName,
    String? specialInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      collectionAddress: collectionAddress ?? this.collectionAddress,
      testNames: testNames ?? this.testNames,
      totalAmount: totalAmount ?? this.totalAmount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      sampleBarcodes: sampleBarcodes ?? this.sampleBarcodes,
      assignedPhlebotomistId: assignedPhlebotomistId ?? this.assignedPhlebotomistId,
      assignedPhlebotomistName: assignedPhlebotomistName ?? this.assignedPhlebotomistName,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'collectionAddress': collectionAddress,
      'testNames': testNames,
      'totalAmount': totalAmount,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'timeSlot': timeSlot,
      'branchId': branchId,
      'branchName': branchName,
      'status': status.name,
      'sampleBarcodes': sampleBarcodes,
      'assignedPhlebotomistId': assignedPhlebotomistId,
      'assignedPhlebotomistName': assignedPhlebotomistName,
      'specialInstructions': specialInstructions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : Timestamp.fromDate(createdAt),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return OrderModel(
      id: documentId ?? map['id']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      patientPhone: map['patientPhone']?.toString() ?? '',
      collectionAddress: map['collectionAddress']?.toString() ?? '',
      testNames: (map['testNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalAmount: (map['totalAmount'] != null)
          ? double.tryParse(map['totalAmount'].toString()) ?? 0.0
          : 0.0,
      scheduledDate: parseDate(map['scheduledDate']),
      timeSlot: map['timeSlot']?.toString() ?? '',
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      status: OrderStatus.fromString(map['status']?.toString()),
      sampleBarcodes: (map['sampleBarcodes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      assignedPhlebotomistId: map['assignedPhlebotomistId']?.toString(),
      assignedPhlebotomistName: map['assignedPhlebotomistName']?.toString(),
      specialInstructions: map['specialInstructions']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }
}
