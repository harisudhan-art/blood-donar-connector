import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BloodDonorApp());
}

class BloodDonorApp extends StatelessWidget {
  const BloodDonorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Donor Connect',
      debugShowCheckedModeBanner: false,
      // LIGHT THEME
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
      ),
      // DARK THEME IMPROVEMENT
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFD32F2F),
      ),
      themeMode: ThemeMode.system, // Switches based on phone settings
      home: const SplashScreen(),
    );
  }
}