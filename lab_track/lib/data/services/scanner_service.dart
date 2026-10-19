import 'package:flutter/foundation.dart';

/// Centralized service for validating, extracting, and processing
/// clinical barcode and 2D QR code strings across all roles.
class ScannerService {
  ScannerService._();

  /// Standard prefix for LabTrack specimen vials
  static const String vialPrefix = 'SMP-';

  /// Extracts the canonical sample barcode from a raw scanned QR or 1D barcode string.
  /// Handles:
  /// - Direct barcode strings: "SMP-88390"
  /// - Tracking URLs: "https://labtrack.com/track/SMP-88390" or "http://localhost:8080/#/track/SMP-88390"
  /// - Deep links: "labtrack://samples/SMP-88390"
  /// - Raw numeric strings: converts to standard "SMP-XXXXX" format if valid
  static String? extractSampleBarcode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Direct standard barcode match (e.g. SMP-88390 or SMP-10293)
    final directRegex = RegExp(r'\b(SMP-\d{4,8})\b', caseSensitive: false);
    final directMatch = directRegex.firstMatch(trimmed);
    if (directMatch != null) {
      return directMatch.group(1)!.toUpperCase();
    }

    // 2. Order ID match (e.g. ORD-84210)
    final orderRegex = RegExp(r'\b(ORD-\d{4,8})\b', caseSensitive: false);
    final orderMatch = orderRegex.firstMatch(trimmed);
    if (orderMatch != null) {
      return orderMatch.group(1)!.toUpperCase();
    }

    // 3. Fallback for plain alphanumeric barcodes (e.g. 5-12 characters)
    final cleanAlpha = trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
    if (cleanAlpha.length >= 4 && cleanAlpha.length <= 20) {
      return cleanAlpha.toUpperCase();
    }

    return trimmed.toUpperCase();
  }

  /// Validates whether a barcode string is in a standard accepted diagnostic format.
  static bool isValidSampleBarcode(String? code) {
    if (code == null || code.trim().isEmpty) return false;
    final normalized = code.trim().toUpperCase();
    // SMP-XXXX or standard alphanumeric
    return RegExp(r'^(SMP|ORD)-[A-Z0-9]{4,10}$').hasMatch(normalized) ||
        RegExp(r'^[A-Z0-9\-]{5,20}$').hasMatch(normalized);
  }

  /// Formats a barcode for display
  static String formatDisplayCode(String code) {
    return code.trim().toUpperCase();
  }
}
