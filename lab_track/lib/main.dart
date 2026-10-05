// Entry point of the LabTrack application.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/firebase_options.dart';
import 'shared/theme/app_theme.dart';
import 'auth/frontend/providers/auth_provider.dart';
import 'auth/frontend/screens/login_screen.dart';
import 'patient/frontend/providers/patient_provider.dart';
import 'patient/frontend/screens/patient_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
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
      home: authProvider.isAuthenticated
          ? const PatientHomeScreen()
          : const LoginScreen(),
    );
  }
}
