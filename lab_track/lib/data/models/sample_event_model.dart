import '../../domain/enums/sample_status.dart';
import '../../domain/enums/user_role.dart';

/// Represents an immutable chain-of-custody milestone for a diagnostic sample.
class SampleEventModel {
  final String id;
  final String sampleBarcode;
  final SampleStatus status;
  final DateTime timestamp;
  final String actorId;
  final String actorName;
  final UserRole actorRole;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final double? temperatureCelsius;
  final String? notes;

  const SampleEventModel({
    required this.id,
    required this.sampleBarcode,
    required this.status,
    required this.timestamp,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.temperatureCelsius,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sampleBarcode': sampleBarcode,
      'status': status.toValue(),
      'timestamp': timestamp.toIso8601String(),
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole.toValue(),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'temperatureCelsius': temperatureCelsius,
      'notes': notes,
    };
  }

  factory SampleEventModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return SampleEventModel(
      id: documentId ?? map['id']?.toString() ?? '',
      sampleBarcode: map['sampleBarcode']?.toString() ?? '',
      status: SampleStatus.fromString(map['status']?.toString()),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actorId: map['actorId']?.toString() ?? '',
      actorName: map['actorName']?.toString() ?? 'System',
      actorRole: UserRole.fromString(map['actorRole']?.toString()),
      locationName: map['locationName']?.toString() ?? 'Diagnostic Facility',
      latitude: map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null,
      temperatureCelsius: map['temperatureCelsius'] != null
          ? double.tryParse(map['temperatureCelsius'].toString())
          : null,
      notes: map['notes']?.toString(),
    );
  }
}
