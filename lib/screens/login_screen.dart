import 'package:flutter/material.dart';
import 'package:flutter_pam/helpers/database_helper.dart';
import 'package:flutter_pam/models/user_model.dart';
import 'package:flutter_pam/screens/home_screen.dart'; // Untuk navigasi setelah login
import 'package:flutter_pam/screens/registration_screen.dart'; // Untuk tombol Daftar
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pam/globals.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // --- 1. TAMBAHKAN STATE UNTUK VISIBILITY PASSWORD ---
  bool _isPasswordVisible = false;
  // --- Akhir Perubahan 1 ---

  final dbHelper = DatabaseHelper();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    // ... (Fungsi login Anda tidak berubah)
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      try {
        User? user = await dbHelper.loginUser(
          _usernameController.text,
          _passwordController.text,
        );

        if (user != null && user.id != null) {
          // Login Berhasil!
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', user.id!); 

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          // Login Gagal
          setState(() {
            _errorMessage = 'Username atau password salah.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToRegistration() {
    // ... (Fungsi ini tidak berubah)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mosque, size: 80, color: primary),
                const SizedBox(height: 24),
                Text(
                  "Selamat Datang di Quran Now",
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Silakan login untuk melanjutkan",
                  style: GoogleFonts.poppins(fontSize: 16, color: text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Username Field (Tidak berubah)
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Username"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- 2. MODIFIKASI PASSWORD FIELD ---
                TextFormField(
                  controller: _passwordController,
                  // Gunakan state _isPasswordVisible
                  obscureText: !_isPasswordVisible, 
                  style: TextStyle(color: Colors.white),
                  // Gunakan .copyWith untuk MENAMBAHKAN suffixIcon
                  decoration: _inputDecoration("Password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        // Ganti ikon berdasarkan state
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: text, // Beri warna ikon
                      ),
                      onPressed: () {
                        // Panggil setState untuk toggle state
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                // --- Akhir Perubahan 2 ---

                const SizedBox(height: 32),

                // Tombol Login (Tidak berubah)
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Login"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol ke Halaman Registrasi (Tidak berubah)
                TextButton(
                  onPressed: _goToRegistration,
                  child: Text(
                    "Belum punya akun? Daftar di sini",
                    style: TextStyle(color: primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk InputDecoration (Tidak berubah)
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: text),
      filled: true,
      fillColor: gray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primary),
      ),
    );
  }
}