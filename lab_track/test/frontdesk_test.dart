import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lab_track/auth/frontend/providers/auth_provider.dart';
import 'package:lab_track/domain/enums/user_role.dart';
import 'package:lab_track/frontdesk/backend/models/walk_in_requisition_request.dart';
import 'package:lab_track/frontdesk/backend/services/frontdesk_service.dart';
import 'package:lab_track/frontdesk/frontend/providers/frontdesk_provider.dart';
import 'package:lab_track/frontdesk/frontend/screens/frontdesk_home_screen.dart';
import 'package:lab_track/frontdesk/frontend/screens/instant_search_screen.dart';
import 'package:lab_track/frontdesk/frontend/screens/thermal_barcode_dispatch_screen.dart';
import 'package:lab_track/shared/theme/app_theme.dart';

void main() {
  group('FrontDeskService Unit Tests', () {
    test('Walk-in requisition allocates correct tube caps and generates thermal labels', () async {
      final service = FrontDeskService();

      final request = WalkInRequisitionRequest(
        patientName: 'Virender Test Patient',
        patientPhone: '+91 98765 00003',
        age: 24,
        gender: 'Male',
        address: 'House 420, Tension Colony',
        selectedTestNames: const [
          'Complete Blood Count (CBC)',
          'Thyroid Panel (T3, T4, TSH)',
          'Fasting Blood Sugar (FBS)',
        ],
        priority: 'Urgent STAT',
      );

      final labels = await service.createWalkInRequisition(request);

      // Should allocate 3 tubes: Purple (EDTA), Gold (SST), Grey (Fluoride)
      expect(labels.length, 3);
      expect(labels.any((l) => l.vialType.contains('Purple')), isTrue);
      expect(labels.any((l) => l.vialType.contains('Gold')), isTrue);
      expect(labels.any((l) => l.vialType.contains('Grey')), isTrue);

      // Check priority preserved
      expect(labels.every((l) => l.priority == 'Urgent STAT'), isTrue);

      // Verify search finds newly created walk-in order
      final search = await service.search(query: 'Virender Test Patient');
      expect(search.isNotEmpty, isTrue);
      expect(search.first.order.patientPhone, '+91 98765 00003');
    });
  });

  group('FrontDeskHomeScreen Widget Tests', () {
    testWidgets('Renders Front Desk Reception Portal matching design with Aryan', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.frontDesk);
      });

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => FrontDeskProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FrontDeskHomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header title
      expect(find.text('Branch Reception Command'), findsOneWidget);

      // Verify user card shows Aryan
      expect(find.text('Aryan'), findsOneWidget);
      expect(find.text('Switch Portal'), findsOneWidget);

      // Verify Action Card 1: Instant Report & Patient Lookup
      expect(find.text('Instant Report & Patient Lookup'), findsOneWidget);

      // Verify Action Card 2: Thermal Barcode & Label Dispatch
      expect(find.text('Thermal Barcode & Label Dispatch'), findsOneWidget);
    });

    testWidgets('Tapping Instant Search navigates to InstantSearchScreen', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.frontDesk);
      });

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => FrontDeskProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FrontDeskHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Instant Report & Patient Lookup'));
      await tester.pumpAndSettle();

      expect(find.byType(InstantSearchScreen), findsOneWidget);
    });

    testWidgets('Tapping Thermal Barcode Dispatch navigates to ThermalBarcodeDispatchScreen', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.frontDesk);
      });

      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => FrontDeskProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FrontDeskHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thermal Barcode & Label Dispatch'));
      await tester.pumpAndSettle();

      expect(find.byType(ThermalBarcodeDispatchScreen), findsOneWidget);
    });
  });
}
