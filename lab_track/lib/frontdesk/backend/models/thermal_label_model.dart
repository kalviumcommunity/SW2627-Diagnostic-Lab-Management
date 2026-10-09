class ThermalLabelModel {
  final String barcode;
  final String orderId;
  final String patientName;
  final String patientAgeGender;
  final List<String> testNames;
  final String vialType;
  final int vialColorValue; // ARGB Color int
  final String volumeRequired;
  final String branchId;
  final String branchName;
  final DateTime timestamp;
  final String priority;
  final bool isPrinted;

  const ThermalLabelModel({
    required this.barcode,
    required this.orderId,
    required this.patientName,
    required this.patientAgeGender,
    required this.testNames,
    required this.vialType,
    required this.vialColorValue,
    required this.volumeRequired,
    required this.branchId,
    required this.branchName,
    required this.timestamp,
    this.priority = 'Routine',
    this.isPrinted = false,
  });

  ThermalLabelModel copyWith({
    String? barcode,
    String? orderId,
    String? patientName,
    String? patientAgeGender,
    List<String>? testNames,
    String? vialType,
    int? vialColorValue,
    String? volumeRequired,
    String? branchId,
    String? branchName,
    DateTime? timestamp,
    String? priority,
    bool? isPrinted,
  }) {
    return ThermalLabelModel(
      barcode: barcode ?? this.barcode,
      orderId: orderId ?? this.orderId,
      patientName: patientName ?? this.patientName,
      patientAgeGender: patientAgeGender ?? this.patientAgeGender,
      testNames: testNames ?? this.testNames,
      vialType: vialType ?? this.vialType,
      vialColorValue: vialColorValue ?? this.vialColorValue,
      volumeRequired: volumeRequired ?? this.volumeRequired,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      isPrinted: isPrinted ?? this.isPrinted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'orderId': orderId,
      'patientName': patientName,
      'patientAgeGender': patientAgeGender,
      'testNames': testNames,
      'vialType': vialType,
      'vialColorValue': vialColorValue,
      'volumeRequired': volumeRequired,
      'branchId': branchId,
      'branchName': branchName,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority,
      'isPrinted': isPrinted,
    };
  }

  factory ThermalLabelModel.fromMap(Map<String, dynamic> map) {
    return ThermalLabelModel(
      barcode: map['barcode']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      patientAgeGender: map['patientAgeGender']?.toString() ?? '',
      testNames: (map['testNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      vialType: map['vialType']?.toString() ?? 'Standard Vial',
      vialColorValue: (map['vialColorValue'] as int?) ?? 0xFF7E22CE,
      volumeRequired: map['volumeRequired']?.toString() ?? '3.0 mL',
      branchId: map['branchId']?.toString() ?? 'branch-spoke-01',
      branchName: map['branchName']?.toString() ?? 'Branch Spoke 01',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      priority: map['priority']?.toString() ?? 'Routine',
      isPrinted: map['isPrinted'] == true,
    );
  }
}
