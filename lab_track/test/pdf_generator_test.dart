import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/data/models/report_model.dart';
import 'package:lab_track/data/models/sample_model.dart';
import 'package:lab_track/shared/services/pdf/pdf_report_generator.dart';
import 'package:lab_track/shared/services/pdf/pdf_report_service.dart';

void main() {
  group('Diagnostic PDF Report Generation Engine Tests', () {
    late ReportModel testReport;
    late SampleModel testSample;

    setUp(() {
      testReport = ReportModel(
        id: 'REP-CBC-90214',
        orderId: 'ORD-70014',
        sampleBarcode: 'SMP-90214',
        patientId: 'PT-84210',
        patientName: 'Johnathan Doe',
        status: 'Verified & Ready',
        testName: 'Complete Blood Count (CBC) with Differential',
        branchName: 'Apex Central Reference Laboratory',
        pathologistName: 'Dr. Sarah Chen, MD (Pathology)',
        uploadedAt: DateTime(2026, 11, 1, 10, 30),
        verifiedAt: DateTime(2026, 11, 1, 14, 45),
        testResults: const [
          ReportParameter(
            name: 'Hemoglobin (Hb)',
            value: '14.2',
            unit: 'g/dL',
            range: '13.0 - 17.0',
            flag: 'Normal',
          ),
          ReportParameter(
            name: 'Total Leukocyte Count (WBC)',
            value: '11,400',
            unit: 'cells/mcL',
            range: '4,000 - 11,000',
            flag: 'High',
          ),
          ReportParameter(
            name: 'Platelet Count',
            value: '220,000',
            unit: 'cells/mcL',
            range: '150,000 - 450,000',
            flag: 'Normal',
          ),
        ],
      );

      testSample = SampleModel(
        barcode: 'SMP-90214',
        orderId: 'ORD-70014',
        patientId: 'PT-84210',
        patientName: 'Johnathan Doe',
        tubeType: 'K2 EDTA Purple Top',
        temperatureC: 4.2,
        collectedAt: DateTime(2026, 11, 1, 8, 30),
      );
    });

    test('Generates valid ISO 32000-1 / PDF 1.4 byte stream', () {
      final Uint8List pdfBytes = PdfReportGenerator.generateDiagnosticReport(
        report: testReport,
        sample: testSample,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      final pdfString = latin1.decode(pdfBytes);

      // Verify PDF Magic Header
      expect(pdfString.startsWith('%PDF-1.4'), isTrue);

      // Verify PDF Trailer and End-of-File marker
      expect(pdfString.trim().endsWith('%%EOF'), isTrue);

      // Verify Standard PDF Structural Objects
      expect(pdfString.contains('/Type /Catalog'), isTrue);
      expect(pdfString.contains('/Type /Pages'), isTrue);
      expect(pdfString.contains('/Type /Page'), isTrue);
      expect(pdfString.contains('/Type /Font'), isTrue);
      expect(pdfString.contains('/BaseFont /Helvetica'), isTrue);
      expect(pdfString.contains('/BaseFont /Helvetica-Bold'), isTrue);
      expect(pdfString.contains('xref'), isTrue);
      expect(pdfString.contains('trailer'), isTrue);
      expect(pdfString.contains('startxref'), isTrue);
    });

    test('Contains clinical report metadata, parameters, and pathologist signature', () {
      final Uint8List pdfBytes = PdfReportGenerator.generateDiagnosticReport(
        report: testReport,
        sample: testSample,
      );

      final pdfString = latin1.decode(pdfBytes);

      // Clinic and Accreditation
      expect(pdfString.contains('APEX CENTRAL REFERENCE LABORATORY'), isTrue);
      expect(pdfString.contains('NABL ACCREDITED'), isTrue);

      // Patient Demographics
      expect(pdfString.contains('JOHNATHAN DOE'), isTrue);
      expect(pdfString.contains('SMP-90214'), isTrue);
      expect(pdfString.contains('ORD-70014'), isTrue);

      // Test Parameters
      expect(pdfString.contains('Hemoglobin'), isTrue);
      expect(pdfString.contains('14.2'), isTrue);
      expect(pdfString.contains('Total Leukocyte Count'), isTrue);
      expect(pdfString.contains('11,400'), isTrue);
      expect(pdfString.contains('Platelet Count'), isTrue);

      // Abnormal Flag Alert
      expect(pdfString.contains('HIGH *'), isTrue);

      // Pathologist Electronic Signature
      expect(pdfString.contains('DR. SARAH CHEN'), isTrue);
      expect(pdfString.contains('DIGITALLY AUTHORIZED'), isTrue);

      // Cold Chain Telemetry
      expect(pdfString.contains('4.2 deg C'), isTrue);
    });

    test('PdfReportService generates valid document bytes', () {
      final bytes = PdfReportService.generateReportBytes(
        report: testReport,
        sample: testSample,
      );

      expect(bytes, isNotEmpty);
      final pdfString = latin1.decode(bytes);
      expect(pdfString.startsWith('%PDF-1.4'), isTrue);
      expect(pdfString.contains('OFFICIAL CLINICAL DIAGNOSTIC REPORT'), isTrue);
    });
  });
}
