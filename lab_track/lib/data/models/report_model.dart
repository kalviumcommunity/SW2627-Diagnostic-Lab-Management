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
  final String patientId;
  final String sampleBarcode;
  final String testName;
  final String branchName;
  final String pathologistName;
  final DateTime? verificationDate;
  final bool isReady;
  final String status;
  final String? pdfUrl;
  final List<ReportParameter> parameters;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.orderId,
    required this.patientId,
    required this.sampleBarcode,
    required this.testName,
    required this.branchName,
    required this.pathologistName,
    this.verificationDate,
    required this.isReady,
    required this.status,
    this.pdfUrl,
    this.parameters = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'patientId': patientId,
      'sampleBarcode': sampleBarcode,
      'testName': testName,
      'branchName': branchName,
      'pathologistName': pathologistName,
      'verificationDate': verificationDate?.toIso8601String(),
      'isReady': isReady,
      'status': status,
      'pdfUrl': pdfUrl,
      'parameters': parameters.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawParams = map['parameters'];
    List<ReportParameter> paramList = [];
    if (rawParams is List) {
      paramList = rawParams
          .map((p) => ReportParameter.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList();
    }

    return ReportModel(
      id: documentId ?? map['id']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      sampleBarcode: map['sampleBarcode']?.toString() ?? '',
      testName: map['testName']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? 'Central Diagnostic Lab',
      pathologistName: map['pathologistName']?.toString() ?? 'Pending Pathologist Review',
      verificationDate: map['verificationDate'] != null
          ? DateTime.tryParse(map['verificationDate'].toString())
          : null,
      isReady: map['isReady'] == true,
      status: map['status']?.toString() ?? 'Processing',
      pdfUrl: map['pdfUrl']?.toString(),
      parameters: paramList,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
