// Salin dan timpa seluruh file lib/delegates/surah_search_delegate.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk 'rootBundle'
import 'package:flutter_pam/models/surah.dart'; // Sesuaikan path ke model Anda
import 'package:flutter_pam/globals.dart'; // Import globals untuk warna
import 'package:google_fonts/google_fonts.dart';

// --- BARU: Import DetailScreen ---
import 'package:flutter_pam/screens/detail_screen.dart'; // <-- Sesuaikan path ke DetailScreen Anda

// Pastikan Anda sudah mendaftarkan 'assets/datas/list-surah.json' di pubspec.yaml
class SurahSearchDelegate extends SearchDelegate<Surah?> {
  late Future<List<Surah>> _surahListFuture;

  SurahSearchDelegate() {
    // Panggil fungsi untuk memuat data DARI LOKAL
    _surahListFuture = _loadSurahsFromAsset();
  }

  // --- Fungsi untuk Membaca data dari list-surah.json ---
  Future<List<Surah>> _loadSurahsFromAsset() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/datas/list-surah.json');
      final List<Surah> surahs = surahFromJson(jsonString);
      return surahs;
    } catch (e) {
      throw Exception('Gagal memuat list-surah.json: $e');
    }
  }

  // Tombol 'clear' (X) di sebelah kanan
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: text),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      )
    ];
  }

  // Tombol 'back' (<-) di sebelah kiri
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null); // Tutup search bar
      },
    );
  }

  // Tampilan hasil (saat menekan 'search' di keyboard)
  @override
  Widget buildResults(BuildContext context) {
    return _buildFutureResults();
  }

  // Tampilan saran (saat pengguna mengetik)
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildFutureResults();
  }

  // --- Widget Helper untuk menampilkan hasil pencarian ---
  Widget _buildFutureResults() {
    return FutureBuilder<List<Surah>>(
      future: _surahListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primary));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('Tidak ada data surah.',
                  style: TextStyle(color: Colors.white)));
        }

        final allSurahs = snapshot.data!;

        // --- Logika Filter ---
        final filteredList = allSurahs.where((surah) {
          final queryLower = query.toLowerCase();
          final namaLatinLower = surah.namaLatin.toLowerCase();
          final artiLower = surah.arti.toLowerCase();
          final nomorString = surah.nomor.toString();

          return namaLatinLower.contains(queryLower) ||
              artiLower.contains(queryLower) ||
              nomorString.contains(queryLower);
        }).toList();

        if (filteredList.isEmpty) {
          return Center(
              child: Text('Surah tidak ditemukan.',
                  style: TextStyle(color: Colors.white)));
        }

        // --- Tampilkan Hasil ---
        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final surah = filteredList[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: primary,
                child: Text(surah.nomor.toString(),
                    style: TextStyle(color: Colors.white)),
              ),
              title:
                  Text(surah.namaLatin, style: TextStyle(color: Colors.white)),
              subtitle: Text('${surah.arti} - ${surah.jumlahAyat} Ayat',
                  style: TextStyle(color: text)),
              trailing: Text(surah.nama,
                  style: GoogleFonts.amiri(color: primary, fontSize: 20)),

              // --- MODIFIKASI: Navigasi ke DetailScreen ---
              onTap: () {
                // 1. Tutup halaman search (opsional, tapi bagus agar tidak menumpuk)
                // Jika Anda ingin search tetap terbuka di belakang, hapus baris ini
                // close(context, surah);

                // 2. Navigasi ke DetailScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Kirim nomor surah ke DetailScreen
                    builder: (context) => DetailScreen(noSurat: surah.nomor),
                  ),
                );
              },
              // ------------------------------------------
            );
          },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.normal,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: text), // Warna 'Search...'
      ),
    );
  }
}
