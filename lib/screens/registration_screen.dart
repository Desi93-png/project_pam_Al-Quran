import 'package:flutter/material.dart';
import 'package:flutter_pam/helpers/database_helper.dart';
import 'package:flutter_pam/models/user_model.dart';
import 'package:flutter_pam/globals.dart'; // Untuk warna
import 'package:google_fonts/google_fonts.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _kelasController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final dbHelper = DatabaseHelper();

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _kelasController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Hapus pesan error lama
    });

    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = "Konfirmasi password tidak cocok.";
          _isLoading = false;
        });
        return; // Hentikan proses jika password tidak cocok
      }

      // Buat objek User
      User newUser = User(
        namaLengkap: _namaController.text,
        nim: _nimController.text,
        kelas: _kelasController.text,
        username: _usernameController.text,
        password: _passwordController.text, // Kirim password asli ke helper
      );

      try {
        int result = await dbHelper.registerUser(newUser);
        if (result > 0) {
          // Registrasi berhasil
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
          );
          Navigator.pop(context); // Kembali ke halaman login
        } else {
          // Seharusnya tidak terjadi jika ID auto-increment
          setState(() {
            _errorMessage = 'Registrasi gagal, coba lagi.';
          });
        }
      } catch (e) {
        // Tangani error dari DatabaseHelper (misal: username/NIM sudah ada)
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', ''); // Tampilkan pesan error
        });
      } finally {
        if (mounted) {
           setState(() { _isLoading = false; });
        }
      }
    } else {
       if (mounted) {
          setState(() { _isLoading = false; });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text("Registrasi Akun"),
        backgroundColor: background,
        elevation: 0,
        leading: IconButton( // Tombol back manual
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              _buildTextField(_namaController, "Nama Lengkap"),
              const SizedBox(height: 16),
              _buildTextField(_nimController, "NIM"),
              const SizedBox(height: 16),
              _buildTextField(_kelasController, "Kelas"),
              const SizedBox(height: 16),
              _buildTextField(_usernameController, "Username"),
              const SizedBox(height: 16),
              _buildPasswordField(_passwordController, "Password"),
              const SizedBox(height: 16),
              _buildPasswordField(_confirmPasswordController, "Konfirmasi Password"),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Daftar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper untuk TextField biasa
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white), // Warna teks input
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: text), // Warna label
        filled: true,
        fillColor: gray, // Warna background field
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
          borderSide: BorderSide(color: primary), // Border saat fokus
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }

  // Widget helper untuk TextField password
  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      obscureText: true, // Sembunyikan teks
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
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
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        if (label == "Password" && value.length < 6) {
           return 'Password minimal 6 karakter';
        }
        return null;
      },
    );
  }
}
