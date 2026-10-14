import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lab_track/admin/backend/services/admin_service.dart';
import 'package:lab_track/admin/frontend/providers/admin_provider.dart';
import 'package:lab_track/admin/frontend/screens/admin_home_screen.dart';
import 'package:lab_track/admin/frontend/screens/sla_dashboard_screen.dart';
import 'package:lab_track/admin/frontend/screens/branch_management_screen.dart';
import 'package:lab_track/admin/frontend/screens/staff_management_screen.dart';
import 'package:lab_track/auth/frontend/providers/auth_provider.dart';
import 'package:lab_track/auth/frontend/screens/login_screen.dart';
import 'package:lab_track/auth/frontend/screens/signup_screen.dart';
import 'package:lab_track/data/models/branch_model.dart';
import 'package:lab_track/domain/enums/user_role.dart';
import 'package:lab_track/shared/theme/app_theme.dart';

void main() {
  group('AdminService & Provider Unit Tests', () {
    test('AdminService seeds operational KPIs, SLA metrics, and branches', () async {
      final service = AdminService();

      final summary = await service.getOperationalSummary();
      expect(summary['totalDailyVolume'], 1420);
      expect(summary['slaComplianceRate'], 96.8);

      final slaMetrics = await service.getSlaMetrics();
      expect(slaMetrics.isNotEmpty, isTrue);
      expect(slaMetrics.any((m) => m.testName.contains('Complete Blood Count')), isTrue);
      expect(slaMetrics.any((m) => m.isBreached), isTrue); // Vitamin D

      final rejections = await service.getRejectionCauses();
      expect(rejections.isNotEmpty, isTrue);
      expect(rejections.first.reason.contains('Hemolyzed'), isTrue);

      final branches = await service.getBranches();
      expect(branches.length, greaterThanOrEqualTo(5));
      expect(branches.any((b) => b.name.contains('Apex Central')), isTrue);
    });

    test('AdminService adds branch and toggles staff duty', () async {
      final service = AdminService();

      const newBranch = BranchModel(
        id: 'BR-TEST-99',
        name: 'South Extension Spoke Hub',
        address: 'Market 1, South Ex, New Delhi',
        city: 'New Delhi',
        hasTestingLab: false,
        phoneNumber: '+91 11 9999 8888',
      );

      final created = await service.addBranch(newBranch);
      expect(created.id, 'BR-TEST-99');

      final branches = await service.getBranches();
      expect(branches.any((b) => b.id == 'BR-TEST-99'), isTrue);

      // Staff duty toggle
      final updatedStaff = await service.toggleStaffDuty('PH-204');
      expect(updatedStaff.id, 'PH-204');

      // Reallocate staff
      final reallocated = await service.reallocateStaff(
        staffId: 'PH-204',
        targetBranchId: 'branch-spoke-01',
        targetBranchName: 'Downtown Spoke Center #1',
      );
      expect(reallocated.assignedBranchId, 'branch-spoke-01');
    });

    test('AdminProvider loads state and filters correctly', () async {
      final provider = AdminProvider();
      await provider.loadAllData();

      expect(provider.branches.isNotEmpty, isTrue);
      expect(provider.slaMetrics.isNotEmpty, isTrue);
      expect(provider.staffAllocations.isNotEmpty, isTrue);

      // Filter by branch
      provider.setBranchFilter('Downtown');
      expect(provider.selectedBranchFilter, 'Downtown');
      expect(provider.filteredBranchPerformances.length, 1);

      provider.setBranchFilter('All Branches');
      expect(provider.filteredBranchPerformances.length, greaterThanOrEqualTo(5));
    });
  });

  group('Admin Dashboard & Authentication Widget Tests', () {
    testWidgets('Renders AdminHomeScreen with Overview KPI cards and pipeline', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.admin);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header & User Card
      expect(find.text('Admin SLA & TAT Analytics'), findsOneWidget);
      expect(find.text('Dr. Vikram Malhotra'), findsOneWidget);
      expect(find.text('Switch Role'), findsOneWidget);

      // Operational KPI cards
      expect(find.text('Daily Volume'), findsOneWidget);
      expect(find.text('SLA Compliance'), findsOneWidget);
      expect(find.text('Avg TAT'), findsOneWidget);
      expect(find.text('In Transit'), findsNWidgets(2)); // KPI card + pipeline stage

      // Specimen Pipeline Stages
      expect(find.text('Live Specimen Pipeline Stages'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('Collected'), findsOneWidget);
      expect(find.text('Bench'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);

      // Administrative Workflows
      expect(find.text('SLA Turnaround Time Dashboard'), findsOneWidget);
      expect(find.text('Multi-Branch Custody Topology'), findsOneWidget);
      expect(find.text('Staff & Phlebotomist Fleet Allocation'), findsOneWidget);
    });

    testWidgets('Tapping SLA tab displays SlaDashboardScreen metrics', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.admin);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap SLA & TAT tab in bottom navigation
      await tester.tap(find.text('SLA & TAT'));
      await tester.pumpAndSettle();

      // Verify SLA Dashboard components render
      expect(find.byType(SlaDashboardScreen), findsOneWidget);
      expect(find.text('Turnaround Time (TAT) Compliance'), findsOneWidget);
      expect(find.text('NABH / NABL Compliant'), findsOneWidget);
      expect(find.textContaining('Complete Blood Count (CBC)'), findsOneWidget);
      expect(find.textContaining('Thyroid Panel'), findsOneWidget);
      expect(find.text('DIAGNOSTIC TEST TAT VS SLA TARGETS'), findsOneWidget);
      expect(find.text('SPECIMEN REJECTION & RE-DRAW ROOT CAUSES'), findsOneWidget);
    });

    testWidgets('Tapping Branches tab displays BranchManagementScreen', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.admin);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Branches tab in bottom navigation
      await tester.tap(find.text('Branches'));
      await tester.pumpAndSettle();

      // Verify Branch Management components render
      expect(find.byType(BranchManagementScreen), findsOneWidget);
      expect(find.text('Total Hubs'), findsOneWidget);
      expect(find.text('Testing Labs'), findsOneWidget);
      expect(find.text('Spoke Centers'), findsOneWidget);
      expect(find.text('Apex Central Reference Laboratory'), findsOneWidget);
      expect(find.text('Downtown Spoke Center #1'), findsOneWidget);
    });

    testWidgets('Tapping Staff Fleet tab displays StaffManagementScreen', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        await authProvider.loginAsRole(UserRole.admin);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Staff Fleet tab in bottom navigation
      await tester.tap(find.text('Staff Fleet'));
      await tester.pumpAndSettle();

      // Verify Staff Management components render
      expect(find.byType(StaffManagementScreen), findsOneWidget);
      expect(find.text('Phlebos in Field'), findsOneWidget);
      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Dr. Neha Kapoor'), findsOneWidget);
    });

    testWidgets('LoginScreen renders Google auth and mode switching', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand & Google Sign-In
      expect(find.text('LabTrack'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Patient Mobile Login'), findsOneWidget);

      // Switch to Staff & Admin Login
      await tester.tap(find.text('Staff & Admin Login'));
      await tester.pumpAndSettle();

      expect(find.text('Staff & Administrator Sign In'), findsOneWidget);
      expect(find.text('Sign In to Enterprise Portal'), findsOneWidget);
      expect(find.text('Work Email Address *'), findsOneWidget);
      expect(find.text('Register / Sign Up'), findsOneWidget);
    });

    testWidgets('SignupScreen renders all registration fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join LabTrack Network'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Full Legal Name *'), findsOneWidget);
      expect(find.text('Work / Personal Email *'), findsOneWidget);
      expect(find.text('Designated System Role *'), findsOneWidget);
      expect(find.text('Account Password *'), findsOneWidget);
      expect(find.text('Confirm Password *'), findsOneWidget);
      expect(find.text('Complete Registration & Sign In'), findsOneWidget);
    });
  });
}
