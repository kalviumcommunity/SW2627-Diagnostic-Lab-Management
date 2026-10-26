// Input validation helper functions for forms and fields.

/// Centralized input validation utilities for LabTrack form fields,
/// authentication, specimen accessioning, and cold chain telemetry.
class AppValidators {
  AppValidators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static final RegExp _phoneDigitsOnlyRegExp = RegExp(r'[^\d]');

  static final RegExp _barcodeRegExp = RegExp(r'^[A-Za-z0-9\-_]{4,32}$');

  /// Validates required fields with a configurable label.
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates standard email addresses.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password with optional minimum length (defaults to 6).
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validates that password and confirm password match.
  static String? validateConfirmPassword(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates phone numbers (must contain between 10 and 15 digits).
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(_phoneDigitsOnlyRegExp, '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Please enter a valid phone number (10 to 15 digits)';
    }
    return null;
  }

  /// Validates age within an acceptable clinical range (e.g. 1 to 120).
  static String? validateAge(String? value, {int min = 1, int max = 120}) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed < min || parsed > max) {
      return 'Age must be between $min and $max';
    }
    return null;
  }

  /// Validates specimen barcode / accession vial IDs.
  static String? validateSampleBarcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sample barcode is required';
    }
    final trimmed = value.trim();
    if (!_barcodeRegExp.hasMatch(trimmed)) {
      return 'Invalid barcode format (alphanumeric, dashes, 4-32 characters)';
    }
    return null;
  }

  /// Validates cold chain telemetry temperature (e.g. -80.0°C to 50.0°C).
  static String? validateColdChainTemperature(
    String? value, {
    double min = -80.0,
    double max = 50.0,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Temperature reading is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid temperature value';
    }
    if (parsed < min || parsed > max) {
      return 'Temperature must be between $min°C and $max°C';
    }
    return null;
  }
}
