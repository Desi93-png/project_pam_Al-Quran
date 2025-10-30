// Salin dan timpa seluruh file lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_pam/screens/splash_screen.dart'; // Ganti dengan splash screen Anda
import 'package:flutter_pam/services/notification_service.dart'; // <-- Import service
import 'package:timezone/data/latest_all.dart' as tz; // <-- Import timezone

Future<void> main() async {
  // Pastikan Flutter binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // --- Inisialisasi dan jadwalkan notifikasi ---
  try {
    tz.initializeTimeZones(); // Inisialisasi database timezone
    print("Timezones Initialized.");
    
    await NotificationService().initNotification(); // Inisialisasi plugin
    print("Notification Service Initialized.");
    
    // Tetap jadwalkan notifikasi harian (untuk Laporan)
    await NotificationService().scheduleDailyReminderNotification(); 
    
  } catch (e) {
     debugPrint("Error saat setup notifikasi: $e"); // Cetak error jika gagal
  }
  // --------------------------------------------------

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
        // TODO: Atur tema global Anda di sini
      ),
      // Mulai dari SplashScreen (yang akan cek login)
      home: const SplashScreen(),
    );
  }
}