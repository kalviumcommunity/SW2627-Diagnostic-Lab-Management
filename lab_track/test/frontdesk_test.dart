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
    test('Service seeds default orders, samples, and reports', () async {
      final service = FrontDeskService();
      final items = await service.search(query: '');

      expect(items.isNotEmpty, isTrue);
      expect(items.any((i) => i.order.patientName == 'John Doe'), isTrue);
      expect(items.any((i) => i.order.id == 'ORD-84210'), isTrue);
      expect(items.any((i) => i.samples.any((s) => s.barcode == 'SMP-88390')), isTrue);
    });

    test('Search filters correctly by phone, name, and barcode', () async {
      final service = FrontDeskService();

      // Search by phone
      final phoneResults = await service.search(query: '9876543210');
      expect(phoneResults.length, 1);
      expect(phoneResults.first.order.patientName, 'John Doe');

      // Search by barcode
      final barcodeResults = await service.search(query: 'SMP-90214');
      expect(barcodeResults.length, 1);
      expect(barcodeResults.first.order.patientName, 'Meena Gupta');

      // Search by name
      final nameResults = await service.search(query: 'Rajesh');
      expect(nameResults.length, 1);
      expect(nameResults.first.order.patientName, 'Rajesh Sharma');
    });

    test('Walk-in requisition allocates correct tube caps and generates thermal labels', () async {
      final service = FrontDeskService();

      final request = WalkInRequisitionRequest(
        patientName: 'Test Patient',
        patientPhone: '+91 99999 88888',
        age: 40,
        gender: 'Male',
        address: 'Test City',
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
      final search = await service.search(query: 'Test Patient');
      expect(search.isNotEmpty, isTrue);
      expect(search.first.order.patientPhone, '+91 99999 88888');
    });
  });

  group('FrontDeskHomeScreen Widget Tests', () {
    testWidgets('Renders Front Desk Reception Portal matching design', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.frontDesk);
      });

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
      expect(find.text('Front Desk Reception Portal'), findsOneWidget);

      // Verify user card
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.textContaining('branch-spoke-01'), findsOneWidget);
      expect(find.text('Switch Role'), findsOneWidget);

      // Verify Action Card 1: Instant Report & Patient Search
      expect(find.text('Instant Report & Patient Search'), findsOneWidget);
      expect(find.text('Search by patient name, phone, or barcode to eliminate manual paper slips'), findsOneWidget);

      // Verify Action Card 2: Thermal Barcode & Label Dispatch
      expect(find.text('Thermal Barcode & Label Dispatch'), findsOneWidget);
      expect(find.text('Generate sterile barcode stickers for walk-in patient test requisitions'), findsOneWidget);
    });

    testWidgets('Tapping Instant Search navigates to InstantSearchScreen', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.frontDesk);
      });

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

      await tester.tap(find.text('Instant Report & Patient Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(InstantSearchScreen), findsOneWidget);
    });

    testWidgets('Tapping Thermal Barcode Dispatch navigates to ThermalBarcodeDispatchScreen', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.frontDesk);
      });

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

      await tester.tap(find.text('Thermal Barcode & Label Dispatch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ThermalBarcodeDispatchScreen), findsOneWidget);
      expect(find.text('Walk-In Requisition'), findsOneWidget);
      expect(find.text('Thermal Label Spooler'), findsOneWidget);
    });
  });
}
