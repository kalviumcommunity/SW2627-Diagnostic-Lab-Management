import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/core/utils/validators.dart';
import 'package:lab_track/core/constants/app_constants.dart';

void main() {
  group('AppValidators Unit Tests', () {
    group('validateRequired', () {
      test('returns error when value is null', () {
        expect(AppValidators.validateRequired(null, 'Full Name'), 'Full Name is required');
      });

      test('returns error when value is empty or only whitespace', () {
        expect(AppValidators.validateRequired('', 'Address'), 'Address is required');
        expect(AppValidators.validateRequired('   ', 'Address'), 'Address is required');
      });

      test('returns null when value is valid', () {
        expect(AppValidators.validateRequired('John Doe', 'Name'), isNull);
      });
    });

    group('validateEmail', () {
      test('returns error on null or empty email', () {
        expect(AppValidators.validateEmail(null), 'Email address is required');
        expect(AppValidators.validateEmail(''), 'Email address is required');
        expect(AppValidators.validateEmail('   '), 'Email address is required');
      });

      test('returns error on invalid email formats', () {
        expect(AppValidators.validateEmail('plainaddress'), 'Please enter a valid email address');
        expect(AppValidators.validateEmail('missingdomain@'), 'Please enter a valid email address');
        expect(AppValidators.validateEmail('@missingusername.com'), 'Please enter a valid email address');
        expect(AppValidators.validateEmail('spaces in@email.com'), 'Please enter a valid email address');
      });

      test('returns null on valid email formats', () {
        expect(AppValidators.validateEmail('john.doe@example.com'), isNull);
        expect(AppValidators.validateEmail('rahul.phlebo@labtrack.com'), isNull);
        expect(AppValidators.validateEmail('  admin@lab.org  '), isNull);
      });
    });

    group('validatePassword', () {
      test('returns error on null or empty password', () {
        expect(AppValidators.validatePassword(null), 'Password is required');
        expect(AppValidators.validatePassword(''), 'Password is required');
      });

      test('returns error when password is below minLength', () {
        expect(AppValidators.validatePassword('12345'), 'Password must be at least 6 characters');
        expect(AppValidators.validatePassword('abc', minLength: 8), 'Password must be at least 8 characters');
      });

      test('returns null when password satisfies minLength', () {
        expect(AppValidators.validatePassword('123456'), isNull);
        expect(AppValidators.validatePassword('securePass123'), isNull);
      });
    });

    group('validateConfirmPassword', () {
      test('returns error on null or empty confirmation', () {
        expect(AppValidators.validateConfirmPassword(null, 'pass123'), 'Please confirm your password');
        expect(AppValidators.validateConfirmPassword('', 'pass123'), 'Please confirm your password');
      });

      test('returns error when passwords do not match', () {
        expect(AppValidators.validateConfirmPassword('pass456', 'pass123'), 'Passwords do not match');
      });

      test('returns null when passwords match', () {
        expect(AppValidators.validateConfirmPassword('pass123', 'pass123'), isNull);
      });
    });

    group('validatePhoneNumber', () {
      test('returns error on null or empty phone', () {
        expect(AppValidators.validatePhoneNumber(null), 'Phone number is required');
        expect(AppValidators.validatePhoneNumber(''), 'Phone number is required');
        expect(AppValidators.validatePhoneNumber('   '), 'Phone number is required');
      });

      test('returns error when digit count is less than 10 or greater than 15', () {
        expect(AppValidators.validatePhoneNumber('12345'), 'Please enter a valid phone number (10 to 15 digits)');
        expect(AppValidators.validatePhoneNumber('123456789'), 'Please enter a valid phone number (10 to 15 digits)');
        expect(AppValidators.validatePhoneNumber('1234567890123456'), 'Please enter a valid phone number (10 to 15 digits)');
      });

      test('returns null on valid phone numbers with varying formats', () {
        expect(AppValidators.validatePhoneNumber('9876543210'), isNull);
        expect(AppValidators.validatePhoneNumber('+91 98765 43210'), isNull);
        expect(AppValidators.validatePhoneNumber('(555) 123-4567'), isNull);
      });
    });

    group('validateAge', () {
      test('returns error on null or empty age', () {
        expect(AppValidators.validateAge(null), 'Age is required');
        expect(AppValidators.validateAge(''), 'Age is required');
      });

      test('returns error on non-numeric age', () {
        expect(AppValidators.validateAge('twenty'), 'Please enter a valid number');
      });

      test('returns error when age is outside acceptable bounds', () {
        expect(AppValidators.validateAge('0'), 'Age must be between 1 and 120');
        expect(AppValidators.validateAge('150'), 'Age must be between 1 and 120');
      });

      test('returns null when age is in valid range', () {
        expect(AppValidators.validateAge('28'), isNull);
        expect(AppValidators.validateAge('65'), isNull);
      });
    });

    group('validateSampleBarcode', () {
      test('returns error on null or empty barcode', () {
        expect(AppValidators.validateSampleBarcode(null), 'Sample barcode is required');
        expect(AppValidators.validateSampleBarcode(''), 'Sample barcode is required');
      });

      test('returns error on invalid barcode format or length', () {
        expect(AppValidators.validateSampleBarcode('A'), 'Invalid barcode format (alphanumeric, dashes, 4-32 characters)');
        expect(AppValidators.validateSampleBarcode('SMP@123'), 'Invalid barcode format (alphanumeric, dashes, 4-32 characters)');
      });

      test('returns null on valid barcodes', () {
        expect(AppValidators.validateSampleBarcode('SMP-8921-X'), isNull);
        expect(AppValidators.validateSampleBarcode('BAR_10023_A'), isNull);
      });
    });

    group('validateColdChainTemperature', () {
      test('returns error on null or empty temperature', () {
        expect(AppValidators.validateColdChainTemperature(null), 'Temperature reading is required');
        expect(AppValidators.validateColdChainTemperature(''), 'Temperature reading is required');
      });

      test('returns error on non-numeric temperature', () {
        expect(AppValidators.validateColdChainTemperature('cold'), 'Please enter a valid temperature value');
      });

      test('returns error when temperature is outside clinical range', () {
        expect(AppValidators.validateColdChainTemperature('-95.0'), 'Temperature must be between -80.0°C and 50.0°C');
        expect(AppValidators.validateColdChainTemperature('60.0'), 'Temperature must be between -80.0°C and 50.0°C');
      });

      test('returns null on valid temperature readings', () {
        expect(AppValidators.validateColdChainTemperature('4.2'), isNull);
        expect(AppValidators.validateColdChainTemperature('-20.0'), isNull);
      });
    });

    group('AppConstants validation', () {
      test('constants have expected production default values', () {
        expect(AppConstants.appName, 'LabTrack');
        expect(AppConstants.coldChainMinSafeTempCelsius, 2.0);
        expect(AppConstants.coldChainMaxSafeTempCelsius, 8.0);
        expect(AppConstants.defaultSampleBarcodePrefix, 'SMP-');
      });
    });
  });
}
