import 'package:flutter/foundation.dart';
import 'app_exception.dart';

/// Global error handling and logging logic for LabTrack.
class ErrorHandler {
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      debugPrint('[LabTrack Error] ${error.toString()}');
    } else {
      debugPrint('[LabTrack Unhandled Error] $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }

  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
