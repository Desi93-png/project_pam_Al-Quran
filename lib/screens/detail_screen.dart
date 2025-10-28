import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pam/globals.dart'; // Asumsi 'globals.dart' berisi variabel 'background', 'gray', 'primary', 'text'
import 'package:flutter_pam/models/ayat.dart';
import 'package:flutter_pam/models/surah.dart';

// 1. KELAS BARU UNTUK MENGELOLA BOOKMARK SECARA GLOBAL
//    Data 'static' akan tetap ada walaupun Anda berpindah halaman.
class BookmarkService {
  // Kita gunakan Set<String> untuk menyimpan key unik, cth: "1:5" (Surah 1, Ayat 5)
  static final Set<String> _bookmarkedAyats = {};

  // Helper untuk membuat key yang unik
  static String _getKey(int surahNomor, int ayatNomor) {
    return "$surahNomor:$ayatNomor";
  }

  // Cek apakah ayat sudah di-bookmark
  static bool isBookmarked(int surahNomor, int ayatNomor) {
    final key = _getKey(surahNomor, ayatNomor);
    return _bookmarkedAyats.contains(key);
  }

  // Toggle status bookmark
  static void toggleBookmark(int surahNomor, int ayatNomor) {
    final key = _getKey(surahNomor, ayatNomor);
    if (_bookmarkedAyats.contains(key)) {
      _bookmarkedAyats.remove(key);
    } else {
      _bookmarkedAyats.add(key);
    }
  }
}
// AKHIR DARI KELAS BARU

class DetailScreen extends StatefulWidget {
  final int noSurat;
  const DetailScreen({super.key, required this.noSurat});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // 2. HAPUS variabel state _bookmarkedAyats dari sini.
  //    final Set<int> _bookmarkedAyats = {}; <--- HAPUS INI

  Future<Surah> _getDetailSurah() async {
    var data = await Dio().get("https://equran.id/api/surat/${widget.noSurat}");
    return Surah.fromJson(json.decode(data.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Surah>(
        future: _getDetailSurah(),
        initialData: null,
        builder: ((context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: background,
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          Surah surah = snapshot.data!;
          return Scaffold(
            backgroundColor: background,
            appBar: _appBar(context: context, surah: surah),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _details(surah: surah),
                )
              ],
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final ayat = surah.ayat!
                        .elementAt(index + (widget.noSurat == 1 ? 1 : 0));

                    // 3. Kirim nomor surah ke _ayatItem
                    return _ayatItem(ayat: ayat, surahNomor: surah.nomor);
                  },
                  itemCount: surah.jumlahAyat + (widget.noSurat == 1 ? -1 : 0),
                  separatorBuilder: (context, index) => Container(),
                ),
              ),
            ),
          );
        }));
  }

  // 4. Modifikasi _ayatItem untuk menerima 'surahNomor'
  Widget _ayatItem({required Ayat ayat, required int surahNomor}) {
    // 5. Cek status bookmark dari 'BookmarkService', bukan dari state lokal
    final bool isBookmarked =
        BookmarkService.isBookmarked(surahNomor, ayat.nomor);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: gray, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(27 / 2)),
                  child: Center(
                      child: Text(
                    '${ayat.nomor}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: Colors.white),
                  )),
                ),
                const Spacer(),
                const SizedBox(
                  width: 16,
                ),
                // const Icon(
                //   Icons.play_arrow_outlined,
                //   color: Colors.white,
                // ),
                const SizedBox(
                  width: 16,
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // 6. Panggil setState agar UI di-rebuild
                    setState(() {
                      // 7. Update status bookmark di 'BookmarkService'
                      BookmarkService.toggleBookmark(surahNomor, ayat.nomor);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            ayat.ar,
            style: GoogleFonts.amiri(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.right,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            ayat.idn,
            style: GoogleFonts.poppins(color: text, fontSize: 16),
          )
        ],
      ),
    );
  }

  Widget _details({required Surah surah}) {
    // ... (Tidak ada perubahan di sini)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(children: [
        Container(
          height: 257,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    0,
                    .6,
                    1
                  ],
                  colors: [
                    Color(0xFFDF98FA),
                    Color(0xFFB070FD),
                    Color(0xFF9055FF)
                  ])),
        ),
        Positioned(
            bottom: 0,
            right: 0,
            child: Opacity(
                opacity: .2,
                child: SvgPicture.asset(
                  'assets/svgs/quran.svg',
                  width: 324 - 55,
                ))),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Text(
                surah.namaLatin,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 26),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                surah.arti,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16),
              ),
              Divider(
                color: Colors.white.withOpacity(.35),
                thickness: 2,
                height: 32,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    surah.tempatTurun.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    "${surah.jumlahAyat} Ayat",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 32,
              ),
              if (surah.nomor != 1 &&
                  surah.nomor !=
                      9) // Bismillah hanya untuk surah selain Al-Fatihah & At-Taubah
                SvgPicture.asset('assets/svgs/bismillah.svg')
            ],
          ),
        )
      ]),
    );
  }

  AppBar _appBar({required BuildContext context, required Surah surah}) {
    return AppBar(
      backgroundColor: background,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Row(children: [
        IconButton(
            onPressed: (() => Navigator.of(context).pop()),
            icon: SvgPicture.asset('assets/svgs/back-icon.svg')),
        const SizedBox(
          width: 24,
        ),
        Text(
          surah.namaLatin,
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const Spacer(),
      ]),
    );
  }
}
