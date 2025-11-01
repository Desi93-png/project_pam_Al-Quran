// Salin dan timpa seluruh file lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_pam/screens/splash_screen.dart'; // Ganti dengan splash screen Anda
import 'package:flutter_pam/services/notification_service.dart'; // <-- Import service
import 'package:timezone/data/latest_all.dart' as tz; // <-- Import timezone

Future<void> main() async {
  // Pastikan Flutter binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // --- Inisialisasi (TANPA PENJADWALAN OTOMATIS) ---
  try {
    tz.initializeTimeZones(); // Inisialisasi database timezone (DIBUTUHKAN)
    print("Timezones Initialized.");

    await NotificationService().initNotification(); // Inisialisasi plugin (WAJIB)
    print("Notification Service Initialized.");

    // --- BARIS INI TELAH DIHAPUS ---
    // await NotificationService().scheduleDailyReminderNotification();
    // --- AKHIR PERUBAHAN ---

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
      ),
      home: const SplashScreen(),
    );
  }
}