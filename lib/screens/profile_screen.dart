import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pam/globals.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _appBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Center(
                  child: CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/images/desi.jpg'),
              )),
              const SizedBox(height: 24),
              Text(
                'Desi Pangestuti',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('NIM: 1234567890',
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
              Text('Kelas: TI-4A',
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saran',
                  style: GoogleFonts.poppins(
                      color: primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aplikasi ini sangat membantu untuk membaca Al-Qur\'an secara digital. '
                'Tampilan antarmukanya menarik, dan fitur navigasi antar Surah maupun Juz mudah digunakan. '
                'Semoga ke depan bisa ditambahkan fitur bookmark dan tafsir ayat agar semakin lengkap.',
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kesan',
                  style: GoogleFonts.poppins(
                      color: primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aplikasi ini sangat membantu untuk membaca Al-Qur\'an secara digital. '
                'Tampilan antarmukanya menarik, dan fitur navigasi antar Surah maupun Juz mudah digunakan. '
                'Semoga ke depan bisa ditambahkan fitur bookmark dan tafsir ayat agar semakin lengkap.',
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar() => AppBar(
        backgroundColor: background,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
                onPressed: (() => {}),
                icon: SvgPicture.asset('assets/svgs/menu-icon.svg')),
            const SizedBox(width: 24),
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const Spacer(),
            IconButton(
                onPressed: (() => {}),
                icon: SvgPicture.asset('assets/svgs/search-icon.svg')),
          ],
        ),
      );
}
