import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Clinical Report & Document Storage Service.
/// Wraps Firebase Cloud Storage with offline/demo resilience for LabTrack.
class StorageService {
  final FirebaseStorage? _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? _tryGetStorage();

  static FirebaseStorage? _tryGetStorage() {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Uploads generated PDF report bytes to cloud storage under `/reports/{reportId}.pdf`.
  Future<String?> uploadReportPdf({
    required String reportId,
    required Uint8List pdfBytes,
  }) async {
    if (_storage == null) {
      debugPrint('[StorageService] Offline mode active: Simulated cloud upload for report $reportId');
      return 'https://storage.googleapis.com/labtrack-reports/$reportId.pdf';
    }

    try {
      final ref = _storage.ref().child('reports').child('$reportId.pdf');
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'reportId': reportId,
        },
      );
      final uploadTask = await ref.putData(pdfBytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('[StorageService] Upload failed: $e');
      return null;
    }
  }

  /// Retrieves the public or signed URL for a diagnostic PDF report.
  Future<String?> getReportPdfUrl(String reportId) async {
    if (_storage == null) {
      return 'https://storage.googleapis.com/labtrack-reports/$reportId.pdf';
    }

    try {
      final ref = _storage.ref().child('reports').child('$reportId.pdf');
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[StorageService] Failed to retrieve report URL: $e');
      return null;
    }
  }
}
