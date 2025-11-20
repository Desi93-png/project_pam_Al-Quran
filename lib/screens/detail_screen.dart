import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pam/globals.dart';
import 'package:flutter_pam/models/ayat.dart';
import 'package:flutter_pam/models/surah.dart';
import 'package:flutter_pam/helpers/database_helper.dart';
import 'package:flutter_pam/models/bookmark_model.dart';

import 'package:flutter_pam/services/notification_service.dart';

class DetailScreen extends StatefulWidget {
  final int noSurat;
  final int userId;

  const DetailScreen({super.key, required this.noSurat, required this.userId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<Surah> _surahFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final NotificationService _notificationService = NotificationService();

  final Set<int> _bookmarkedAyatNomors = {};
  bool _bookmarksLoaded = false;

  @override
  void initState() {
    super.initState();
    _surahFuture = _getDetailSurah();
    _loadBookmarks();
  }

  Future<Surah> _getDetailSurah() async {
    var data = await Dio().get("https://equran.id/api/surat/${widget.noSurat}");
    return Surah.fromJson(json.decode(data.toString()));
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _dbHelper.getBookmarkedAyatNomors(
          widget.userId, widget.noSurat);
      if (mounted) {
        setState(() {
          _bookmarkedAyatNomors.addAll(bookmarks);
        });
      }
    } catch (e) {
      print("Gagal memuat bookmark: $e");
    } finally {
      if (mounted) {
        setState(() {
          _bookmarksLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Surah>(
        future: _surahFuture,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {}

          if (snapshot.hasData && _bookmarksLoaded) {
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

                      return _ayatItem(
                        ayat: ayat,
                        surah: surah,
                      );
                    },
                    itemCount:
                        surah.jumlahAyat + (widget.noSurat == 1 ? -1 : 0),
                    separatorBuilder: (context, index) => Container(),
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }));
  }

  Widget _ayatItem({required Ayat ayat, required Surah surah}) {
    final bool isBookmarked = _bookmarkedAyatNomors.contains(ayat.nomor);

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
                const SizedBox(width: 16),
                const SizedBox(width: 16),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isBookmarked) {
                        _bookmarkedAyatNomors.remove(ayat.nomor);
                        _dbHelper.removeBookmark(
                            widget.userId, surah.nomor, ayat.nomor);

                        _notificationService.showSimpleNotification(
                            id: Random().nextInt(1000),
                            title: "Bookmark Dihapus",
                            body:
                                "Ayat ${ayat.nomor} dari Q.S. ${surah.namaLatin} telah dihapus.");
                      } else {
                        _bookmarkedAyatNomors.add(ayat.nomor);
                        final newBookmark = Bookmark(
                            userId: widget.userId,
                            surahNomor: surah.nomor,
                            ayatNomor: ayat.nomor);
                        _dbHelper.addBookmark(newBookmark);

                        _notificationService.showSimpleNotification(
                            id: Random().nextInt(1000),
                            title: "Bookmark Ditambahkan",
                            body:
                                "Ayat ${ayat.nomor} dari Q.S. ${surah.namaLatin} telah disimpan.");
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            ayat.ar,
            style: GoogleFonts.amiri(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          Text(
            ayat.idn,
            style: GoogleFonts.poppins(color: text, fontSize: 16),
          )
        ],
      ),
    );
  }

  Widget _details({required Surah surah}) => Padding(
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
                SvgPicture.asset('assets/svgs/bismillah.svg')
              ],
            ),
          )
        ]),
      );

  AppBar _appBar({required BuildContext context, required Surah surah}) =>
      AppBar(
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
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
        ]),
      );
}
