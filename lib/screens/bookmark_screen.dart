// lib/screens/bookmark_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk rootBundle
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pam/helpers/database_helper.dart';
import 'package:flutter_pam/models/bookmark_model.dart';
import 'package:flutter_pam/models/surah.dart'; // Dibutuhkan untuk nama surah
import 'package:flutter_pam/globals.dart'; // Untuk warna
import 'package:flutter_pam/screens/detail_screen.dart'; // Untuk navigasi

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<Map<String, dynamic>> _dataFuture;
  int? _userId; // Untuk menyimpan ID user yang login

  @override
  void initState() {
    super.initState();
    // Memulai proses load data saat halaman dibuka
    _dataFuture = _loadData();
  }

  // Fungsi untuk memuat list surah dari asset JSON
  Future<List<Surah>> _loadSurahsFromAsset() async {
    String data = await rootBundle.loadString('assets/datas/list-surah.json');
    return surahFromJson(data);
  }

  // Fungsi utama untuk mengambil semua data yang diperlukan
  Future<Map<String, dynamic>> _loadData() async {
    // 1. Ambil userId dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');

    if (_userId == null) {
      // Jika user tidak login (seharusnya tidak mungkin jika halaman ini terproteksi)
      throw Exception('User tidak terautentikasi');
    }

    // 2. Ambil data bookmarks dan data nama surah secara bersamaan
    final results = await Future.wait([
      _dbHelper.getAllUserBookmarks(_userId!),
      _loadSurahsFromAsset(),
    ]);

    // 3. Kembalikan data dalam bentuk Map
    return {
      'bookmarks': results[0] as List<Bookmark>,
      'surahs': results[1] as List<Surah>,
    };
  }

  // Helper untuk mencari nama surah berdasarkan nomor surah
  String _getSurahName(List<Surah> allSurahs, int surahNomor) {
    try {
      // Cari surah di list yang nomornya cocok
      return allSurahs.firstWhere((s) => s.nomor == surahNomor).namaLatin;
    } catch (e) {
      return 'Surah $surahNomor'; // Tampilkan nomor jika gagal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          "Bookmarks",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        automaticallyImplyLeading: false, // Menghilangkan tombol back
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          // 1. Saat data sedang di-load
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          }

          // 2. Jika terjadi error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat data: ${snapshot.error}",
                style: GoogleFonts.poppins(color: text),
              ),
            );
          }

          // 3. Jika data tidak ada
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "Tidak ada data.",
                style: GoogleFonts.poppins(color: text),
              ),
            );
          }

          // 4. Jika data berhasil di-load
          final bookmarks = snapshot.data!['bookmarks'] as List<Bookmark>;
          final allSurahs = snapshot.data!['surahs'] as List<Surah>;

          // --- INI ADALAH BAGIAN YANG ANDA MINTA ---
          // 5. Jika daftar bookmark kosong
          if (bookmarks.isEmpty) {
            return Center(
              child: Text(
                "Anda belum menambahkan ayat ke bookmark",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: text, fontSize: 16),
              ),
            );
          }
          // --- AKHIR DARI BAGIAN YANG ANDA MINTA ---

          // 6. Jika ada bookmark, tampilkan ListView
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: bookmarks.length,
            separatorBuilder: (context, index) =>
                Divider(color: const Color(0xFF7B80AD).withOpacity(.35)),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              // Dapatkan nama surah dari nomornya
              final surahName = _getSurahName(allSurahs, bookmark.surahNomor);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: primary.withOpacity(0.2),
                  child: Text(
                    bookmark.surahNomor.toString(),
                    style: GoogleFonts.poppins(
                        color: primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  "$surahName: Ayat ${bookmark.ayatNomor}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: text),
                onTap: () {
                  // Navigasi ke DetailScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        noSurat: bookmark.surahNomor,
                        userId: _userId!, // Kita tahu _userId tidak null di sini
                      ),
                    ),
                  ).then((_) {
                    // Ini akan dijalankan saat Anda kembali dari DetailScreen
                    // Ini penting untuk me-refresh halaman jika Anda menghapus bookmark
                    setState(() {
                      _dataFuture = _loadData();
                    });
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}