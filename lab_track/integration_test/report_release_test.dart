import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:lab_track/data/models/sample_model.dart';
import 'package:lab_track/data/models/report_model.dart';
import 'package:lab_track/data/services/central_data_store.dart';
import 'package:lab_track/domain/enums/sample_status.dart';
import 'package:lab_track/lab/frontend/providers/lab_provider.dart';
import 'package:lab_track/lab/frontend/widgets/pathologist_sign_dialog.dart';
import 'package:lab_track/patient/frontend/providers/patient_provider.dart';
import 'package:lab_track/patient/frontend/screens/my_reports_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('signed lab report reaches patient and saves PDF on Android',
      (tester) async {
    final store = CentralDataStore.instance;
    store.clearAllDataForTesting();
    store.saveSample(SampleModel(
      barcode: 'SMP-PDF-DEVICE',
      orderId: 'ORD-PDF-DEVICE',
      patientId: 'PT-VIRENDER',
      patientName: 'Virender',
      status: SampleStatus.processing,
      testNames: const ['CBC'],
    ));
    final patient = PatientProvider()..setPatient('PT-VIRENDER');
    final lab = LabProvider();
    final report = store.saveTestResults(
      sampleBarcode: 'SMP-PDF-DEVICE',
      testName: 'CBC',
      parameters: const [
        ReportParameter(
            name: 'Hemoglobin', value: '14.2', unit: 'g/dL', range: '13-17')
      ],
    );
    expect(patient.reports.single.isReady, isFalse);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: patient),
        ChangeNotifierProvider.value(value: lab)
      ],
      child: MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) => Center(
                        child: ElevatedButton(
                            onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: lab,
                                    child:
                                        PathologistSignDialog(report: report),
                                  ),
                                ),
                            child: const Text('Open sign-off')),
                      )))),
    ));
    await tester.tap(find.text('Open sign-off'));
    await tester.pumpAndSettle();
    // The first field is the verifier; the second is optional interpretation.
    await tester.enterText(find.byType(TextField).first, 'Dr Device Test');
    await tester
        .ensureVisible(find.text('Electronically Authorize & Release Report'));
    await tester.tap(find.text('Electronically Authorize & Release Report'));
    await tester.pumpAndSettle();
    expect(find.byType(PathologistSignDialog), findsNothing);
    expect(patient.reports.single.isReady, isTrue);
    expect(patient.reports.single.pathologistName, 'Dr Device Test');
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: patient,
      child: const MaterialApp(home: MyReportsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('VERIFIED'), findsOneWidget);
    await tester.tap(find.byTooltip('Download PDF'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved to Downloads/LabTrack/'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    patient.dispose();
    lab.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
