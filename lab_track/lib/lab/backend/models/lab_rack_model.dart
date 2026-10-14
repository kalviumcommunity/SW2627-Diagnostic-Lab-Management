/// Physical Analyzer Rack Model representing batch tube holders
/// for automated analyzers (Hematology, Biochemistry, Immunoassay).
class LabRackModel {
  final String id;
  final String name;
  final String department; // 'Hematology', 'Biochemistry', 'Immunology', 'Clinical Pathology'
  final String analyzerName; // e.g. 'Beckman DxH 800', 'Roche Cobas 8000'
  final int capacity;
  final List<String> sampleBarcodes;
  final String status; // 'loading', 'in_analyzer', 'completed'
  final DateTime createdAt;

  const LabRackModel({
    required this.id,
    required this.name,
    required this.department,
    required this.analyzerName,
    this.capacity = 24,
    this.sampleBarcodes = const [],
    this.status = 'loading',
    required this.createdAt,
  });

  int get currentCount => sampleBarcodes.length;
  bool get isFull => currentCount >= capacity;
  double get occupancyRate => capacity > 0 ? (currentCount / capacity) : 0.0;

  LabRackModel copyWith({
    String? id,
    String? name,
    String? department,
    String? analyzerName,
    int? capacity,
    List<String>? sampleBarcodes,
    String? status,
    DateTime? createdAt,
  }) {
    return LabRackModel(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      analyzerName: analyzerName ?? this.analyzerName,
      capacity: capacity ?? this.capacity,
      sampleBarcodes: sampleBarcodes ?? this.sampleBarcodes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'analyzerName': analyzerName,
      'capacity': capacity,
      'sampleBarcodes': sampleBarcodes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LabRackModel.fromMap(Map<String, dynamic> map) {
    return LabRackModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      department: map['department']?.toString() ?? 'Biochemistry',
      analyzerName: map['analyzerName']?.toString() ?? 'Standard Analyzer',
      capacity: (map['capacity'] as num?)?.toInt() ?? 24,
      sampleBarcodes: (map['sampleBarcodes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: map['status']?.toString() ?? 'loading',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
