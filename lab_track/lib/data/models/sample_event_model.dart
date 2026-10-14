import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/enums/sample_status.dart';
import '../../domain/enums/user_role.dart';

/// Represents an immutable chain-of-custody milestone for a diagnostic sample.
class SampleEventModel {
  final String id;
  final String sampleBarcode;
  final String orderId;
  final SampleStatus? fromStatus;
  final SampleStatus toStatus;
  final String actorId;
  final String actorName;
  final UserRole actorRole;
  final DateTime timestamp;
  final String? branchId;
  final double? latitude;
  final double? longitude;
  final double? temperatureC;
  final String? note;

  const SampleEventModel({
    required this.id,
    required this.sampleBarcode,
    this.orderId = '',
    this.fromStatus,
    required this.toStatus,
    required this.timestamp,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    this.branchId,
    this.latitude,
    this.longitude,
    this.temperatureC,
    this.note,
  });

  // Non-breaking aliases for existing UI code
  SampleStatus get status => toStatus;
  double? get temperatureCelsius => temperatureC;
  String? get notes => note;
  String get locationName => branchId ?? 'Diagnostic Facility';

  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'sampleBarcode': sampleBarcode,
      'orderId': orderId,
      'fromStatus': fromStatus?.name,
      'toStatus': toStatus.name,
      'actorId': actorId,
      'actorRole': actorRole.name,
      'actorName': actorName,
      'timestamp': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(timestamp),
      'branchId': branchId,
      if (latitude != null && longitude != null)
        'gps': GeoPoint(latitude!, longitude!),
      if (temperatureC != null) 'temperatureC': temperatureC,
      if (note != null) 'note': note,
    };
  }

  factory SampleEventModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    double? lat;
    double? lng;
    final gpsVal = map['gps'];
    if (gpsVal is GeoPoint) {
      lat = gpsVal.latitude;
      lng = gpsVal.longitude;
    } else {
      if (map['latitude'] != null) lat = double.tryParse(map['latitude'].toString());
      if (map['longitude'] != null) lng = double.tryParse(map['longitude'].toString());
    }

    double? tempC;
    if (map['temperatureC'] != null) {
      tempC = double.tryParse(map['temperatureC'].toString());
    } else if (map['temperatureCelsius'] != null) {
      tempC = double.tryParse(map['temperatureCelsius'].toString());
    }

    final toStatusStr = map['toStatus']?.toString() ?? map['status']?.toString();

    return SampleEventModel(
      id: documentId ?? map['id']?.toString() ?? '',
      sampleBarcode: map['sampleBarcode']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      fromStatus: map['fromStatus'] != null
          ? SampleStatus.fromString(map['fromStatus'].toString())
          : null,
      toStatus: SampleStatus.fromString(toStatusStr),
      timestamp: parseDate(map['timestamp']),
      actorId: map['actorId']?.toString() ?? '',
      actorName: map['actorName']?.toString() ?? 'System',
      actorRole: UserRole.fromString(map['actorRole']?.toString()),
      branchId: map['branchId']?.toString() ?? map['locationName']?.toString(),
      latitude: lat,
      longitude: lng,
      temperatureC: tempC,
      note: map['note']?.toString() ?? map['notes']?.toString(),
    );
  }
}
