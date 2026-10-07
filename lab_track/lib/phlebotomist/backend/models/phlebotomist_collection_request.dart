class PhlebotomistCollectionRequest {
  final String orderId;
  final String patientId;
  final String patientName;
  final String sampleBarcode;
  final String vialType;
  final double temperatureCelsius;
  final double? latitude;
  final double? longitude;
  final String locationAddress;
  final bool fastingVerified;
  final bool patientIdentified;
  final String? notes;
  final String phlebotomistId;
  final String phlebotomistName;

  const PhlebotomistCollectionRequest({
    required this.orderId,
    required this.patientId,
    required this.patientName,
    required this.sampleBarcode,
    required this.vialType,
    required this.temperatureCelsius,
    this.latitude,
    this.longitude,
    required this.locationAddress,
    this.fastingVerified = true,
    this.patientIdentified = true,
    this.notes,
    required this.phlebotomistId,
    required this.phlebotomistName,
  });

  String? validate() {
    if (sampleBarcode.trim().isEmpty) {
      return 'Please scan or enter a sterile vial barcode.';
    }
    if (temperatureCelsius < 1.0 || temperatureCelsius > 12.0) {
      return 'Cold-box temperature (${temperatureCelsius.toStringAsFixed(1)}°C) is outside permissible range (2.0°C - 8.0°C).';
    }
    if (!patientIdentified) {
      return 'Please verify patient identity before collecting blood.';
    }
    return null;
  }
}
