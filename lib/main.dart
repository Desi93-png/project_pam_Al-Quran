import 'package:flutter/material.dart';
import 'package:flutter_pam/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Now',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      // Mulai dari SplashScreen
      home: const SplashScreen(),
    );
  }
}
