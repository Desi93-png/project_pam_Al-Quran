// Salin dan timpa seluruh file lib/screens/home_screen.dart Anda

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pam/globals.dart';
import 'package:flutter_pam/tabs/hijb_tab.dart';
import 'package:flutter_pam/tabs/page_tab.dart';
import 'package:flutter_pam/tabs/para_tab.dart';
import 'package:flutter_pam/tabs/surah_tab.dart';

// --- Import Halaman Lain ---
import 'package:flutter_pam/screens/currency_converter_screen.dart'; // Pastikan ini KalkulatorZakatPage
import 'package:flutter_pam/screens/time_converter_screen.dart';
import 'package:flutter_pam/screens/bookmark_screen.dart';
import 'package:flutter_pam/screens/profile_screen.dart';

// --- Import Search Delegate ---
import 'package:flutter_pam/delegates/surah_search_delegate.dart'; // Sesuaikan path

// ===================================================
// --- HomeScreen SEKARANG StatefulWidget ---
// ===================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Pindahkan state ke sini
  int _selectedIndex = 0;

  // Daftar halaman tetap sama
  final List<Widget> _pages = [
    const HomeTabContent(), // Halaman utama (Quran)
    const KalkulatorZakatPage(),
    const TimeConverterScreen(),
    const BookmarkScreen(),
    const ProfileScreen(),
  ];

  // Fungsi onTap untuk mengubah state
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      // Tampilkan halaman berdasarkan _selectedIndex
      body: _pages[_selectedIndex],
      // Bangun BottomNavigationBar di sini
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: gray,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        // Gunakan state _selectedIndex
        currentIndex: _selectedIndex,
        // Panggil fungsi _onItemTapped saat item diklik
        onTap: _onItemTapped,
        items: [
          // Panggil _bottomBarItem untuk setiap item
          _bottomBarItem(icon: "assets/svgs/quran-icon.svg", label: "Quran"),
          _bottomBarItem(
              icon: "assets/svgs/money-icon.svg",
              label: "Money"), // Sesuaikan ikon jika perlu
          _bottomBarItem(
              icon: "assets/svgs/time-icon.svg",
              label: "Time"), // Sesuaikan ikon jika perlu
          _bottomBarItem(
              icon: "assets/svgs/bookmark-icon.svg", label: "Bookmark"),
          _bottomBarItem(
              icon: "assets/svgs/profile-icon.svg", label: "Profile"),
        ],
      ),
    );
  }

  // Metode _bottomBarItem tetap sama
  BottomNavigationBarItem _bottomBarItem(
          {required String icon, required String label}) =>
      BottomNavigationBarItem(
          icon: SvgPicture.asset(
            icon,
            // ignore: deprecated_member_use
            color: text, // Warna ikon tidak aktif
          ),
          activeIcon: SvgPicture.asset(
            icon,
            // ignore: deprecated_member_use
            color: primary, // Warna ikon aktif
          ),
          label: label);
}

// ===================================================
// Class HomeTabContent (Tetap StatelessWidget, tidak berubah dari sebelumnya)
// ===================================================
class HomeTabContent extends StatelessWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _appBar(context), // Panggil _appBar (NON-STATIC)
      body: DefaultTabController(
        length: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: _greeting()),
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: background,
                automaticallyImplyLeading: false,
                shape: Border(
                    bottom: BorderSide(
                        width: 3,
                        color: const Color(0xFFAAAAAA).withOpacity(.1))),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0),
                  child: _tab(),
                ),
              )
            ],
            body: const TabBarView(
                children: [SurahTab(), ParaTab(), PageTab(), HijbTab()]),
          ),
        ),
      ),
    );
  }

  // --- AppBar untuk HomeTabContent ---
  AppBar _appBar(BuildContext context) => AppBar(
        backgroundColor: background,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(children: [
          IconButton(
              onPressed: (() => {}), // TODO: Implementasi menu drawer?
              icon: SvgPicture.asset('assets/svgs/menu-icon.svg')),
          const SizedBox(width: 24),
          Text(
            'Quran App',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          IconButton(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: SurahSearchDelegate(),
                );
              },
              icon: SvgPicture.asset('assets/svgs/search-icon.svg')),
        ]),
      );

  // --- Widget-widget statis untuk HomeTabContent ---

  TabBar _tab() {
    return TabBar(
        unselectedLabelColor: text,
        labelColor: Colors.white,
        indicatorColor: primary,
        indicatorWeight: 3,
        tabs: [
          _tabItem(label: "Surah"),
          _tabItem(label: "Para"),
          _tabItem(label: "Page"),
          _tabItem(label: "Hijb"),
        ]);
  }

  Tab _tabItem({required String label}) {
    return Tab(
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Column _greeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamualaikum',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w500, color: text),
        ),
        const SizedBox(height: 4),
        Text(
          'Desi Pangestuti', // TODO: Ganti dengan nama pengguna login
          style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 24),
        _lastRead()
      ],
    );
  }

  Stack _lastRead() {
    return Stack(
      children: [
        Container(
          height: 131,
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
            child: SvgPicture.asset('assets/svgs/quran.svg')),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/svgs/book.svg'),
                  const SizedBox(width: 8),
                  Text(
                    'Have You Read',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Al-Quran',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Today?',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        )
      ],
    );
  }
}
