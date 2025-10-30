// lib/delegates/surah_search_delegate.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pam/models/surah.dart';
import 'package:flutter_pam/globals.dart';
import 'package:google_fonts/google_fonts.dart';
// Import DetailScreen
import 'package:flutter_pam/screens/detail_screen.dart';

class SurahSearchDelegate extends SearchDelegate<Surah?> {
  // --- 1. TAMBAHKAN VARIABLE UNTUK MENYIMPAN USER ID ---
  final int userId;

  late Future<List<Surah>> _surahListFuture;

  // --- 2. MODIFIKASI KONSTRUKTOR UNTUK MENERIMA USER ID ---
  SurahSearchDelegate({required this.userId}) {
    _surahListFuture = _loadSurahsFromAsset();
  }

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

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildFutureResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildFutureResults();
  }

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

              // --- 3. PERBAIKI NAVIGASI DI SINI ---
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Kirimkan 'noSurat' DAN 'userId'
                    builder: (context) => DetailScreen(
                      noSurat: surah.nomor,
                      userId: this.userId, // <-- TAMBAHKAN INI
                    ),
                  ),
                );
              },
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
        hintStyle: TextStyle(color: text),
      ),
    );
  }
}
