import 'package:flutter/material.dart';
import 'package:flutter_pam/globals.dart'; // Warna
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk session
import 'package:flutter_pam/screens/login_screen.dart'; // Untuk navigasi
import 'package:flutter_pam/helpers/database_helper.dart'; // Import DatabaseHelper
import 'package:flutter_pam/models/user_model.dart'; // Import UserModel

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State untuk menyimpan data user dan status loading
  User? _currentUser;
  bool _isLoading = true;
  String _errorMessage = '';

  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Muat data saat halaman dibuka
  }

  // Fungsi untuk memuat data user dari DB
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');

      if (userId != null) {
        final user = await dbHelper.getUserById(userId);
        if (user != null) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Data pengguna tidak ditemukan.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Sesi tidak valid. Silakan login ulang.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Fungsi Logout
  Future<void> _logout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: gray,
          title:
              Text('Konfirmasi Logout', style: TextStyle(color: Colors.white)),
          content: Text('Apakah Anda yakin ingin keluar?',
              style: TextStyle(color: text)),
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: TextStyle(color: primary)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Ya, Keluar', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  AppBar _appBar() => AppBar(
        backgroundColor: background,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const Spacer(),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _appBar(), // Panggil AppBar
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : _errorMessage.isNotEmpty
              ? Center(
                  child:
                      Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : _currentUser == null
                  ? Center(
                      child: Text('Gagal memuat data pengguna.',
                          style: TextStyle(color: Colors.white)))
                  : _buildProfileContent(), // Tampilkan konten jika data ada
    );
  }

  // Widget untuk membangun konten profil (sesuai screenshot image_c5a04e.png)
  Widget _buildProfileContent() {
    final user = _currentUser!;

    return ListView(
      // Gunakan ListView
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      children: [
        // --- Bagian Foto dan Data Pengguna ---
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50, // Ukuran sesuai screenshot awal
                backgroundColor: gray,
                backgroundImage: const AssetImage('assets/images/desi.jpg'),
              ),
              const SizedBox(height: 16),
              Text(
                user.namaLengkap, // Data Dinamis
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'NIM: ${user.nim}', // Data Dinamis
                style: GoogleFonts.poppins(
                    color: text, // Warna abu dari globals
                    fontSize: 14),
              ),
              Text(
                'Kelas: ${user.kelas}', // Data Dinamis
                style: GoogleFonts.poppins(
                    color: text, // Warna abu dari globals
                    fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- Bagian Saran (Statis) ---
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Saran',
            style: GoogleFonts.poppins(
                color: primary, // Warna ungu dari globals
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Aplikasi ini sangat membantu untuk membaca Al-Qur\'an secara digital. Tampilan antarmukanya menarik, dan fitur navigasi antar Surah maupun Juz mudah digunakan. Semoga ke depan bisa ditambahkan fitur bookmark dan tafsir ayat agar semakin lengkap.',
          textAlign: TextAlign.justify,
          style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8), // Sedikit transparan
              fontSize: 14),
        ),
        const SizedBox(height: 24),

        // --- Bagian Kesan (Statis) ---
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Kesan',
            style: GoogleFonts.poppins(
                color: primary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Aplikasi ini sangat membantu untuk membaca Al-Qur\'an secara digital. Tampilan antarmukanya menarik, dan fitur navigasi antar Surah maupun Juz mudah digunakan. Semoga ke depan bisa ditambahkan fitur bookmark dan tafsir ayat agar semakin lengkap.',
          textAlign: TextAlign.justify,
          style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 40),

        // --- Tombol Logout ---
        ElevatedButton(
          onPressed: _logout, // Panggil fungsi logout dengan konfirmasi
          child: Text("Logout"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent[700],
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 48), // Tinggi tombol disesuaikan
            shape: RoundedRectangleBorder(
              // Sudut tombol
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20), // Jarak di bawah
      ],
    );
  }
}
