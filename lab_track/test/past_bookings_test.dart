import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lab_track/shared/theme/app_theme.dart';
import 'package:lab_track/auth/frontend/providers/auth_provider.dart';
import 'package:lab_track/patient/frontend/providers/patient_provider.dart';
import 'package:lab_track/patient/backend/models/patient_booking_request.dart';
import 'package:lab_track/patient/frontend/screens/past_bookings_screen.dart';
import 'package:lab_track/data/services/central_data_store.dart';

void main() {
  setUp(() {
    CentralDataStore.instance.clearAllDataForTesting();
  });

  group('Patient Past Bookings Feature Tests', () {
    test('PatientProvider initializes with empty orders on clean state', () {
      final provider = PatientProvider();
      provider.setPatient('PT-VIRENDER');
      expect(provider.orders, isEmpty);
    });

    test('Creating booking immediately reflects in patient orders list', () async {
      final provider = PatientProvider();
      provider.setPatient('PT-VIRENDER');

      final order = await provider.createBooking(
        PatientBookingRequest(
          patientId: 'PT-VIRENDER',
          patientName: 'Virender',
          patientPhone: '+91 98765 00003',
          address: 'House 420, Tension Colony, New Delhi',
          selectedTestNames: const ['Complete Blood Count (CBC)', 'Lipid Profile'],
          scheduledDate: DateTime.now().add(const Duration(days: 1)),
          timeSlot: '08:00 AM - 10:00 AM',
          branchName: 'Downtown Spoke Center #1',
          totalAmount: 950.0,
        ),
      );

      expect(order, isNotNull);
      expect(provider.orders, isNotEmpty);
      expect(provider.orders.first.patientName, 'Virender');
      expect(provider.orders.first.testNames, contains('Complete Blood Count (CBC)'));
      expect(provider.orders.first.sampleBarcodes, isNotEmpty);
    });

    testWidgets('PastBookingsScreen renders empty state when no bookings exist', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsDemoPatient();
      });

      final patientProvider = PatientProvider();
      patientProvider.setPatient('PT-VIRENDER');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: patientProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PastBookingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('No Past Bookings Yet'), findsOneWidget);
    });

    testWidgets('PastBookingsScreen renders booking card when order exists', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsDemoPatient();
      });

      final patientProvider = PatientProvider();
      patientProvider.setPatient('PT-VIRENDER');

      await tester.runAsync(() async {
        await patientProvider.createBooking(
          PatientBookingRequest(
            patientId: 'PT-VIRENDER',
            patientName: 'Virender',
            patientPhone: '+91 98765 00003',
            address: 'House 420, Tension Colony, New Delhi',
            selectedTestNames: const ['Thyroid Stimulating Hormone (TSH)'],
            scheduledDate: DateTime.now(),
            timeSlot: '07:00 AM - 09:00 AM',
            branchName: 'Downtown Spoke Center #1',
            totalAmount: 450.0,
          ),
        );
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: patientProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PastBookingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('CONFIRMED'), findsWidgets);
      expect(find.text('Thyroid Stimulating Hormone (TSH)'), findsWidgets);
      expect(find.text('View QR Pass'), findsOneWidget);
      expect(find.text('Live Track'), findsOneWidget);
    });
  });
}
