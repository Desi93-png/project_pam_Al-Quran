import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pam/helpers/database_helper.dart';
import 'package:flutter_pam/models/bookmark_model.dart';
import 'package:flutter_pam/models/surah.dart';
import 'package:flutter_pam/globals.dart';
import 'package:flutter_pam/screens/detail_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<Map<String, dynamic>> _dataFuture;
  int? _userId;

  @override
  void initState() {
    super.initState();

    _dataFuture = _loadData();
  }

  Future<List<Surah>> _loadSurahsFromAsset() async {
    String data = await rootBundle.loadString('assets/datas/list-surah.json');
    return surahFromJson(data);
  }

  Future<Map<String, dynamic>> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');

    if (_userId == null) {
      throw Exception('User tidak terautentikasi');
    }

    final results = await Future.wait([
      _dbHelper.getAllUserBookmarks(_userId!),
      _loadSurahsFromAsset(),
    ]);

    return {
      'bookmarks': results[0] as List<Bookmark>,
      'surahs': results[1] as List<Surah>,
    };
  }

  String _getSurahName(List<Surah> allSurahs, int surahNomor) {
    try {
      return allSurahs.firstWhere((s) => s.nomor == surahNomor).namaLatin;
    } catch (e) {
      return 'Surah $surahNomor';
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
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat data: ${snapshot.error}",
                style: GoogleFonts.poppins(color: text),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "Tidak ada data.",
                style: GoogleFonts.poppins(color: text),
              ),
            );
          }

          final bookmarks = snapshot.data!['bookmarks'] as List<Bookmark>;
          final allSurahs = snapshot.data!['surahs'] as List<Surah>;

          if (bookmarks.isEmpty) {
            return Center(
              child: Text(
                "Anda belum menambahkan ayat ke bookmark",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: text, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: bookmarks.length,
            separatorBuilder: (context, index) =>
                Divider(color: const Color(0xFF7B80AD).withOpacity(.35)),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        noSurat: bookmark.surahNomor,
                        userId: _userId!,
                      ),
                    ),
                  ).then((_) {
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
