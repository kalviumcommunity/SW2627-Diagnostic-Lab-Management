import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/config/firebase_options.dart';
import '../lib/domain/enums/order_status.dart';
import '../lib/domain/enums/sample_status.dart';
import '../lib/domain/enums/user_role.dart';
import '../lib/data/models/order_model.dart';
import '../lib/data/models/sample_model.dart';
import '../lib/data/models/sample_event_model.dart';
import '../lib/data/models/report_model.dart';
import '../lib/data/mock/seed_users.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('--- Seeding Cloud Firestore for LabTrack ---');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase already initialized or notice: $e');
  }

  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();

  // 0. Seed Users (100 Users across Patient, Phlebotomist, Lab Tech, Front Desk, Admin)
  debugPrint('--- Seeding ${kSeedUsers.length} Users into /users collection ---');
  for (final user in kSeedUsers) {
    await firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
    debugPrint('Seeded User [${user.role.name}]: ${user.id} (${user.name})');
  }
  debugPrint('Successfully seeded ${kSeedUsers.length} users into /users.');

  // 1. Seed Orders
  final orders = [
    OrderModel(
      id: 'ORD-84210',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      patientPhone: '+91 98765 43210',
      collectionAddress: 'Apartment 4B, Sunrise Residency, Sector 14, Gurugram',
      testNames: const [
        'Thyroid Panel (T3, T4, TSH)',
        'HbA1c Glycated Hemoglobin',
        'Complete Blood Count (CBC)'
      ],
      totalAmount: 1450.0,
      scheduledDate: now.subtract(const Duration(hours: 4)),
      timeSlot: '07:30 AM - 08:30 AM',
      branchId: 'BR-004',
      branchName: 'Branch Hub 4 - Central',
      status: OrderStatus.inProgress,
      sampleBarcodes: const ['SMP-88390', 'SMP-77219'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      specialInstructions: 'Patient is diabetic; 10-hour fasting sample required. Ring 4B.',
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    ),
    OrderModel(
      id: 'ORD-84212',
      patientId: 'PT-91024',
      patientName: 'Meena Gupta',
      patientPhone: '+91 98112 34567',
      collectionAddress: 'House 142, Block C, Green Glen Layout, Sector 18',
      testNames: const ['Lipid Profile', 'Fasting Blood Sugar (FBS)', 'Serum Creatinine'],
      totalAmount: 1800.0,
      scheduledDate: now,
      timeSlot: '08:45 AM - 09:30 AM (Fasting)',
      branchId: 'BR-004',
      branchName: 'Branch Hub 4 - Central',
      status: OrderStatus.confirmed,
      sampleBarcodes: const ['SMP-90214'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      specialInstructions: 'Senior citizen; please handle gently during venipuncture.',
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 3)),
    ),
    OrderModel(
      id: 'ORD-84215',
      patientId: 'PT-60291',
      patientName: 'Rajesh Khanna',
      patientPhone: '+91 99887 66554',
      collectionAddress: 'Tower 2, Flat 1102, DLF Phase 5',
      testNames: const ['Liver Function Test (LFT)', 'Vitamin D3 (25-OH)', 'Vitamin B12'],
      totalAmount: 2200.0,
      scheduledDate: now.add(const Duration(hours: 2)),
      timeSlot: '11:00 AM - 12:00 PM',
      branchId: 'BR-004',
      branchName: 'Branch Hub 4 - Central',
      status: OrderStatus.confirmed,
      sampleBarcodes: const ['SMP-66102'],
      assignedPhlebotomistId: 'PH-204',
      assignedPhlebotomistName: 'Rahul Verma',
      specialInstructions: 'Call 15 minutes before arrival at main gate security.',
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    ),
  ];

  for (final order in orders) {
    await firestore.collection('orders').doc(order.id).set(order.toMap());
    debugPrint('Seeded Order: ${order.id}');
  }

  // 2. Seed Samples
  final samples = [
    SampleModel(
      barcode: 'SMP-88390',
      orderId: 'ORD-84210',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      patientPhone: '+91 98765 43210',
      tubeType: 'Gold Top (SST Serum Gel)',
      status: SampleStatus.inTransit,
      currentCustodianId: 'PH-204',
      currentCustodianRole: UserRole.phlebotomist.name,
      currentBranchId: 'BR-004',
      currentBranchName: 'Branch Hub 4 - Courier Bag #12',
      assignedPhlebotomistName: 'Rahul Verma',
      collectedAt: now.subtract(const Duration(hours: 3)),
      temperatureC: 4.2,
      lastEventAt: now.subtract(const Duration(hours: 1)),
      createdAt: now.subtract(const Duration(hours: 6)),
      testNames: const ['Thyroid Panel (T3, T4, TSH)', 'HbA1c'],
      notes: 'Phlebotomist transferred vial to Courier Bag. Expected testing at Central Lab.',
    ),
    SampleModel(
      barcode: 'SMP-77219',
      orderId: 'ORD-84210',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      patientPhone: '+91 98765 43210',
      tubeType: 'Purple Top (K2 EDTA)',
      status: SampleStatus.reportReady,
      currentCustodianId: 'LAB-001',
      currentCustodianRole: UserRole.labTechnician.name,
      currentBranchId: 'BR-CENTRAL',
      currentBranchName: 'Central Diagnostic Lab',
      assignedPhlebotomistName: 'Rahul Verma',
      collectedAt: now.subtract(const Duration(hours: 4)),
      temperatureC: 4.0,
      lastEventAt: now.subtract(const Duration(minutes: 30)),
      createdAt: now.subtract(const Duration(hours: 6)),
      testNames: const ['Complete Blood Count (CBC)'],
      notes: 'Analysis completed on Sysmex XN-1000. Verified by Chief Pathologist.',
    ),
    SampleModel(
      barcode: 'SMP-90214',
      orderId: 'ORD-84212',
      patientId: 'PT-91024',
      patientName: 'Meena Gupta',
      patientPhone: '+91 98112 34567',
      tubeType: 'Grey Top (Sodium Fluoride)',
      status: SampleStatus.booked,
      currentCustodianId: 'PH-204',
      currentCustodianRole: UserRole.phlebotomist.name,
      currentBranchId: 'BR-004',
      currentBranchName: 'Branch Hub 4 - Central',
      assignedPhlebotomistName: 'Rahul Verma',
      collectedAt: null,
      temperatureC: null,
      lastEventAt: now.subtract(const Duration(hours: 3)),
      createdAt: now.subtract(const Duration(hours: 3)),
      testNames: const ['Lipid Profile', 'Fasting Blood Sugar (FBS)'],
      notes: 'Scheduled for doorstep morning collection.',
    ),
    SampleModel(
      barcode: 'SMP-66102',
      orderId: 'ORD-84215',
      patientId: 'PT-60291',
      patientName: 'Rajesh Khanna',
      patientPhone: '+91 99887 66554',
      tubeType: 'Gold Top (SST Serum Gel)',
      status: SampleStatus.booked,
      currentCustodianId: 'PH-204',
      currentCustodianRole: UserRole.phlebotomist.name,
      currentBranchId: 'BR-004',
      currentBranchName: 'Branch Hub 4 - Central',
      assignedPhlebotomistName: 'Rahul Verma',
      collectedAt: null,
      temperatureC: null,
      lastEventAt: now.subtract(const Duration(hours: 1)),
      createdAt: now.subtract(const Duration(hours: 1)),
      testNames: const ['Liver Function Test (LFT)', 'Vitamin D3 (25-OH)'],
      notes: 'Upcoming appointment.',
    ),
  ];

  for (final sample in samples) {
    await firestore.collection('samples').doc(sample.barcode).set(sample.toMap());
    debugPrint('Seeded Sample: ${sample.barcode}');
  }

  // 3. Seed Sample Events (Immutable Audit Log)
  final events = [
    SampleEventModel(
      id: 'EV-88390-1',
      sampleBarcode: 'SMP-88390',
      orderId: 'ORD-84210',
      fromStatus: null,
      toStatus: SampleStatus.booked,
      timestamp: now.subtract(const Duration(hours: 6)),
      actorId: 'PT-84210',
      actorName: 'John Doe',
      actorRole: UserRole.patient,
      branchId: 'BR-004',
      note: 'Home collection appointment booked online.',
    ),
    SampleEventModel(
      id: 'EV-88390-2',
      sampleBarcode: 'SMP-88390',
      orderId: 'ORD-84210',
      fromStatus: SampleStatus.booked,
      toStatus: SampleStatus.collected,
      timestamp: now.subtract(const Duration(hours: 3)),
      actorId: 'PH-204',
      actorName: 'Rahul Verma (Phlebotomist)',
      actorRole: UserRole.phlebotomist,
      branchId: 'Sector 14 Gurugram',
      latitude: 28.4595,
      longitude: 77.0266,
      temperatureC: 4.0,
      note: 'Specimen drawn & sealed in gel cold carrier.',
    ),
    SampleEventModel(
      id: 'EV-88390-3',
      sampleBarcode: 'SMP-88390',
      orderId: 'ORD-84210',
      fromStatus: SampleStatus.collected,
      toStatus: SampleStatus.inTransit,
      timestamp: now.subtract(const Duration(hours: 1)),
      actorId: 'PH-204',
      actorName: 'Rahul Verma (Phlebotomist)',
      actorRole: UserRole.phlebotomist,
      branchId: 'BR-004',
      temperatureC: 4.2,
      note: 'Handed over to cold-chain courier van.',
    ),
    SampleEventModel(
      id: 'EV-77219-1',
      sampleBarcode: 'SMP-77219',
      orderId: 'ORD-84210',
      fromStatus: null,
      toStatus: SampleStatus.booked,
      timestamp: now.subtract(const Duration(hours: 6)),
      actorId: 'PT-84210',
      actorName: 'John Doe',
      actorRole: UserRole.patient,
      branchId: 'BR-004',
      note: 'Order placed.',
    ),
    SampleEventModel(
      id: 'EV-77219-2',
      sampleBarcode: 'SMP-77219',
      orderId: 'ORD-84210',
      fromStatus: SampleStatus.booked,
      toStatus: SampleStatus.collected,
      timestamp: now.subtract(const Duration(hours: 4)),
      actorId: 'PH-204',
      actorName: 'Rahul Verma',
      actorRole: UserRole.phlebotomist,
      branchId: 'Sector 14 Gurugram',
      temperatureC: 3.9,
      note: 'Doorstep EDTA tube accessioned.',
    ),
    SampleEventModel(
      id: 'EV-77219-3',
      sampleBarcode: 'SMP-77219',
      orderId: 'ORD-84210',
      fromStatus: SampleStatus.collected,
      toStatus: SampleStatus.inTransit,
      timestamp: now.subtract(const Duration(hours: 3)),
      actorId: 'PH-204',
      actorName: 'Rahul Verma',
      actorRole: UserRole.phlebotomist,
      branchId: 'BR-004',
      temperatureC: 4.1,
      note: 'In transit to central laboratory.',
    ),
    SampleEventModel(
      id: 'EV-77219-4',
      sampleBarcode: 'SMP-77219',
      orderId: 'ORD-84210',
      fromStatus: SampleStatus.inTransit,
      toStatus: SampleStatus.receivedAtLab,
      timestamp: now.subtract(const Duration(hours: 2)),
      actorId: 'LAB-001',
      actorName: 'Lab Intake Tech',
      actorRole: UserRole.labTechnician,
      branchId: 'BR-CENTRAL',
      temperatureC: 4.0,
      note: 'Barcode scanned at central lab accessioning bench.',
    ),
    SampleEventModel(
      id: 'EV-77219-5',
      sampleBarcode: 'SMP-77219',
      orderId: 'ORD-84210',
      fromStatus: SampleStatus.receivedAtLab,
      toStatus: SampleStatus.processing,
      timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
      actorId: 'LAB-001',
      actorName: 'Lab Testing Tech',
      actorRole: UserRole.labTechnician,
      branchId: 'BR-CENTRAL',
      note: 'Loaded on Sysmex automated hematology analyzer.',
    ),
    SampleEventModel(
      id: 'EV-77219-6',
      sampleBarcode: 'SMP-77219',
      orderId: 'ORD-84210',
      fromStatus: SampleStatus.processing,
      toStatus: SampleStatus.reportReady,
      timestamp: now.subtract(const Duration(minutes: 30)),
      actorId: 'LAB-001',
      actorName: 'Dr. Ananya Roy (Chief Pathologist)',
      actorRole: UserRole.labTechnician,
      branchId: 'BR-CENTRAL',
      note: 'Results verified and digital PDF signed.',
    ),
  ];

  for (final event in events) {
    await firestore.collection('sample_events').doc(event.id).set(event.toMap());
    debugPrint('Seeded Event: ${event.id}');
  }

  // 4. Seed Reports
  final reports = [
    ReportModel(
      id: 'RPT-84210',
      orderId: 'ORD-84210',
      sampleBarcode: 'SMP-77219',
      patientId: 'PT-84210',
      patientName: 'John Doe',
      status: 'Verified',
      pdfUrl: 'https://storage.googleapis.com/labtrack-reports/sample-cbc-report.pdf',
      uploadedById: 'Dr. Ananya Roy (MD Pathology)',
      uploadedAt: now.subtract(const Duration(minutes: 30)),
      verifiedAt: now.subtract(const Duration(minutes: 25)),
      testName: 'Complete Blood Count (CBC)',
      branchName: 'Central Diagnostic Lab',
      testResults: const [
        ReportParameter(
          name: 'Hemoglobin (Hb)',
          value: '14.2',
          unit: 'g/dL',
          range: '13.0 - 17.0',
          flag: 'Normal',
        ),
        ReportParameter(
          name: 'Total Leucocyte Count (TLC)',
          value: '11,800',
          unit: '/cumm',
          range: '4,000 - 11,000',
          flag: 'High',
        ),
        ReportParameter(
          name: 'Platelet Count',
          value: '2.4',
          unit: 'lakh/cumm',
          range: '1.5 - 4.5',
          flag: 'Normal',
        ),
        ReportParameter(
          name: 'Packed Cell Volume (PCV)',
          value: '43.5',
          unit: '%',
          range: '40.0 - 50.0',
          flag: 'Normal',
        ),
        ReportParameter(
          name: 'Neutrophils',
          value: '68',
          unit: '%',
          range: '40 - 70',
          flag: 'Normal',
        ),
        ReportParameter(
          name: 'Lymphocytes',
          value: '24',
          unit: '%',
          range: '20 - 45',
          flag: 'Normal',
        ),
      ],
    ),
  ];

  for (final report in reports) {
    await firestore.collection('reports').doc(report.id).set(report.toMap());
    debugPrint('Seeded Report: ${report.id}');
  }

  debugPrint('--- Firestore Seeding Successfully Finished ---');
}
