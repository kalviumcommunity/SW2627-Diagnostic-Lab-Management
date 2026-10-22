import 'package:cloud_firestore/cloud_firestore.dart';

class ReportParameter {
  final String name;
  final String value;
  final String? unit;
  final String range;
  final String flag; // 'Normal', 'High', 'Low', 'Borderline High'

  const ReportParameter({
    required this.name,
    required this.value,
    this.unit,
    required this.range,
    this.flag = 'Normal',
  });

  bool get isAbnormal => flag.toLowerCase() != 'normal';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'range': range,
      'flag': flag,
    };
  }

  factory ReportParameter.fromMap(Map<String, dynamic> map) {
    return ReportParameter(
      name: map['name']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
      unit: map['unit']?.toString(),
      range: map['range']?.toString() ?? '',
      flag: map['flag']?.toString() ?? 'Normal',
    );
  }
}

class ReportModel {
  final String id;
  final String orderId;
  final String sampleBarcode;
  final String patientId;
  final String patientName;
  final String status;
  final String? pdfUrl;
  final String? uploadedById;
  final String? pathologistName;
  final DateTime? uploadedAt;
  final DateTime? verifiedAt;
  final List<ReportParameter> testResults;

  // Compatibility fields for existing UI screens
  final String testName;
  final String branchName;

  const ReportModel({
    required this.id,
    required this.orderId,
    required this.sampleBarcode,
    required this.patientId,
    this.patientName = '',
    required this.status,
    this.pdfUrl,
    String? uploadedById,
    String? pathologistName,
    DateTime? uploadedAt,
    DateTime? createdAt,
    DateTime? verifiedAt,
    DateTime? verificationDate,
    List<ReportParameter>? testResults,
    List<ReportParameter>? parameters,
    bool? isReady,
    this.testName = '',
    this.branchName = '',
  })  : uploadedById = uploadedById,
        pathologistName = pathologistName,
        uploadedAt = uploadedAt ?? createdAt,
        verifiedAt = verifiedAt ?? verificationDate,
        testResults = testResults ?? parameters ?? const [];

  // Non-breaking aliases for existing UI code
  List<ReportParameter> get parameters => testResults;
  DateTime get createdAt => uploadedAt ?? DateTime.now();
  DateTime? get verificationDate => verifiedAt;
  bool get isReady =>
      status.toLowerCase().contains('verified') ||
      status.toLowerCase().contains('ready');

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'sampleBarcode': sampleBarcode,
      'patientId': patientId,
      'patientName': patientName,
      'status': status,
      'pdfUrl': pdfUrl,
      'uploadedById': uploadedById,
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'testResults': testResults.map((p) => p.toMap()).toList(),
      if (testName.isNotEmpty) 'testName': testName,
      if (branchName.isNotEmpty) 'branchName': branchName,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawParams = map['testResults'] ?? map['parameters'];
    List<ReportParameter> paramList = [];
    if (rawParams is List) {
      paramList = rawParams
          .map((p) => ReportParameter.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList();
    }

    return ReportModel(
      id: documentId ?? map['id']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      sampleBarcode: map['sampleBarcode']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Processing',
      pdfUrl: map['pdfUrl']?.toString(),
      uploadedById: map['uploadedById']?.toString(),
      pathologistName: map['pathologistName']?.toString(),
      uploadedAt: parseDate(map['uploadedAt']) ?? parseDate(map['createdAt']),
      verifiedAt: parseDate(map['verifiedAt']) ?? parseDate(map['verificationDate']),
      testResults: paramList,
      testName: map['testName']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? 'Central Diagnostic Lab',
    );
  }
}
