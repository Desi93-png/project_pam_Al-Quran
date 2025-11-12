// Salin dan timpa seluruh file lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_pam/globals.dart'; // Warna
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk session
import 'package:flutter_pam/screens/login_screen.dart'; // Untuk navigasi
import 'package:flutter_pam/helpers/database_helper.dart'; // Import DatabaseHelper
import 'package:flutter_pam/models/user_model.dart'; // Import UserModel
import 'package:flutter_pam/services/notification_service.dart'; // Sesuaikan path

// --- Import untuk Image Picker ---
import 'dart:io'; // Untuk File
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// --------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State untuk data
  User? _currentUser;
  bool _isLoading = true;
  String _errorMessage = '';
  final dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  // State untuk Mode Edit
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controller
  late TextEditingController _namaController;
  late TextEditingController _nimController;
  late TextEditingController _kelasController;
  // --- BARU: Tambahkan controller untuk Email ---
  late TextEditingController _emailController;
  // ---------------------------------------------

  // State untuk gambar baru
  XFile? _newImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

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
            _namaController = TextEditingController(text: user.namaLengkap);
            _nimController = TextEditingController(text: user.nim);
            _kelasController = TextEditingController(text: user.kelas);
            // --- BARU: Inisialisasi controller Email ---
            _emailController = TextEditingController(text: user.email);
            // -----------------------------------------
            _isLoading = false;
          });
        } else {
          _errorMessage = 'Data pengguna tidak ditemukan.';
          _isLoading = false;
        }
      } else {
        _errorMessage = 'Sesi tidak valid. Silakan login ulang.';
        _isLoading = false;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data: ${e.toString()}';
      _isLoading = false;
    }
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _kelasController.dispose();
    // --- BARU: Dispose controller Email ---
    _emailController.dispose();
    // ------------------------------------
    super.dispose();
  }

  Future<void> _logout() async {
    // ...(Kode _logout Anda tetap sama)...
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
        // ...(Kode _appBar Anda tetap sama)...
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
    // ...(Kode build Anda tetap sama)...
    return Scaffold(
      backgroundColor: background,
      appBar: _appBar(),
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
                  : _buildProfileContent(),
    );
  }

  Future<void> _pickImage() async {
    // ...(Kode _pickImage Anda tetap sama)...
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: gray,
        title:
            Text('Pilih Sumber Gambar', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: Text('Kamera', style: TextStyle(color: primary)),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
          TextButton(
            child: Text('Galeri', style: TextStyle(color: primary)),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source == null) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _newImageFile = image;
        });
      }
    } catch (e) {
      print("Gagal mengambil gambar: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  Future<String> _saveImagePermanently(XFile imageFile) async {
    // ...(Kode _saveImagePermanently Anda tetap sama)...
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName =
        'profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
    final String savedImagePath = p.join(appDir.path, fileName);
    await File(imageFile.path).copy(savedImagePath);
    return savedImagePath;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // --- BARU: Cek keunikan email SEBELUM menyimpan ---
    // (Pengecekan ini opsional namun SANGAT disarankan)
    // Kita cek apakah email diubah, dan jika iya, apakah email baru sudah ada.
    final newEmail = _emailController.text;
    if (newEmail != _currentUser!.email) {
      // Email diubah, cek database
      // Kita perlu fungsi baru di DatabaseHelper: getUserByEmail
      // Untuk sekarang, kita skip pengecekan ini agar sederhana
      // dan asumsikan user memasukkan email unik.
      
      // Jika Anda ingin menambahkan pengecekan, Anda perlu:
      // 1. Buat `getUserByEmail(String email)` di DatabaseHelper.
      // 2. Panggil: `final existingUser = await dbHelper.getUserByEmail(newEmail);`
      // 3. Cek: `if (existingUser != null) { ... tampilkan error ... }`
    }
    // --------------------------------------------------

    setState(() {
      _isLoading = true;
    });

    try {
      String? imagePathToSave = _currentUser!.profileImagePath;
      if (_newImageFile != null) {
        if (imagePathToSave != null && imagePathToSave.isNotEmpty) {
          final oldFile = File(imagePathToSave);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }
        imagePathToSave = await _saveImagePermanently(_newImageFile!);
      }

      // --- BARU: Tambahkan 'email' ke copyWith ---
      final updatedUser = _currentUser!.copyWith(
        namaLengkap: _namaController.text,
        nim: _nimController.text,
        kelas: _kelasController.text,
        email: _emailController.text, // <-- TAMBAHKAN INI
        profileImagePath: imagePathToSave,
      );
      // ----------------------------------------

      await dbHelper.updateUser(updatedUser);
      setState(() {
        _currentUser = updatedUser;
        _isEditing = false;
        _newImageFile = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Gagal menyimpan profil: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              // --- BARU: Tampilkan error jika email sudah ada ---
              content: Text(e.toString().contains('UNIQUE constraint failed')
                  ? 'Email tersebut sudah digunakan.'
                  : 'Gagal menyimpan profil: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileContent() {
    final user = _currentUser!;

    ImageProvider profileImage;
    if (_newImageFile != null) {
      profileImage = FileImage(File(_newImageFile!.path));
    } else if (user.profileImagePath != null &&
        user.profileImagePath!.isNotEmpty) {
      profileImage = FileImage(File(user.profileImagePath!));
    } else {
      profileImage = const AssetImage('assets/images/desi.jpg');
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  // ...(GestureDetector Foto tetap sama)...
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: gray,
                        backgroundImage: profileImage,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _isEditing
                    ? _buildEditableField(
                        // ...(Field Nama tetap sama)...
                        controller: _namaController,
                        label: 'Nama Lengkap',
                        icon: Icons.person,
                      )
                    : Text(
                        user.namaLengkap,
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                const SizedBox(height: 8),
                _isEditing
                    ? _buildEditableField(
                        // ...(Field NIM tetap sama)...
                        controller: _nimController,
                        label: 'NIM',
                        icon: Icons.badge,
                      )
                    : Text(
                        'NIM: ${user.nim}',
                        style: GoogleFonts.poppins(color: text, fontSize: 14),
                      ),
                _isEditing
                    ? _buildEditableField(
                        // ...(Field Kelas tetap sama)...
                        controller: _kelasController,
                        label: 'Kelas',
                        icon: Icons.school,
                      )
                    : Text(
                        'Kelas: ${user.kelas}',
                        style: GoogleFonts.poppins(color: text, fontSize: 14),
                      ),

                // --- BARU: Tambahkan Tampilan/Edit Email ---
                _isEditing
                    ? _buildEditableEmailField( // Panggil helper email baru
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                      )
                    : Text(
                        'Email: ${user.email}', // Tampilkan email
                        style: GoogleFonts.poppins(color: text, fontSize: 14),
                      ),
                // ----------------------------------------

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) {
                        _newImageFile = null;
                        _namaController.text = _currentUser!.namaLengkap;
                        _nimController.text = _currentUser!.nim;
                        _kelasController.text = _currentUser!.kelas;
                        // --- BARU: Reset controller Email saat batal ---
                        _emailController.text = _currentUser!.email;
                        // ---------------------------------------------
                      }
                    });
                  },
                  child: Text(
                    _isEditing ? 'Batal' : 'Edit Profil',
                    style: GoogleFonts.poppins(
                        color: _isEditing ? Colors.red : primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (_isEditing)
            ElevatedButton(
              // ...(Tombol Simpan tetap sama)...
              onPressed: _saveProfile,
              child: Text("Simpan Perubahan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

          if (!_isEditing) ...[
            // ...(Saran, Kesan, Notif, Logout tetap sama)...
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saran',
                style: GoogleFonts.poppins(
                    color: primary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mungkin saran dari saya terkait Mata Kuliah PAM adalah untuk deadline tugas akhir diberitahu sejak awal masuk kuliah supaya mahasiswa bisa lebih bersiap-siap dan mengatur jadwal akademik maupun non akademik dengan lebih efektif dan efisien',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 24),
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
              'Kesan dari saya yaitu Mata Kuliah PAM keren sekali karena saya tidak menyangka saya bisa melangkah sejauh ini. Selain itu, dari dulu saya bertanya-tanya bagaimana cara pengguna berinteraksi dengan aplikasi, dan akhirnya sekarang saya sudah melakukannya',
              textAlign: TextAlign.justify,
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                print("Tombol Notifikasi Demo Ditekan");
                await _notificationService.showNowReminderNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Notifikasi demo telah dikirim! Cek bar notifikasi Anda.'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                }
              },
              child: Text("Tampilkan Notifikasi Pengingat"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _logout,
              child: Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent[700],
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  // Helper untuk field edit (Nama, NIM, Kelas)
  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    // ...(Kode _buildEditableField Anda tetap sama)...
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: text),
          prefixIcon: Icon(icon, color: primary, size: 20),
          filled: true,
          fillColor: gray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: gray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }

  // --- BARU: Widget helper KHUSUS untuk Email (dengan validasi) ---
  Widget _buildEditableEmailField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        keyboardType: TextInputType.emailAddress, // Keyboard email
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: text),
          prefixIcon: Icon(icon, color: primary, size: 20),
          filled: true,
          fillColor: gray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: gray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary),
          ),
        ),
        validator: (value) { // Validasi email
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong';
          }
          final emailRegex =
              RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
          if (!emailRegex.hasMatch(value)) {
            return 'Masukkan format email yang valid';
          }
          return null;
        },
      ),
    );
  }
}