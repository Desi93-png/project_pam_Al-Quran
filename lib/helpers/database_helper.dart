import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart'; // Untuk hashing
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pam/models/user_model.dart'; // Kita akan buat model ini

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inisialisasi database
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'quran_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Buat tabel saat database pertama kali dibuat
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaLengkap TEXT NOT NULL,
        nim TEXT UNIQUE NOT NULL,
        kelas TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL
        -- Tambahkan foto_path jika diperlukan nanti
        -- foto_path TEXT
      )
    ''');
    // Tambahkan tabel lain jika perlu (misal: bookmarks, saran_kesan)
  }

  // --- Fungsi Hashing Password ---
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Encode password ke bytes
    final digest = sha256.convert(bytes); // Lakukan hashing SHA-256
    return digest.toString(); // Kembalikan hash sebagai string
  }

  // --- Operasi CRUD untuk User ---

  // Registrasi User Baru
  Future<int> registerUser(User user) async {
    Database db = await database;
    // Hash password sebelum disimpan
    String hashedPassword =
        _hashPassword(user.password); // Gunakan password asli dari model

    // Buat Map baru tanpa password asli, ganti dengan hash
    Map<String, dynamic> userMap = {
      'namaLengkap': user.namaLengkap,
      'nim': user.nim,
      'kelas': user.kelas,
      'username': user.username,
      'passwordHash': hashedPassword, // Simpan hash-nya
    };

    try {
      return await db.insert('users', userMap);
    } catch (e) {
      // Tangani error jika username atau NIM sudah ada (UNIQUE constraint failed)
      print('Error saat registrasi: $e');
      if (e.toString().contains('UNIQUE constraint failed: users.username')) {
        throw Exception('Username sudah digunakan.');
      } else if (e.toString().contains('UNIQUE constraint failed: users.nim')) {
        throw Exception('NIM sudah terdaftar.');
      } else {
        throw Exception('Registrasi gagal, terjadi kesalahan.');
      }
    }
  }

  // Login User
  Future<User?> loginUser(String username, String password) async {
    Database db = await database;
    String hashedPassword = _hashPassword(password);

    // Cari user berdasarkan username DAN hash password yang cocok
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND passwordHash = ?',
      whereArgs: [username, hashedPassword],
    );

    if (maps.isNotEmpty) {
      // Jika ditemukan, kembalikan data user (tanpa password hash)
      Map<String, dynamic> userMap = Map.from(maps.first);
      userMap.remove('passwordHash'); // Jangan kirim hash ke UI
      // Kita perlu membuat User model dari map ini, TAPI password asli tidak ada
      // Jadi kita buat User model tanpa password asli
      return User.fromDbMap(userMap);
    } else {
      // Jika tidak ditemukan (username atau password salah)
      return null;
    }
  }

  // (Opsional) Ambil data user berdasarkan ID (misal untuk halaman profil)
  Future<User?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      Map<String, dynamic> userMap = Map.from(maps.first);
      userMap.remove('passwordHash');
      return User.fromDbMap(userMap);
    }
    return null;
  }
}
