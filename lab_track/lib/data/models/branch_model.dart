class BranchModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final bool hasTestingLab;
  final String phoneNumber;

  const BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.hasTestingLab = true,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'hasTestingLab': hasTestingLab,
      'phoneNumber': phoneNumber,
    };
  }

  factory BranchModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return BranchModel(
      id: documentId ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      hasTestingLab: map['hasTestingLab'] == true,
      phoneNumber: map['phoneNumber']?.toString() ?? '',
    );
  }
}
