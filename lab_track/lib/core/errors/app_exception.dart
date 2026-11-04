/// Standard domain and operational exceptions for LabTrack.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.details});
}

class SpecimenException extends AppException {
  const SpecimenException(super.message, {super.code, super.details});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.details});
}
