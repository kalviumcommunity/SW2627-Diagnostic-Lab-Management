// Entry point of the LabTrack application.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/firebase_options.dart';
import 'config/app_mode.dart';
import 'shared/theme/app_theme.dart';
import 'auth/frontend/providers/auth_provider.dart';
import 'auth/frontend/screens/role_selection_screen.dart';
import 'patient/frontend/providers/patient_provider.dart';
import 'phlebotomist/frontend/providers/phlebotomist_provider.dart';
import 'frontdesk/frontend/providers/frontdesk_provider.dart';
import 'lab/frontend/providers/lab_provider.dart';
import 'admin/frontend/providers/admin_provider.dart';
import 'data/services/central_data_store.dart';
import 'routing/role_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    CentralDataStore.instance.connectToFirestore();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PatientProvider>(
          create: (_) => PatientProvider(),
          update: (_, auth, patient) => patient!..setPatient(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PhlebotomistProvider>(
          create: (_) => PhlebotomistProvider(),
          update: (_, auth, collector) => collector!..setPhlebotomist(auth.currentUser?.id),
        ),
        ChangeNotifierProvider(create: (_) => FrontDeskProvider()),
        ChangeNotifierProvider(create: (_) => LabProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const LabTrackApp(),
    ),
  );
}

class LabTrackApp extends StatelessWidget {
  const LabTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'LabTrack - Diagnostic Lab Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) => isDemoMode
          ? Banner(message: 'DEMO', location: BannerLocation.topEnd, child: child!)
          : child!,
      home: authProvider.isAuthenticated
          ? RoleRouter.getHomeScreenForRole(authProvider.currentUser?.role)
          : const RoleSelectionScreen(),
    );
  }
}
