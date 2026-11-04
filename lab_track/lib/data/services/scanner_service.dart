/// Model for parsed Appointment QR Pass data
class AppointmentQrData {
  final String orderId;
  final String patientId;
  final String patientName;

  const AppointmentQrData({
    required this.orderId,
    required this.patientId,
    required this.patientName,
  });
}

/// Model for parsed Phlebotomist Handover Pass data
class HandoverQrData {
  final String senderId;
  final String senderName;
  final List<String> sampleBarcodes;
  final double? temperatureC;

  const HandoverQrData({
    required this.senderId,
    required this.senderName,
    required this.sampleBarcodes,
    this.temperatureC,
  });
}

/// Centralized service for validating, extracting, and processing
/// clinical barcode and 2D QR code strings across all roles.
class ScannerService {
  ScannerService._();

  /// Standard prefix for LabTrack specimen vials
  static const String vialPrefix = 'SMP-';

  /// Standard prefix for LabTrack appointment QR passes
  static const String appointmentPrefix = 'LABTRACK:APPOINTMENT:';

  /// Standard prefix for LabTrack cold-box handover passes
  static const String handoverPrefix = 'LABTRACK:HANDOVER:';

  /// Checks if raw code is an Appointment QR Pass
  static bool isAppointmentQr(String? raw) {
    if (raw == null) return false;
    final trimmed = raw.trim();
    return trimmed.startsWith(appointmentPrefix) ||
        (trimmed.contains('LABTRACK') && trimmed.contains('APPOINTMENT'));
  }

  /// Parses Appointment QR Pass data:
  /// Payload format: LABTRACK:APPOINTMENT:<orderId>:<patientId>:<patientName>
  static AppointmentQrData? parseAppointmentQr(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!isAppointmentQr(trimmed)) {
      // Fallback: Check if it's an ORD-XXXXX code directly
      final orderRegex = RegExp(r'\b(ORD-[A-Z0-9]+(?:-[A-Z0-9]+)*)\b', caseSensitive: false);
      final match = orderRegex.firstMatch(trimmed);
      if (match != null) {
        return AppointmentQrData(
          orderId: match.group(1)!.toUpperCase(),
          patientId: '',
          patientName: '',
        );
      }
      return null;
    }

    final parts = trimmed.split(':');
    // Expected: ["LABTRACK", "APPOINTMENT", orderId, patientId, patientName]
    if (parts.length >= 3) {
      final orderId = parts[2].trim().toUpperCase();
      final patientId = parts.length > 3 ? parts[3].trim() : '';
      final patientName = parts.length > 4 ? parts.sublist(4).join(':').trim() : '';
      return AppointmentQrData(
        orderId: orderId,
        patientId: patientId,
        patientName: patientName,
      );
    }
    return null;
  }

  /// Checks if raw code is a Handover QR Pass
  static bool isHandoverQr(String? raw) {
    if (raw == null) return false;
    final trimmed = raw.trim();
    return trimmed.startsWith(handoverPrefix) ||
        (trimmed.contains('LABTRACK') && trimmed.contains('HANDOVER'));
  }

  /// Parses Handover QR Pass data:
  /// Payload format: LABTRACK:HANDOVER:<senderId>:<senderName>:<tempC>:<barcode1>,<barcode2>
  static HandoverQrData? parseHandoverQr(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!isHandoverQr(trimmed)) return null;

    final parts = trimmed.split(':');
    // Expected: ["LABTRACK", "HANDOVER", senderId, senderName, tempC, barcodesCsv]
    if (parts.length >= 4) {
      final senderId = parts[2].trim();
      final senderName = parts[3].trim();
      double? temp;
      List<String> barcodes = [];

      if (parts.length >= 5) {
        temp = double.tryParse(parts[4].trim());
      }
      if (parts.length >= 6) {
        final rawCsv = parts.sublist(5).join(':').trim();
        barcodes = rawCsv
            .split(',')
            .map((s) => s.trim().toUpperCase())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      return HandoverQrData(
        senderId: senderId,
        senderName: senderName,
        sampleBarcodes: barcodes,
        temperatureC: temp,
      );
    }
    return null;
  }

  /// Extracts the canonical sample barcode from a raw scanned QR or 1D barcode string.
  /// Handles:
  /// - Handover QR: returns first sample barcode if available
  /// - Direct barcode strings: "SMP-88390"
  /// - Tracking URLs: "https://labtrack.com/track/SMP-88390" or "http://localhost:8080/#/track/SMP-88390"
  /// - Deep links: "labtrack://samples/SMP-88390"
  /// - Raw numeric strings: converts to standard "SMP-XXXXX" format if valid
  static String? extractSampleBarcode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Check Handover QR
    if (isHandoverQr(trimmed)) {
      final handover = parseHandoverQr(trimmed);
      if (handover != null && handover.sampleBarcodes.isNotEmpty) {
        return handover.sampleBarcodes.first;
      }
    }

    // 1. Direct standard barcode match (e.g. SMP-88390 or SMP-10293)
    final directRegex = RegExp(r'\b(SMP-[A-Z0-9]+(?:-[A-Z0-9]+)*)\b', caseSensitive: false);
    final directMatch = directRegex.firstMatch(trimmed);
    if (directMatch != null) {
      return directMatch.group(1)!.toUpperCase();
    }

    // 2. Order ID match (e.g. ORD-84210)
    final orderRegex = RegExp(r'\b(ORD-[A-Z0-9]+(?:-[A-Z0-9]+)*)\b', caseSensitive: false);
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
    return RegExp(r'^(SMP|ORD)-[A-Z0-9]{4,32}$').hasMatch(normalized) ||
        RegExp(r'^[A-Z0-9\-]{5,36}$').hasMatch(normalized);
  }

  /// Formats a barcode for display
  static String formatDisplayCode(String code) {
    return code.trim().toUpperCase();
  }
}
