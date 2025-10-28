// lib/delegates/surah_search_delegate.dart (Contoh path)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk 'rootBundle'
// import 'dart:convert';
import 'package:flutter_pam/models/surah.dart'; // Sesuaikan path ke model Anda
import 'package:flutter_pam/globals.dart';
import 'package:google_fonts/google_fonts.dart';

class SurahSearchDelegate extends SearchDelegate<Surah?> {
  late Future<List<Surah>> _surahListFuture;

  SurahSearchDelegate() {
    // Panggil fungsi untuk memuat data DARI LOKAL
    _surahListFuture = _loadSurahsFromAsset();
  }

  // --- Fungsi untuk Membaca data dari list-surah.json ---
  Future<List<Surah>> _loadSurahsFromAsset() async {
    try {
      // 1. Muat string JSON dari file aset
      final String jsonString =
          await rootBundle.loadString('assets/datas/list-surah.json');

      // 2. Gunakan fungsi 'surahFromJson' dari model Anda
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
              onTap: () {
                close(context, surah);
                // TODO: Navigasi ke halaman detail surah
                // Navigator.push(context, MaterialPageRoute(
                //   builder: (context) => DetailScreen(surah: surah)
                // ));
              },
            );
          },
        );
      },
    );
  }

  // ================================================================
  // --- INI ADALAH BAGIAN YANG DIPERBAIKI ---
  // ================================================================
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      appBarTheme: AppBarTheme(
        // <-- 'const' ditambahkan
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        // 'headline6' diganti menjadi 'titleLarge'
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.normal, // Dibuat normal agar tidak tebal
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        // <-- 'const' ditambahkan
        hintStyle: TextStyle(color: text), // Warna 'Search...'
      ),
    );
  }
}
