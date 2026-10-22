import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/data/models/report_model.dart';
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
        patientId: 'PT-TEST-01',
        patientName: 'Kunal Singhania',
        patientPhone: '+91 99887 66554',
        selectedTestNames: const ['Complete Blood Count (CBC)', 'Thyroid Panel (T3, T4, TSH)'],
        totalAmount: 1200.0,
        address: 'Flat 101, Palm Court, Sector 23',
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
      final pickups = await phlebotomistService.getAssignedPickups('PH-204');
      expect(pickups.any((o) => o.id == createdOrder.id), isTrue);
      final assignedOrder = pickups.firstWhere((o) => o.id == createdOrder.id);
      expect(assignedOrder.patientName, 'Kunal Singhania');
      expect(assignedOrder.testNames.contains('Complete Blood Count (CBC)'), isTrue);

      // Front Desk immediately finds the booking via phone or order ID
      final searchResults = await frontDeskService.search(query: '9988766554');
      expect(searchResults.any((item) => item.order.id == createdOrder.id), isTrue);
    });

    test('2. Phlebotomist collection updates Patient tracker & Front Desk status', () async {
      final barcode = 'SMP-TEST-BIND-01';

      final collectionRequest = PhlebotomistCollectionRequest(
        orderId: 'ORD-84210',
        sampleBarcode: barcode,
        patientId: 'PT-84210',
        patientName: 'John Doe',
        vialType: 'Purple Top (K2 EDTA)',
        phlebotomistId: 'PH-204',
        phlebotomistName: 'Rahul Verma',
        temperatureCelsius: 4.1,
        locationAddress: 'Sector 14 Patient Home',
        notes: 'Draw successful. Barcode bound at doorstep.',
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
      expect(patientSample.events.any((e) => e.actorName == 'Rahul Verma'), isTrue);

      // Front Desk search displays updated status
      final fdItems = await frontDeskService.search(query: barcode);
      expect(fdItems.isNotEmpty, isTrue);
      expect(fdItems.first.samples.any((s) => s.barcode == barcode), isTrue);
    });

    test('3. Front Desk walk-in requisition propagates immediately to Lab Specimen Queue', () async {
      final walkInRequest = WalkInRequisitionRequest(
        patientName: 'Sanjay Dutt',
        patientPhone: '+91 91234 56789',
        age: 48,
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
      expect(specimen.patientName, 'Sanjay Dutt');
    });

    test('4. Lab result entry & Pathologist authorization unlocks Patient Report', () async {
      final sampleBarcode = 'SMP-77401';

      // 1. Lab technician accessions specimen and enters results
      await labService.accessionSpecimen(barcode: sampleBarcode);

      final report = await labService.enterTestResults(
        sampleBarcode: sampleBarcode,
        testName: 'Complete Blood Count (CBC)',
        parameters: const [
          ReportParameter(name: 'Hemoglobin', value: '15.2', unit: 'g/dL', range: '13.0 - 17.0', flag: 'Normal'),
          ReportParameter(name: 'Platelet Count', value: '280,000', unit: '/uL', range: '150,000 - 450,000', flag: 'Normal'),
        ],
      );
      expect(report.isReady, isFalse);

      // 2. Pathologist digitally signs and authorizes the report
      final signed = await labService.authorizeAndSignReport(
        reportId: report.id,
        pathologistName: 'Dr. Arvind Mehta (MD Path, MCI-4421)',
        clinicalInterpretation: 'Values within standard reference range.',
      );
      expect(signed.isReady, isTrue);
      expect(signed.pathologistName, 'Dr. Arvind Mehta (MD Path, MCI-4421)');

      // 3. Patient sees report ready
      final patientReports = await patientService.getPatientReports(report.patientId);
      expect(patientReports.any((r) => r.id == report.id && r.isReady), isTrue);

      // 4. Sample status is transitioned to reportReady across all roles
      final sample = await patientService.trackSample(sampleBarcode);
      expect(sample?.status, SampleStatus.reportReady);
    });

    test('5. Pre-analytical QC rejection automatically triggers recollection task for Phlebotomist', () async {
      final barcode = 'SMP-88390';

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
      final pickups = await phlebotomistService.getAssignedPickups('PH-204');
      expect(pickups.any((o) => o.specialInstructions?.contains('STAT RE-DRAW') == true), isTrue);
    });
  });
}
