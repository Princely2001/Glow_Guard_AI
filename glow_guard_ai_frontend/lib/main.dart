import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ✅ Import the generated options file
import 'firebase_options.dart';
import 'User/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize with explicit options (Fixes "Firebase object required" error)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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