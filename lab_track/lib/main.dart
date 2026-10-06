```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/phlebotomist/screens/phlebotomist_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const LabTrackApp());
}

class LabTrackApp extends StatelessWidget {
  const LabTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LabTrack - Diagnostic Lab Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const PhlebotomistHomeScreen(),
    );
  }
}
```