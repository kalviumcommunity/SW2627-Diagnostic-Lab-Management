class WalkInRequisitionRequest {
  final String patientName;
  final String patientPhone;
  final int age;
  final String gender;
  final String address;
  final List<String> selectedTestNames;
  final String priority; // 'Routine' or 'Urgent STAT'
  final String branchId;
  final String branchName;
  final String? clinicalNotes;

  const WalkInRequisitionRequest({
    required this.patientName,
    required this.patientPhone,
    required this.age,
    required this.gender,
    required this.address,
    required this.selectedTestNames,
    this.priority = 'Routine',
    this.branchId = 'branch-spoke-01',
    this.branchName = 'Downtown Spoke Center #1',
    this.clinicalNotes,
  });

  String? validate() {
    if (patientName.trim().isEmpty) {
      return 'Please enter the patient full name.';
    }
    final digits = patientPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) {
      return 'Please enter a valid 10-digit mobile number.';
    }
    if (age <= 0 || age > 125) {
      return 'Please enter a valid patient age.';
    }
    if (selectedTestNames.isEmpty) {
      return 'Please select at least one diagnostic test.';
    }
    return null;
  }
}
