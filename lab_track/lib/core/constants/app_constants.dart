// Global application constants and configuration values.

/// Core operational and clinical constants for the LabTrack application.
class AppConstants {
  AppConstants._();

  /// Application branding
  static const String appName = 'LabTrack';
  static const String appTagline = 'Diagnostic Lab Management & Chain-of-Custody';
  static const String appVersion = '1.0.0';

  /// Cold chain safe temperature thresholds (Celsius)
  static const double coldChainMinSafeTempCelsius = 2.0;
  static const double coldChainMaxSafeTempCelsius = 8.0;

  /// Specimen accessioning defaults
  static const String defaultSampleBarcodePrefix = 'SMP-';
  static const int minBarcodeLength = 4;
  static const int maxBarcodeLength = 32;

  /// Network & search debouncing
  static const Duration searchDebounceDuration = Duration(milliseconds: 300);
  static const Duration networkTimeout = Duration(seconds: 15);
}
