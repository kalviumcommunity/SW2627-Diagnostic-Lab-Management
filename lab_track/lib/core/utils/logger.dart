import 'package:flutter/foundation.dart';

/// Clinical OS logging service for audit trails and system telemetry.
class AppLogger {
  static void info(String message) {
    debugPrint('[INFO] $message');
  }

  static void warn(String message) {
    debugPrint('[WARN] ⚠️ $message');
  }

  static void error(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('[ERROR] ❌ $message: $error');
    if (stack != null && kDebugMode) {
      debugPrint(stack.toString());
    }
  }
}
