/// Represents connected automated clinical diagnostic analyzers and their operational status.
class AnalyzerEquipmentModel {
  final String id;
  final String name;
  final String modelNumber;
  final String department;
  final String status; // 'Online & Calibrated', 'Analyzing Batch', 'Maintenance Due', 'Offline'
  final int samplesProcessedToday;
  final double temperatureC;
  final DateTime lastCalibrationTime;
  final String reagentLevel; // 'Optimal (94%)', 'Adequate (72%)', 'Low (18%)'

  const AnalyzerEquipmentModel({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.department,
    required this.status,
    required this.samplesProcessedToday,
    required this.temperatureC,
    required this.lastCalibrationTime,
    required this.reagentLevel,
  });

  bool get isOperational => status.contains('Online') || status.contains('Analyzing');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'modelNumber': modelNumber,
      'department': department,
      'status': status,
      'samplesProcessedToday': samplesProcessedToday,
      'temperatureC': temperatureC,
      'lastCalibrationTime': lastCalibrationTime.toIso8601String(),
      'reagentLevel': reagentLevel,
    };
  }

  factory AnalyzerEquipmentModel.fromMap(Map<String, dynamic> map) {
    return AnalyzerEquipmentModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      modelNumber: map['modelNumber']?.toString() ?? '',
      department: map['department']?.toString() ?? 'Biochemistry',
      status: map['status']?.toString() ?? 'Online & Calibrated',
      samplesProcessedToday: (map['samplesProcessedToday'] as num?)?.toInt() ?? 0,
      temperatureC: (map['temperatureC'] as num?)?.toDouble() ?? 22.0,
      lastCalibrationTime: map['lastCalibrationTime'] != null
          ? DateTime.tryParse(map['lastCalibrationTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reagentLevel: map['reagentLevel']?.toString() ?? 'Optimal',
    );
  }
}
