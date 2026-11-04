import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lab_track/auth/frontend/providers/auth_provider.dart';
import 'package:lab_track/data/models/sample_model.dart';
import 'package:lab_track/data/services/central_data_store.dart';
import 'package:lab_track/domain/enums/sample_status.dart';
import 'package:lab_track/lab/frontend/screens/lab_home_screen.dart';
import 'package:lab_track/lab/frontend/widgets/result_entry_dialog.dart';

void main() {
  testWidgets('lab screen dialog submits measured results for sign-off',
      (tester) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = CentralDataStore.instance;
    store.clearAllDataForTesting();
    store.saveSample(SampleModel(
      barcode: 'SMP-SUBMIT-TEST',
      orderId: 'ORD-SUBMIT-TEST',
      patientId: 'PT-TEST',
      patientName: 'Test Patient',
      patientPhone: '1234567890',
      tubeType: 'EDTA',
      status: SampleStatus.receivedAtLab,
      testNames: const ['Complete Blood Count (CBC)'],
      createdAt: DateTime.now(),
    ));
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MaterialApp(home: LabHomeScreen()),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Bench Testing & Results'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Enter Analyzer Findings'));
    await tester.pump(const Duration(milliseconds: 500));
    final dialog = find.byType(ResultEntryDialog);
    expect(dialog, findsOneWidget);
    final fields =
        find.descendant(of: dialog, matching: find.byType(TextField));
    // Each row has name, measured value, unit, and reference range.
    for (var row = 0; row < 6; row++) {
      await tester.enterText(fields.at(row * 4 + 1), '${row + 10}');
    }
    await tester.tap(find.text('Save & Submit for Sign-Off'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(dialog, findsNothing);
    expect(tester.takeException(), isNull);
    final report =
        store.reports.singleWhere((r) => r.sampleBarcode == 'SMP-SUBMIT-TEST');
    expect(report.status, 'Pending Authorization');
    expect(report.testResults.length, 6);
    await tester.tap(find.text('Pathologist Sign-Off'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Review & Sign Report'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
