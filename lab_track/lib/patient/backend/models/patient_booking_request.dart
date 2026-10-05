class PatientBookingRequest {
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String address;
  final List<String> selectedTestNames;
  final double totalAmount;
  final DateTime scheduledDate;
  final String timeSlot;
  final String branchName;
  final String? notes;

  const PatientBookingRequest({
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.address,
    required this.selectedTestNames,
    required this.totalAmount,
    required this.scheduledDate,
    required this.timeSlot,
    required this.branchName,
    this.notes,
  });

  String? validate() {
    if (patientName.trim().isEmpty) return 'Patient name is required.';
    if (patientPhone.trim().isEmpty) return 'Contact phone number is required.';
    if (address.trim().isEmpty) return 'Sample collection address is required.';
    if (selectedTestNames.isEmpty) return 'At least one test must be selected.';
    return null;
  }
}
