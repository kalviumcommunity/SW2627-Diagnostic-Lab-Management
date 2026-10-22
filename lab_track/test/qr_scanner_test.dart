import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/data/services/scanner_service.dart';
import 'package:lab_track/shared/theme/app_theme.dart';
import 'package:lab_track/shared/widgets/universal_qr_scanner_modal.dart';

void main() {
  group('ScannerService Unit Tests', () {
    test('extracts direct standard specimen barcodes', () {
      expect(ScannerService.extractSampleBarcode('SMP-88390'), 'SMP-88390');
      expect(ScannerService.extractSampleBarcode('smp-88390'), 'SMP-88390');
      expect(ScannerService.extractSampleBarcode('  SMP-12345  '), 'SMP-12345');
    });

    test('extracts sample barcodes from URLs and deep links', () {
      expect(
        ScannerService.extractSampleBarcode('https://labtrack.com/track/SMP-88390'),
        'SMP-88390',
      );
      expect(
        ScannerService.extractSampleBarcode('http://localhost:8080/#/track/SMP-91024'),
        'SMP-91024',
      );
      expect(
        ScannerService.extractSampleBarcode('labtrack://samples/SMP-77401'),
        'SMP-77401',
      );
    });

    test('extracts order IDs correctly', () {
      expect(ScannerService.extractSampleBarcode('ORD-84210'), 'ORD-84210');
      expect(ScannerService.extractSampleBarcode('ord-84210'), 'ORD-84210');
      expect(
        ScannerService.extractSampleBarcode('https://labtrack.com/orders/ORD-84210'),
        'ORD-84210',
      );
    });

    test('validates sample barcodes accurately', () {
      expect(ScannerService.isValidSampleBarcode('SMP-88390'), isTrue);
      expect(ScannerService.isValidSampleBarcode('ORD-84210'), isTrue);
      expect(ScannerService.isValidSampleBarcode('ABC-12345'), isTrue);
      expect(ScannerService.isValidSampleBarcode(''), isFalse);
      expect(ScannerService.isValidSampleBarcode(null), isFalse);
    });
  });

  group('UniversalQrScannerModal Widget Tests', () {
    testWidgets('renders scanner modal and allows preset selection', (WidgetTester tester) async {
      String? returnedBarcode;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedBarcode = await UniversalQrScannerModal.show(
                    context,
                    title: 'Test Barcode Scanner',
                  );
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      );

      // Tap open scanner button
      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      // Modal appears
      expect(find.text('Test Barcode Scanner'), findsOneWidget);
      expect(find.text('Live Camera'), findsOneWidget);
      expect(find.text('Manual / Presets'), findsOneWidget);

      // Switch to Manual / Presets tab
      await tester.tap(find.text('Manual / Presets'));
      await tester.pumpAndSettle();

      // Check preset chips exist
      expect(find.text('SMP-88390'), findsOneWidget);
      expect(find.text('SMP-99120'), findsOneWidget);

      // Select preset chip
      await tester.tap(find.text('SMP-88390'));
      await tester.pumpAndSettle();

      // Modal should dismiss and return selected barcode
      expect(returnedBarcode, 'SMP-88390');
    });
  });
}
