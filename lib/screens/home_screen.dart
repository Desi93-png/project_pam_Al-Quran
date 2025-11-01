import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pam/globals.dart';
import 'package:flutter_pam/tabs/surah_tab.dart';

// --- Import Halaman Lain ---
// (Saya perbaiki import ini agar sesuai dengan apa yang Anda panggil)
import 'package:flutter_pam/screens/currency_converter_screen.dart'; 
import 'package:flutter_pam/screens/time_converter_screen.dart';
import 'package:flutter_pam/screens/bookmark_screen.dart';
import 'package:flutter_pam/screens/profile_screen.dart';

// --- Import Tambahan ---
import 'package:flutter_pam/delegates/surah_search_delegate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pam/helpers/database_helper.dart';

// --- Import untuk Notifikasi ---
import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_pam/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // final NotificationService _notificationService = NotificationService();

  List<Widget> _pages = [
    HomeTabContent(userId: null), // Mulai dengan userId null
    const KalkulatorZakatPage(),
    
    // --- PERBAIKAN 1: Menyamakan urutan _pages dengan items ---
    const TimeConverterScreen(), // Indeks 2 (Sholat)
    const BookmarkScreen(),      // Indeks 3 (Bookmark)
    // --- AKHIR PERBAIKAN 1 ---

    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndSetupPages();
    // Panggil fungsi izin (nama fungsinya tetap, tapi isinya kita ubah)
    _requestPermissionAndSchedule();
  }

  // --- PERBAIKAN 2: Hapus penjadwalan, sisakan permintaan izin ---
  Future<void> _requestPermissionAndSchedule() async {
    // 1. Minta izin (Ini akan memunculkan pop-up)
    PermissionStatus status = await Permission.notification.request();

    // 2. Cek statusnya (untuk debug)
    if (status.isGranted) {
      print("Izin notifikasi DIBERIKAN.");
      // KITA TIDAK MEMANGGIL scheduleDailyReminderNotification() LAGI
    } else {
      print("Izin notifikasi DITOLAK.");
    }
  }
  // --- AKHIR PERBAIKAN 2 ---

  Future<void> _loadUserAndSetupPages() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');

    if (mounted) {
      setState(() {
        _pages = [
          HomeTabContent(userId: userId), // Kirim userId ke HomeTabContent
          const KalkulatorZakatPage(), // Indeks 1
          
          // (Ubah urutan di sini juga agar konsisten)
          const TimeConverterScreen(), // Indeks 2
          const BookmarkScreen(),      // Indeks 3

          const ProfileScreen(), // Indeks 4
        ];
      });
    }
  }
  // --- AKHIR MODIFIKASI ---

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
          // Urutan ini sudah benar (sesuai UI)
          _bottomBarItem(icon: "assets/svgs/quran-icon.svg", label: "Quran"),   // 0
          _bottomBarItem(icon: "assets/svgs/money-icon.svg", label: "Zakat"),   // 1
          _bottomBarItem(icon: "assets/svgs/time-icon.svg", label: "Sholat"),  // 2
          _bottomBarItem(icon: "assets/svgs/bookmark-icon.svg", label: "Bookmark"), // 3
          _bottomBarItem(icon: "assets/svgs/profile-icon.svg", label: "Profile"),  // 4
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

// ... (Class HomeTabContent dan _HomeTabContentState Anda TIDAK BERUBAH) ...
class HomeTabContent extends StatefulWidget {
  final int? userId;
  HomeTabContent({super.key, required this.userId});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  String _userName = "Pengguna";
  bool _isLoadingName = true;
  final dbHelper = DatabaseHelper();
 
  @override
  void initState() {
    super.initState();
    _loadUserName(widget.userId);
  }

  @override
  void didUpdateWidget(HomeTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId && widget.userId != null) {
      print("HomeTabContent: userId diperbarui, memuat ulang nama...");
      _loadUserName(widget.userId);
    }
  }

  Future<void> _loadUserName(int? userId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingName = true;
    });
    try {
      if (userId != null) {
        final user = await dbHelper.getUserById(userId);
        if (user != null && mounted) {
          setState(() {
            _userName = user.namaLengkap;
            _isLoadingName = false;
          });
        } else if (mounted) {
          setState(() {
            _userName = "Pengguna";
            _isLoadingName = false;
          });
        }
      } else if (mounted) {
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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _appBar(context),
      body: DefaultTabController(
        length: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
            body: TabBarView(children: [
              SurahTab(userId: widget.userId) // Kirim userId ke tab
            ]),
          ),
        ),
      ),
    );
  }

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
                if (widget.userId != null) {
                  showSearch(
                    context: context,
                    delegate: SurahSearchDelegate(userId: widget.userId!),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("Masih memuat data user, coba sesaat lagi."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: SvgPicture.asset('assets/svgs/search-icon.svg')),
        ]),
      );

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
        Text(
          isLoading ? "Memuat..." : userName,
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