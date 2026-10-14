/// Represents a pre-analytical or analytical specimen quality failure.
class QcInspectionModel {
  final String id;
  final String sampleBarcode;
  final String patientName;
  final String testName;
  final String rejectionReason; // 'Hemolyzed (Free Hb > 500mg/dL)', 'Micro-clots in EDTA Tube', 'Insufficient Specimen Volume (< 1.5 mL)', 'Lipemic / High Turbidity', 'Specimen Tube Damaged'
  final String technicianId;
  final String technicianName;
  final DateTime rejectedAt;
  final String? clinicalNotes;
  final bool recollectionTriggered;

  const QcInspectionModel({
    required this.id,
    required this.sampleBarcode,
    required this.patientName,
    required this.testName,
    required this.rejectionReason,
    required this.technicianId,
    required this.technicianName,
    required this.rejectedAt,
    this.clinicalNotes,
    this.recollectionTriggered = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sampleBarcode': sampleBarcode,
      'patientName': patientName,
      'testName': testName,
      'rejectionReason': rejectionReason,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'rejectedAt': rejectedAt.toIso8601String(),
      'clinicalNotes': clinicalNotes,
      'recollectionTriggered': recollectionTriggered,
    };
  }

  factory QcInspectionModel.fromMap(Map<String, dynamic> map) {
    return QcInspectionModel(
      id: map['id']?.toString() ?? '',
      sampleBarcode: map['sampleBarcode']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      testName: map['testName']?.toString() ?? '',
      rejectionReason: map['rejectionReason']?.toString() ?? 'Unspecified Pre-analytical Non-compliance',
      technicianId: map['technicianId']?.toString() ?? 'LAB-501',
      technicianName: map['technicianName']?.toString() ?? 'Dr. Sarah Chen',
      rejectedAt: map['rejectedAt'] != null
          ? DateTime.tryParse(map['rejectedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      clinicalNotes: map['clinicalNotes']?.toString(),
      recollectionTriggered: map['recollectionTriggered'] as bool? ?? true,
    );
  }
}
