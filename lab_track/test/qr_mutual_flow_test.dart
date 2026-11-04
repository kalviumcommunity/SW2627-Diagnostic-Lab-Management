import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/data/models/order_model.dart';
import 'package:lab_track/data/models/sample_model.dart';
import 'package:lab_track/data/services/central_data_store.dart';
import 'package:lab_track/data/services/scanner_service.dart';
import 'package:lab_track/domain/enums/order_status.dart';
import 'package:lab_track/domain/enums/sample_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mutual Real-Time QR Scanning & Handover Tests', () {
    test('1. ScannerService correctly validates and parses Appointment QR Pass', () {
      const payload = 'LABTRACK:APPOINTMENT:ORD-84210:PT-VIRENDER:Virender';
      expect(ScannerService.isAppointmentQr(payload), isTrue);

      final data = ScannerService.parseAppointmentQr(payload);
      expect(data, isNotNull);
      expect(data!.orderId, equals('ORD-84210'));
      expect(data.patientId, equals('PT-VIRENDER'));
      expect(data.patientName, equals('Virender'));

      // Test fallback to plain ORD code
      final plainData = ScannerService.parseAppointmentQr('ORD-99123');
      expect(plainData, isNotNull);
      expect(plainData!.orderId, equals('ORD-99123'));
    });

    test('2. ScannerService correctly validates and parses Cold-Box Handover Pass', () {
      const payload = 'LABTRACK:HANDOVER:PH-PRAVEEN:Praveen:4.2:SMP-88390,SMP-10293';
      expect(ScannerService.isHandoverQr(payload), isTrue);

      final data = ScannerService.parseHandoverQr(payload);
      expect(data, isNotNull);
      expect(data!.senderId, equals('PH-PRAVEEN'));
      expect(data.senderName, equals('Praveen'));
      expect(data.temperatureC, equals(4.2));
      expect(data.sampleBarcodes, equals(['SMP-88390', 'SMP-10293']));
    });

    test('3. Phlebotomist Doorstep Verification updates OrderModel with doorstepVerifiedAt', () {
      final store = CentralDataStore.instance;

      // Seed an order for Virender if none exists
      final testOrder = OrderModel(
        id: 'ORD-TEST-001',
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        patientPhone: '+91 98765 43210',
        collectionAddress: 'Flat 402, Lotus Arena, Sector 79, Gurugram',
        testNames: ['Complete Blood Count (CBC)'],
        totalAmount: 499.0,
        scheduledDate: DateTime.now(),
        timeSlot: '08:00 AM - 09:00 AM',
        branchId: 'BR-004',
        branchName: 'Central Diagnostic Hub 4',
        createdAt: DateTime.now(),
      );
      store.createOrder(testOrder);

      // Verify pass using appointment QR string
      final verified = store.verifyPatientDoorstepPass(
        orderId: 'LABTRACK:APPOINTMENT:ORD-TEST-001:PT-VIRENDER:Virender',
        phlebotomistId: 'PH-PRAVEEN',
        phlebotomistName: 'Praveen',
      );

      expect(verified, isNotNull);
      expect(verified!.id, equals('ORD-TEST-001'));
      expect(verified.doorstepVerifiedAt, isNotNull);
      expect(verified.status, equals(OrderStatus.inProgress));
      expect(verified.assignedPhlebotomistId, equals('PH-PRAVEEN'));
      expect(verified.assignedPhlebotomistName, equals('Praveen'));
    });

    test('4. Phlebotomist Collection binds sample and sets inTransit custody', () {
      final store = CentralDataStore.instance;

      store.confirmPhlebotomistCollection(
        orderId: 'ORD-TEST-001',
        sampleBarcode: 'SMP-TEST-999',
        tubeType: 'EDTA Vacutainer (Lavender Cap)',
        temperature: 4.2,
        phlebotomistId: 'PH-PRAVEEN',
        phlebotomistName: 'Praveen',
      );

      final sample = store.getSample('SMP-TEST-999');
      expect(sample, isNotNull);
      expect(sample!.status, equals(SampleStatus.inTransit));
      expect(sample.currentCustodianId, equals('PH-PRAVEEN'));
      expect(sample.temperatureC, equals(4.2));
    });

    test('5. Lab Tech Aryan accessions batch handover into Central Reference Lab', () {
      final store = CentralDataStore.instance;

      // Accession via batch handover pass
      const handoverQr = 'LABTRACK:HANDOVER:PH-PRAVEEN:Praveen:4.2:SMP-TEST-999';
      final accessioned = store.accessionSpecimen(
        barcode: handoverQr,
        technicianName: 'Aryan (#LAB-ARYAN)',
      );

      expect(accessioned, isNotNull);
      expect(accessioned!.barcode, equals('SMP-TEST-999'));
      expect(accessioned.status, equals(SampleStatus.receivedAtLab));
      expect(accessioned.currentCustodianId, equals('LAB-ARYAN'));
      expect(accessioned.currentCustodianRole, equals('Lab Technician'));
      expect(accessioned.currentBranchName, contains('Central Reference Laboratory'));

      // Verify audit trail contains milestone event
      expect(accessioned.events.any((e) => e.toStatus == SampleStatus.receivedAtLab), isTrue);
    });
  });
}

