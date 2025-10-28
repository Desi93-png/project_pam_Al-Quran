import 'package:flutter/material.dart';
import 'package:flutter_pam/screens/splash_screen.dart'; // Mulai dari Splash Screen
// Hapus import Notifikasi jika Anda belum siap mengimplementasikannya
// import 'package:flutter_pam/services/notification_service.dart';
// import 'package:timezone/data/latest_all.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // try {
  //   await NotificationService().initNotification();
  //   await NotificationService().scheduleDailyAyahNotification();
  // } catch (e) {
  //    debugPrint("Error saat setup notifikasi: $e");
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Now',
      theme: ThemeData(
        // ... tema Anda ...
        brightness: Brightness.dark, // Sesuaikan tema gelap/terang
        // Atur warna primer, dll jika perlu
      ),
      // Mulai dari SplashScreen
      home: const SplashScreen(),
    );
  }
}
