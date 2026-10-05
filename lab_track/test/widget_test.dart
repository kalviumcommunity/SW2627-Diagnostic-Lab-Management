import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lab_track/shared/theme/app_theme.dart';
import 'package:lab_track/auth/frontend/providers/auth_provider.dart';
import 'package:lab_track/auth/frontend/screens/login_screen.dart';
import 'package:lab_track/patient/frontend/providers/patient_provider.dart';
import 'package:lab_track/patient/frontend/screens/patient_home_screen.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PatientProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    // Verify login UI elements render
    expect(find.text('LabTrack'), findsOneWidget);
    expect(find.text('Patient Mobile Login'), findsOneWidget);
    expect(find.text('Send Verification OTP'), findsOneWidget);
    expect(find.text('1-Click Demo Login as John Doe'), findsOneWidget);
  });

  testWidgets('PatientHomeScreen smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await authProvider.loginAsDemoPatient();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => PatientProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PatientHomeScreen(),
        ),
      ),
    );

    // Verify key UI elements render
    expect(find.text('Welcome, John Doe'), findsOneWidget);
    expect(find.text('Active Sample Tracking'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
