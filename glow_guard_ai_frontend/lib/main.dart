import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'User/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 2. Initialize App Check using the DEBUG provider so it works on your Emulator
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // CHANGED TO DEBUG
    appleProvider: AppleProvider.deviceCheck,
  );

  runApp(const GlowGuardApp());
}

class GlowGuardApp extends StatelessWidget {
  const GlowGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlowGuard AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}