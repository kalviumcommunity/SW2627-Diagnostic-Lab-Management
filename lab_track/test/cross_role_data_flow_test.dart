import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/data/models/order_model.dart';
import 'package:lab_track/data/models/report_model.dart';
import 'package:lab_track/data/models/sample_model.dart';
import 'package:lab_track/data/services/central_data_store.dart';
import 'package:lab_track/shared/services/pdf/pdf_report_service.dart';
import 'package:lab_track/domain/enums/order_status.dart';
import 'package:lab_track/domain/enums/sample_status.dart';
import 'package:lab_track/frontdesk/backend/models/walk_in_requisition_request.dart';
import 'package:lab_track/frontdesk/backend/services/frontdesk_service.dart';
import 'package:lab_track/lab/backend/services/lab_service.dart';
import 'package:lab_track/patient/backend/models/patient_booking_request.dart';
import 'package:lab_track/patient/backend/services/patient_api_service.dart';
import 'package:lab_track/phlebotomist/backend/models/phlebotomist_collection_request.dart';
import 'package:lab_track/phlebotomist/backend/services/phlebotomist_service.dart';

void main() {
  group('Cross-Role Unified Data Flow Integration Tests', () {
    late PatientApiService patientService;
    late PhlebotomistService phlebotomistService;
    late FrontDeskService frontDeskService;
    late LabService labService;

    setUp(() {
      patientService = PatientApiService();
      phlebotomistService = PhlebotomistService();
      frontDeskService = FrontDeskService();
      labService = LabService();
    });

    test('1. Patient booking propagates directly to Phlebotomist, Front Desk, & Lab', () async {
      final bookingRequest = PatientBookingRequest(
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        patientPhone: '+91 98765 00003',
        selectedTestNames: const ['Complete Blood Count (CBC)', 'Thyroid Panel (T3, T4, TSH)'],
        totalAmount: 1200.0,
        address: 'House 420, Tension Colony, New Delhi',
        scheduledDate: DateTime.now().add(const Duration(hours: 1)),
        timeSlot: '08:00 AM - 09:00 AM',
        branchName: 'Downtown Spoke Center #1',
        notes: 'Fasting required for Thyroid.',
      );

      // Patient books
      final createdOrder = await patientService.submitBooking(bookingRequest);
      expect(createdOrder.id.isNotEmpty, isTrue);
      expect(createdOrder.sampleBarcodes.isNotEmpty, isTrue);

      // Phlebotomist immediately sees the pickup in their assigned queue
      final pickups = await phlebotomistService.getAssignedPickups('PH-PRAVEEN');
      expect(pickups.any((o) => o.id == createdOrder.id), isTrue);
      final assignedOrder = pickups.firstWhere((o) => o.id == createdOrder.id);
      expect(assignedOrder.patientName, 'Virender');
      expect(assignedOrder.testNames.contains('Complete Blood Count (CBC)'), isTrue);

      // Front Desk immediately finds the booking via phone or order ID
      final searchResults = await frontDeskService.search(query: '9876500003');
      expect(searchResults.any((item) => item.order.id == createdOrder.id), isTrue);
    });

    test('2. Phlebotomist collection updates Patient tracker & Front Desk status', () async {
      // First create a live booking
      final bookingRequest = PatientBookingRequest(
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        patientPhone: '+91 98765 00003',
        selectedTestNames: const ['HbA1c Glycated Hemoglobin'],
        totalAmount: 600.0,
        address: 'House 420, Tension Colony',
        scheduledDate: DateTime.now(),
        timeSlot: '10:00 AM - 11:00 AM',
        branchName: 'Downtown Spoke Center #1',
      );
      final order = await patientService.submitBooking(bookingRequest);
      final barcode = order.sampleBarcodes.first;

      final collectionRequest = PhlebotomistCollectionRequest(
        orderId: order.id,
        sampleBarcode: barcode,
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        vialType: 'Purple Top (K2 EDTA)',
        phlebotomistId: 'PH-PRAVEEN',
        phlebotomistName: 'Praveen',
        temperatureCelsius: 4.1,
        locationAddress: 'House 420, Tension Colony',
        notes: 'Doorstep QR verified. Barcode bound.',
      );

      // Phlebotomist confirms doorstep draw
      final collected = await phlebotomistService.confirmCollection(collectionRequest);
      expect(collected.barcode, barcode);
      expect(collected.status, SampleStatus.inTransit);
      expect(collected.temperatureC, 4.1);

      // Patient tracker sees updated status & milestone
      final patientSample = await patientService.trackSample(barcode);
      expect(patientSample, isNotNull);
      expect(patientSample!.status, SampleStatus.inTransit);
      expect(patientSample.events.any((e) => e.actorName == 'Praveen'), isTrue);

      // Front Desk search displays updated status
      final fdItems = await frontDeskService.search(query: barcode);
      expect(fdItems.isNotEmpty, isTrue);
      expect(fdItems.first.samples.any((s) => s.barcode == barcode), isTrue);
    });

    test('3. Front Desk walk-in requisition propagates immediately to Lab Specimen Queue', () async {
      final walkInRequest = WalkInRequisitionRequest(
        patientName: 'Aryan Walk-In',
        patientPhone: '+91 91234 56789',
        age: 24,
        gender: 'Male',
        address: 'Walk-In Spoke Center',
        selectedTestNames: const ['Lipid Profile', 'HbA1c Glycated Hemoglobin'],
        priority: 'Urgent STAT',
        branchId: 'branch-spoke-01',
        branchName: 'Downtown Spoke Center #1',
      );

      // Front Desk generates walk-in requisition
      final labels = await frontDeskService.createWalkInRequisition(walkInRequest);
      expect(labels.isNotEmpty, isTrue);
      final generatedBarcode = labels.first.barcode;

      // Lab Tech immediately sees the walk-in vial in Central Lab specimens list
      final labSpecimens = await labService.getSpecimens();
      expect(labSpecimens.any((s) => s.barcode == generatedBarcode), isTrue);
      final specimen = labSpecimens.firstWhere((s) => s.barcode == generatedBarcode);
      expect(specimen.patientName, 'Aryan Walk-In');
    });

    test('4. Lab result entry & Pathologist authorization unlocks Patient Report', () async {
      // 1. Create a booked & collected sample
      final now = DateTime.now();
      final sampleBarcode = 'SMP-FLOW-TEST-4';
      final orderId = 'ORD-FLOW-TEST-4';

      final order = OrderModel(
        id: orderId,
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        patientPhone: '+91 98765 00003',
        collectionAddress: 'House 420, Tension Colony',
        testNames: const ['Complete Blood Count (CBC) with Differential'],
        totalAmount: 850.0,
        scheduledDate: now,
        timeSlot: '09:00 AM - 10:00 AM',
        branchId: 'branch-spoke-01',
        branchName: 'Downtown Spoke Center #1',
        status: OrderStatus.inProgress,
        sampleBarcodes: [sampleBarcode],
        assignedPhlebotomistId: 'PH-PRAVEEN',
        assignedPhlebotomistName: 'Praveen',
        createdAt: now,
      );
      final sample = SampleModel(
        barcode: sampleBarcode,
        orderId: orderId,
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        tubeType: 'Purple Top (K2 EDTA)',
        status: SampleStatus.inTransit,
        currentBranchId: 'branch-apex-hq',
        createdAt: now,
      );
      CentralDataStore.instance.createOrder(order);
      CentralDataStore.instance.saveSample(sample);

      // 2. Lab technician accessions specimen and enters results
      await labService.accessionSpecimen(barcode: sampleBarcode);

      final report = await labService.enterTestResults(
        sampleBarcode: sampleBarcode,
        testName: 'Complete Blood Count (CBC) with Differential',
        parameters: const [
          ReportParameter(name: 'Hemoglobin', value: '15.2', unit: 'g/dL', range: '13.0 - 17.0', flag: 'Normal'),
          ReportParameter(name: 'Platelet Count', value: '280,000', unit: '/uL', range: '150,000 - 450,000', flag: 'Normal'),
        ],
      );
      expect(report.isReady, isFalse);

      // 3. Pathologist digitally signs and authorizes the report
      final signed = await labService.authorizeAndSignReport(
        reportId: report.id,
        pathologistName: 'Dr. Sarah Chen, MD (Pathology)',
        clinicalInterpretation: 'Values within standard reference range.',
      );
      expect(signed.isReady, isTrue);
      expect(signed.pathologistName, 'Dr. Sarah Chen, MD (Pathology)');

      // 4. Patient sees report ready
      final patientReports = await patientService.getPatientReports(report.patientId);
      expect(patientReports.any((r) => r.id == report.id && r.isReady), isTrue);

      // 5. Sample status is transitioned to reportReady across all roles
      final trackedSample = await patientService.trackSample(sampleBarcode);
      expect(trackedSample?.status, SampleStatus.reportReady);
    });

    test('5. Pre-analytical QC rejection automatically triggers recollection task for Phlebotomist', () async {
      final now = DateTime.now();
      final barcode = 'SMP-QC-REJECT-TEST';
      final orderId = 'ORD-QC-TEST';

      final sample = SampleModel(
        barcode: barcode,
        orderId: orderId,
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        patientPhone: '+91 98765 00003',
        tubeType: 'Purple Top (K2 EDTA)',
        status: SampleStatus.receivedAtLab,
        currentBranchId: 'branch-apex-hq',
        createdAt: now,
      );
      CentralDataStore.instance.saveSample(sample);

      // Lab technician flags sample as rejected
      final qc = await labService.recordQcRejection(
        barcode: barcode,
        rejectionReason: 'Hemolyzed Specimen (Free Hb > 500mg/dL)',
        clinicalNotes: 'Mechanical rupture of erythrocytes. Invalidates Potassium reading.',
      );

      expect(qc.recollectionTriggered, isTrue);

      // Sample status is updated to rejected
      final rejectedSample = await patientService.trackSample(barcode);
      expect(rejectedSample?.status, SampleStatus.rejected);

      // Phlebotomist automatically receives a new recollection order in their queue
      final pickups = await phlebotomistService.getAssignedPickups('PH-PRAVEEN');
      expect(pickups.any((o) => o.specialInstructions?.contains('STAT RE-DRAW') == true), isTrue);
    });

    test('6. Pathologist authorization generates authenticated standard PDF report document', () async {
      final now = DateTime.now();
      final sampleBarcode = 'SMP-PDF-TEST-01';
      final orderId = 'ORD-PDF-TEST-01';

      final sample = SampleModel(
        barcode: sampleBarcode,
        orderId: orderId,
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        tubeType: 'Purple Top (K2 EDTA)',
        status: SampleStatus.receivedAtLab,
        currentBranchId: 'branch-apex-hq',
        createdAt: now,
      );
      CentralDataStore.instance.saveSample(sample);

      final report = await labService.enterTestResults(
        sampleBarcode: sampleBarcode,
        testName: 'Complete Blood Count (CBC) with Differential',
        parameters: const [
          ReportParameter(name: 'Hemoglobin (Hb)', value: '14.5', unit: 'g/dL', range: '13.0 - 17.0', flag: 'Normal'),
          ReportParameter(name: 'Platelet Count', value: '250,000', unit: 'cells/mcL', range: '150,000 - 450,000', flag: 'Normal'),
        ],
      );

      final signedReport = await labService.authorizeAndSignReport(
        reportId: report.id,
        pathologistName: 'Dr. Sarah Chen, MD (Pathology)',
        clinicalInterpretation: 'Hemogram parameters within normal biological reference intervals.',
      );

      // Generate standard ISO PDF bytes
      final pdfBytes = PdfReportService.generateReportBytes(report: signedReport);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      final pdfString = latin1.decode(pdfBytes);
      expect(pdfString.startsWith('%PDF-1.4'), isTrue);
      expect(pdfString.trim().endsWith('%%EOF'), isTrue);
      expect(pdfString.contains('APEX CENTRAL REFERENCE LABORATORY'), isTrue);
      expect(pdfString.contains('DR. SARAH CHEN'), isTrue);
      expect(pdfString.contains(sampleBarcode), isTrue);
    });
  });
}
