import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pam/models/user_model.dart';
import 'package:flutter_pam/models/bookmark_model.dart';

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

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'quran_app.db');
    return await openDatabase(
      path,
      version: 1, // PENTING: Jika Anda menambah tabel, ini harus dinaikkan
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // Anda akan butuh ini jika menaikkan versi
    );
  }

  Future _onCreate(Database db, int version) async {
    // Tabel Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaLengkap TEXT NOT NULL,
        nim TEXT UNIQUE NOT NULL,
        kelas TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL
      )
    ''');

    // Tabel Bookmarks
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        surah_nomor INTEGER NOT NULL,
        ayat_nomor INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE (user_id, surah_nomor, ayat_nomor) 
      )
    ''');
  }

  // --- Fungsi Hashing Password ---
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- Operasi CRUD untuk User ---
  Future<int> registerUser(User user) async {
    Database db = await database;
    String hashedPassword = _hashPassword(user.password);

    Map<String, dynamic> userMap = {
      'namaLengkap': user.namaLengkap,
      'nim': user.nim,
      'kelas': user.kelas,
      'username': user.username,
      'passwordHash': hashedPassword,
    };

    try {
      return await db.insert('users', userMap);
    } catch (e) {
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

  Future<User?> loginUser(String username, String password) async {
    Database db = await database;
    String hashedPassword = _hashPassword(password);

    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND passwordHash = ?',
      whereArgs: [username, hashedPassword],
    );

    if (maps.isNotEmpty) {
      Map<String, dynamic> userMap = Map.from(maps.first);
      userMap.remove('passwordHash');
      return User.fromDbMap(userMap);
    } else {
      return null;
    }
  }

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

  // --- FUNGSI CRUD UNTUK BOOKMARKS ---

  Future<int> addBookmark(Bookmark bookmark) async {
    Database db = await database;
    return await db.insert(
      'bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> removeBookmark(int userId, int surahNomor, int ayatNomor) async {
    Database db = await database;
    return await db.delete(
      'bookmarks',
      where: 'user_id = ? AND surah_nomor = ? AND ayat_nomor = ?',
      whereArgs: [userId, surahNomor, ayatNomor],
    );
  }

  Future<bool> isBookmarked(int userId, int surahNomor, int ayatNomor) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'user_id = ? AND surah_nomor = ? AND ayat_nomor = ?',
      whereArgs: [userId, surahNomor, ayatNomor],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<Set<int>> getBookmarkedAyatNomors(int userId, int surahNomor) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'user_id = ? AND surah_nomor = ?',
      whereArgs: [userId, surahNomor],
      columns: ['ayat_nomor'],
    );
    return maps.map((map) => map['ayat_nomor'] as int).toSet();
  }

  // --- FUNGSI BARU UNTUK HALAMAN BOOKMARK SCREEN ---
  // (Ini yang ditambahkan dari respons saya sebelumnya)

  /// Mengambil semua bookmark milik seorang user (untuk halaman BookmarkScreen)
  Future<List<Bookmark>> getAllUserBookmarks(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'surah_nomor ASC, ayat_nomor ASC', // Urutkan
    );
    return maps.map((map) => Bookmark.fromMap(map)).toList();
  }
}
