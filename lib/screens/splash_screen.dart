import 'package:flutter/material.dart';
import 'package:flutter_pam/screens/home_screen.dart';
import 'package:flutter_pam/screens/login_screen.dart'; // Import LoginScreen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pam/globals.dart'; // Untuk warna

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Tunggu beberapa detik (opsional, untuk efek splash)
    await Future.delayed(Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId'); // Cek apakah userId ada

    if (!mounted) return; // Pastikan widget masih ada

    if (userId != null) {
      // Jika ADA session, navigasi ke HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Jika TIDAK ADA session, navigasi ke LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan Splash Screen Anda (contoh sederhana)
    return Scaffold(
      backgroundColor: background, // Warna background Anda
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ganti dengan logo atau gambar Anda
            Icon(Icons.mosque, size: 100, color: primary),
            SizedBox(height: 20),
            CircularProgressIndicator(color: primary),
          ],
        ),
      ),
    );
  }
}
