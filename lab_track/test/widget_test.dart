import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/core/theme/app_theme.dart';
import 'package:lab_track/features/patient/screens/patient_home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('PatientHomeScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const PatientHomeScreen(),
      ),
    );

    // Verify key UI elements render
    expect(find.text('Welcome, John Doe'), findsOneWidget);
    expect(find.text('Active Sample In-Transit'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
