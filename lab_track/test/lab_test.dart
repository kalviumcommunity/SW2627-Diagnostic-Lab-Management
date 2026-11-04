import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lab_track/auth/frontend/providers/auth_provider.dart';
import 'package:lab_track/data/models/report_model.dart';
import 'package:lab_track/data/models/sample_model.dart';
import 'package:lab_track/data/services/central_data_store.dart';
import 'package:lab_track/domain/enums/sample_status.dart';
import 'package:lab_track/domain/enums/user_role.dart';
import 'package:lab_track/lab/backend/services/lab_service.dart';
import 'package:lab_track/lab/frontend/providers/lab_provider.dart';
import 'package:lab_track/lab/frontend/screens/lab_home_screen.dart';
import 'package:lab_track/shared/theme/app_theme.dart';

void main() {
  group('LabService Unit Tests', () {
    test('LabService seeds specimen racks and connected analyzers', () async {
      final service = LabService();

      final racks = await service.getRacks();
      expect(racks.isNotEmpty, isTrue);
      expect(racks.any((r) => r.department == 'Hematology'), isTrue);
      expect(racks.any((r) => r.analyzerName.contains('Sysmex')), isTrue);

      final analyzers = await service.getAnalyzers();
      expect(analyzers.length, greaterThanOrEqualTo(4));
      expect(analyzers.any((a) => a.isOperational), isTrue);
    });

    test('LabService accessions incoming vial and assigns to analyzer rack', () async {
      final service = LabService();
      final barcode = 'SMP-LAB-UNIT-01';

      CentralDataStore.instance.saveSample(SampleModel(
        barcode: barcode,
        orderId: 'ORD-LAB-01',
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        tubeType: 'Purple Top (K2 EDTA)',
        status: SampleStatus.inTransit,
        currentBranchId: 'branch-apex-hq',
        createdAt: DateTime.now(),
      ));

      // Accession incoming specimen
      final accessioned = await service.accessionSpecimen(barcode: barcode);
      expect(accessioned.status, SampleStatus.receivedAtLab);
      expect(accessioned.currentBranchId, 'branch-apex-hq');

      // Assign to rack
      await service.assignToRack(barcode: barcode, rackId: 'RACK-BIO-02');
      final racks = await service.getRacks();
      final targetRack = racks.firstWhere((r) => r.id == 'RACK-BIO-02');
      expect(targetRack.sampleBarcodes.contains(barcode), isTrue);

      final specimens = await service.getSpecimens();
      final updatedSpecimen = specimens.firstWhere((s) => s.barcode == barcode);
      expect(updatedSpecimen.status, SampleStatus.processing);
    });

    test('LabService records pre-analytical QC rejection with recollection trigger', () async {
      final service = LabService();
      final barcode = 'SMP-LAB-QC-01';

      CentralDataStore.instance.saveSample(SampleModel(
        barcode: barcode,
        orderId: 'ORD-LAB-02',
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        tubeType: 'Purple Top (K2 EDTA)',
        status: SampleStatus.receivedAtLab,
        currentBranchId: 'branch-apex-hq',
        createdAt: DateTime.now(),
      ));

      final qc = await service.recordQcRejection(
        barcode: barcode,
        rejectionReason: 'Micro-clots in EDTA Tube',
        clinicalNotes: 'Clot detected on applicator stick inspection.',
      );

      expect(qc.sampleBarcode, barcode);
      expect(qc.recollectionTriggered, isTrue);

      final specimens = await service.getSpecimens();
      final rejected = specimens.firstWhere((s) => s.barcode == barcode);
      expect(rejected.status, SampleStatus.rejected);
    });

    test('LabService saves test findings and pathologist authorizes report', () async {
      final service = LabService();
      final barcode = 'SMP-LAB-REPORT-01';

      CentralDataStore.instance.saveSample(SampleModel(
        barcode: barcode,
        orderId: 'ORD-LAB-03',
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        tubeType: 'Gold Top (SST)',
        testNames: const ['Lipid Profile'],
        status: SampleStatus.receivedAtLab,
        currentBranchId: 'branch-apex-hq',
        createdAt: DateTime.now(),
      ));

      // Enter findings
      final report = await service.enterTestResults(
        sampleBarcode: barcode,
        testName: 'Lipid Profile',
        parameters: const [
          ReportParameter(name: 'Total Cholesterol', value: '190', range: '< 200', flag: 'Normal'),
          ReportParameter(name: 'Triglycerides', value: '130', range: '< 150', flag: 'Normal'),
        ],
      );
      expect(report.sampleBarcode, barcode);
      expect(report.isReady, isFalse);

      // Pathologist sign-off
      final signed = await service.authorizeAndSignReport(
        reportId: report.id,
        pathologistName: 'Dr. Sunita Sen (Senior Pathologist)',
      );
      expect(signed.isReady, isTrue);
      expect(signed.pathologistName, 'Dr. Sunita Sen (Senior Pathologist)');

      final specimens = await service.getSpecimens();
      final sample = specimens.firstWhere((s) => s.barcode == barcode);
      expect(sample.status, SampleStatus.reportReady);
    });
  });

  group('LabProvider State Tests', () {
    test('LabProvider initializes and filters specimens correctly', () async {
      final barcode = 'SMP-VIRENDER-LAB';
      CentralDataStore.instance.saveSample(SampleModel(
        barcode: barcode,
        orderId: 'ORD-VIR-LAB',
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        tubeType: 'Purple Top (K2 EDTA)',
        status: SampleStatus.receivedAtLab,
        currentBranchId: 'branch-apex-hq',
        createdAt: DateTime.now(),
      ));

      final provider = LabProvider();
      await provider.loadAllData();

      expect(provider.isLoading, isFalse);
      expect(provider.racks.isNotEmpty, isTrue);
      expect(provider.analyzers.isNotEmpty, isTrue);

      // Search query filtering
      provider.setSearchQuery('Virender');
      expect(provider.filteredSpecimens.any((s) => s.patientName.contains('Virender')), isTrue);

      // Department filtering
      provider.setDepartmentFilter('Hematology');
      expect(provider.selectedDepartment, 'Hematology');
    });
  });

  group('LabHomeScreen Widget Tests', () {
    testWidgets('Renders LabHomeScreen with KPI bar, quick accession bar, and tab navigation with Aryan', (WidgetTester tester) async {
      CentralDataStore.instance.saveSample(SampleModel(
        barcode: 'SMP-WIDGET',
        orderId: 'ORD-WIDGET',
        patientId: 'PT-VIRENDER',
        patientName: 'Virender',
        status: SampleStatus.processing,
        testNames: const ['CBC'],
      ));
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.labTechnician);
      });

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LabHomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify Header & Credentials show Aryan
      expect(find.text('Laboratory & Pathologist Portal'), findsOneWidget);
      expect(find.text('Aryan'), findsOneWidget);
      expect(find.text('Switch Role'), findsOneWidget);

      // Verify KPI Metric Cards
      expect(find.text('Incoming Couriers'), findsOneWidget);
      expect(find.text('In Central Lab'), findsOneWidget);
      expect(find.text('In Analyzers'), findsOneWidget);
      expect(find.text('Awaiting Sign-Off'), findsOneWidget);
    });
  });
}
