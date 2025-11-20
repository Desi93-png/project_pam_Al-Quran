import 'package:flutter/material.dart';
import 'package:flutter_pam/screens/splash_screen.dart';
import 'package:flutter_pam/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    tz.initializeTimeZones();
    print("Timezones Initialized.");

    await NotificationService().initNotification();
    print("Notification Service Initialized.");
  } catch (e) {
    debugPrint("Error saat setup notifikasi: $e");
  }

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
