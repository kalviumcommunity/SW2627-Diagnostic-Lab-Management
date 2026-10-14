import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lab_track/auth/frontend/providers/auth_provider.dart';
import 'package:lab_track/data/models/report_model.dart';
import 'package:lab_track/domain/enums/sample_status.dart';
import 'package:lab_track/domain/enums/user_role.dart';
import 'package:lab_track/lab/backend/services/lab_service.dart';
import 'package:lab_track/lab/frontend/providers/lab_provider.dart';
import 'package:lab_track/lab/frontend/screens/lab_home_screen.dart';
import 'package:lab_track/shared/theme/app_theme.dart';

void main() {
  group('LabService Unit Tests', () {
    test('LabService seeds specimen racks, connected analyzers, and diagnostic reports', () async {
      final service = LabService();

      final racks = await service.getRacks();
      expect(racks.isNotEmpty, isTrue);
      expect(racks.any((r) => r.department == 'Hematology'), isTrue);
      expect(racks.any((r) => r.analyzerName.contains('Sysmex')), isTrue);

      final analyzers = await service.getAnalyzers();
      expect(analyzers.length, greaterThanOrEqualTo(4));
      expect(analyzers.any((a) => a.isOperational), isTrue);

      final specimens = await service.getSpecimens();
      expect(specimens.isNotEmpty, isTrue);

      final reports = await service.getReports();
      expect(reports.isNotEmpty, isTrue);
      expect(reports.any((r) => r.status.contains('Pending')), isTrue);

      final qcs = await service.getQcRejections();
      expect(qcs.isNotEmpty, isTrue);
      expect(qcs.any((q) => q.rejectionReason.contains('Hemolyzed')), isTrue);
    });

    test('LabService accessions incoming vial and assigns to analyzer rack', () async {
      final service = LabService();

      // Accession incoming specimen
      final accessioned = await service.accessionSpecimen(barcode: 'SMP-90214');
      expect(accessioned.status, SampleStatus.receivedAtLab);
      expect(accessioned.currentBranchId, 'branch-apex-hq');

      // Assign to rack
      await service.assignToRack(barcode: 'SMP-90214', rackId: 'RACK-HEM-01');
      final racks = await service.getRacks();
      final targetRack = racks.firstWhere((r) => r.id == 'RACK-HEM-01');
      expect(targetRack.sampleBarcodes.contains('SMP-90214'), isTrue);

      final specimens = await service.getSpecimens();
      final updatedSpecimen = specimens.firstWhere((s) => s.barcode == 'SMP-90214');
      expect(updatedSpecimen.status, SampleStatus.processing);
    });

    test('LabService records pre-analytical QC rejection with recollection trigger', () async {
      final service = LabService();

      final qc = await service.recordQcRejection(
        barcode: 'SMP-77401',
        rejectionReason: 'Micro-clots in EDTA Tube',
        clinicalNotes: 'Clot detected on applicator stick inspection.',
      );

      expect(qc.sampleBarcode, 'SMP-77401');
      expect(qc.recollectionTriggered, isTrue);

      final specimens = await service.getSpecimens();
      final rejected = specimens.firstWhere((s) => s.barcode == 'SMP-77401');
      expect(rejected.status, SampleStatus.rejected);
    });

    test('LabService saves test findings and pathologist authorizes report', () async {
      final service = LabService();

      // Enter findings
      final report = await service.enterTestResults(
        sampleBarcode: 'SMP-65219',
        testName: 'Lipid Profile',
        parameters: const [
          ReportParameter(name: 'Total Cholesterol', value: '190', range: '< 200', flag: 'Normal'),
          ReportParameter(name: 'Triglycerides', value: '130', range: '< 150', flag: 'Normal'),
        ],
      );
      expect(report.sampleBarcode, 'SMP-65219');
      expect(report.isReady, isFalse);

      // Pathologist sign-off
      final signed = await service.authorizeAndSignReport(
        reportId: report.id,
        pathologistName: 'Dr. Sunita Sen (Senior Pathologist)',
      );
      expect(signed.isReady, isTrue);
      expect(signed.pathologistName, 'Dr. Sunita Sen (Senior Pathologist)');

      final specimens = await service.getSpecimens();
      final sample = specimens.firstWhere((s) => s.barcode == 'SMP-65219');
      expect(sample.status, SampleStatus.reportReady);
    });
  });

  group('LabProvider State Tests', () {
    test('LabProvider initializes and filters specimens correctly', () async {
      final provider = LabProvider();
      await provider.loadAllData();

      expect(provider.isLoading, isFalse);
      expect(provider.racks.isNotEmpty, isTrue);
      expect(provider.analyzers.isNotEmpty, isTrue);

      // Search query filtering
      provider.setSearchQuery('Meena');
      expect(provider.filteredSpecimens.any((s) => s.patientName.contains('Meena')), isTrue);

      provider.setSearchQuery('');
      expect(provider.filteredSpecimens.length, greaterThanOrEqualTo(4));

      // Department filtering
      provider.setDepartmentFilter('Hematology');
      expect(provider.selectedDepartment, 'Hematology');
    });
  });

  group('LabHomeScreen Widget Tests', () {
    testWidgets('Renders LabHomeScreen with KPI bar, quick accession bar, and tab navigation', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.labTechnician);
      });

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
      await tester.pumpAndSettle();

      // Verify Header & Credentials
      expect(find.text('Laboratory & Pathologist Portal'), findsOneWidget);
      expect(find.text('Dr. Sarah Chen'), findsOneWidget);
      expect(find.text('Switch Role'), findsOneWidget);

      // Verify KPI Metric Cards
      expect(find.text('Incoming Couriers'), findsOneWidget);
      expect(find.text('In Central Lab'), findsOneWidget);
      expect(find.text('In Analyzers'), findsOneWidget);
      expect(find.text('Awaiting Sign-Off'), findsOneWidget);

      // Verify Quick Accession Input
      expect(find.text('Accession Vial'), findsOneWidget);

      // Verify 4 Tab Titles
      expect(find.text('Accession & Racks'), findsOneWidget);
      expect(find.text('Bench Testing & Results'), findsOneWidget);
      expect(find.text('Pathologist Sign-Off'), findsOneWidget);
      expect(find.text('QC & Analyzers'), findsOneWidget);

      // Verify Tab 1 Content (Racks & Couriers)
      expect(find.text('ACTIVE ANALYZER SPECIMEN RACKS'), findsOneWidget);
      expect(find.textContaining('Rack A1'), findsOneWidget);

      // Switch to Tab 2: Bench Testing & Results
      await tester.tap(find.text('Bench Testing & Results'));
      await tester.pumpAndSettle();
      expect(find.text('DIAGNOSTIC TEST PANEL'), findsWidgets);

      // Switch to Tab 3: Pathologist Sign-Off
      await tester.tap(find.text('Pathologist Sign-Off'));
      await tester.pumpAndSettle();
      expect(find.text('AWAITING CLINICAL AUTHORIZATION'), findsOneWidget);

      // Switch to Tab 4: QC & Analyzers
      await tester.tap(find.text('QC & Analyzers'));
      await tester.pumpAndSettle();
      expect(find.text('CONNECTED CLINICAL ANALYZERS HARDWARE STATUS'), findsOneWidget);
      expect(find.textContaining('Sysmex XN-1000'), findsOneWidget);
      expect(find.text('PRE-ANALYTICAL QUALITY CONTROL REJECTION LOG'), findsOneWidget);
    });
  });
}
