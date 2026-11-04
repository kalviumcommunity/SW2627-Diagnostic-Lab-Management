/// Core medical and operational thresholds for LabTrack.
class AppConstants {
  static const String appName = 'LabTrack';
  static const String appVersion = '1.0.0';

  // Cold Chain Thermal Regulation (°C)
  static const double minColdChainTemp = 2.0;
  static const double maxColdChainTemp = 8.0;

  // Search & Debounce
  static const int instantSearchDebounceMs = 300;

  // NABL Lab Details
  static const String labName = 'Apex Central Reference Laboratory';
  static const String nablAccreditation = 'NABL ISO 15189:2022';
  static const String helpline = '+91 124 456 7890';
}
