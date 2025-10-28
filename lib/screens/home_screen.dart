import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pam/globals.dart';
import 'package:flutter_pam/tabs/surah_tab.dart';

// --- Import Halaman Lain ---
import 'package:flutter_pam/screens/currency_converter_screen.dart'; // KalkulatorZakatPage
import 'package:flutter_pam/screens/time_converter_screen.dart';
import 'package:flutter_pam/screens/bookmark_screen.dart';
import 'package:flutter_pam/screens/profile_screen.dart';

// --- Import Tambahan ---
import 'package:flutter_pam/delegates/surah_search_delegate.dart'; // Search
import 'package:shared_preferences/shared_preferences.dart'; // Session
import 'package:flutter_pam/helpers/database_helper.dart'; // Database

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- Daftar Halaman (Widget HomeTabContent SEKARANG perlu dibuat instance baru) ---
  // Kita tidak bisa pakai 'const' lagi karena HomeTabContent jadi StatefulWidget
  final List<Widget> _pages = [
    HomeTabContent(), // Hapus 'const'
    const KalkulatorZakatPage(),
    const TimeConverterScreen(),
    const BookmarkScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: gray,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          _bottomBarItem(icon: "assets/svgs/quran-icon.svg", label: "Quran"),
          _bottomBarItem(
              icon: "assets/svgs/money-icon.svg",
              label: "Zakat"), // Ganti label jika perlu
          _bottomBarItem(
              icon: "assets/svgs/time-icon.svg",
              label: "Sholat"), // Ganti label jika perlu
          _bottomBarItem(
              icon: "assets/svgs/bookmark-icon.svg", label: "Bookmark"),
          _bottomBarItem(
              icon: "assets/svgs/profile-icon.svg", label: "Profile"),
        ],
      ),
    );
  }

  BottomNavigationBarItem _bottomBarItem(
          {required String icon, required String label}) =>
      BottomNavigationBarItem(
          icon: SvgPicture.asset(
            icon,
            color: text,
          ),
          activeIcon: SvgPicture.asset(
            icon,
            color: primary,
          ),
          label: label);
}

// ===================================================
// --- HomeTabContent SEKARANG StatefulWidget ---
// ===================================================
class HomeTabContent extends StatefulWidget {
  // Hapus 'const' dari constructor
  HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  // --- State untuk menyimpan nama pengguna ---
  String _userName = "Pengguna"; // Default name
  bool _isLoadingName = true;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadUserName(); // Panggil fungsi load nama saat widget dibuat
  }

  // --- Fungsi untuk memuat nama pengguna ---
  Future<void> _loadUserName() async {
    if (!mounted) return;
    setState(() {
      _isLoadingName = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      if (userId != null) {
        final user = await dbHelper.getUserById(userId);
        if (user != null && mounted) {
          setState(() {
            // Ambil nama lengkap dari user
            _userName = user.namaLengkap;
            _isLoadingName = false;
          });
        } else if (mounted) {
          // User tidak ditemukan di DB
          setState(() {
            _userName = "Pengguna";
            _isLoadingName = false;
          });
        }
      } else if (mounted) {
        // User ID tidak ada di session
        setState(() {
          _userName = "Pengguna";
          _isLoadingName = false;
        });
      }
    } catch (e) {
      print("Error loading user name: $e");
      if (mounted) {
        setState(() {
          _userName = "Pengguna";
          _isLoadingName = false;
        }); // Fallback jika error
      }
    }
  }

  // --- Build Method (Tidak berubah signifikan) ---
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
              // --- Kirim nama pengguna ke _greeting ---
              SliverToBoxAdapter(child: _greeting(_userName, _isLoadingName)),
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
            body: const TabBarView(children: [SurahTab()]),
          ),
        ),
      ),
    );
  }

  // --- AppBar untuk HomeTabContent (Tidak Berubah) ---
  AppBar _appBar(BuildContext context) => AppBar(
        backgroundColor: background,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(children: [
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

  // --- Widget-widget statis/helper untuk HomeTabContent ---
  // Metode ini TIDAK perlu 'static' lagi karena dipanggil dari instance _HomeTabContentState

  TabBar _tab() {
    return TabBar(
        unselectedLabelColor: text,
        labelColor: Colors.white,
        indicatorColor: primary,
        indicatorWeight: 1,
        tabs: [
          _tabItem(label: "Surah"),
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

  // --- Modifikasi _greeting untuk menerima nama ---
  Column _greeting(String userName, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamualaikum',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w500, color: text),
        ),
        const SizedBox(height: 4),
        // --- Tampilkan nama dinamis atau loading ---
        Text(
          isLoading ? "Memuat..." : userName, // Tampilkan nama atau loading
          style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        // ------------------------------------------
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
