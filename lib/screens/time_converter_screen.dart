import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Untuk format tanggal dan waktu
import 'package:flutter_pam/globals.dart'; // Import globals untuk warna
import 'package:google_fonts/google_fonts.dart';

// Model untuk menampung jadwal sholat (ditambah Imsak & Sunrise)
class PrayerTimes {
  final String imsak;
  final String fajr;
  final String sunrise; // Waktu Terbit Matahari (Syuruq)
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;
  final String timezone;

  PrayerTimes({
    required this.imsak,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.timezone,
  });

  // Factory constructor untuk parse JSON dari Aladhan API
  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'];
    final dateInfo = json['data']['date']['readable'];
    final timezone = json['data']['meta']['timezone'];

    // Fungsi helper untuk format waktu HH:mm (tidak perlu parsing ulang)
    String formatTime(String time) => time;

    return PrayerTimes(
      imsak: formatTime(timings['Imsak']),
      fajr: formatTime(timings['Fajr']),
      sunrise: formatTime(timings['Sunrise']), // Ambil data Sunrise
      dhuhr: formatTime(timings['Dhuhr']),
      asr: formatTime(timings['Asr']),
      maghrib: formatTime(timings['Maghrib']),
      isha: formatTime(timings['Isha']),
      date: dateInfo,
      timezone: timezone,
    );
  }
}

class TimeConverterScreen extends StatefulWidget {
  const TimeConverterScreen({super.key});

  @override
  State<TimeConverterScreen> createState() => _TimeConverterScreenState();
}

class _TimeConverterScreenState extends State<TimeConverterScreen> {
  // Daftar kota dan parameter API-nya
  final Map<String, Map<String, String>> _locations = {
    'Jakarta (WIB)': {'city': 'Jakarta', 'country': 'Indonesia'},
    'Makassar (WITA)': {'city': 'Makassar', 'country': 'Indonesia'},
    'Jayapura (WIT)': {'city': 'Jayapura', 'country': 'Indonesia'},
    'London (GMT/BST)': {'city': 'London', 'country': 'UK'},
    'Sydney (AEDT/AEST)': {'city': 'Sydney', 'country': 'Australia'},
    'Nagoya (JST)': {'city': 'Nagoya', 'country': 'Japan'},
    // Opsional: 'Mekkah (AST)': {'city': 'Makkah', 'country': 'SA'},
  };

  // State untuk menyimpan lokasi terpilih dan hasil Future-nya
  String? _selectedLocationKey;
  Future<PrayerTimes>? _prayerTimesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default ke Jakarta saat pertama kali dibuka
    _selectedLocationKey = _locations.keys.first;
    _loadSelectedPrayerTimes(); // Langsung load data untuk Jakarta
  }

  // Fungsi untuk memanggil API Aladhan untuk satu lokasi
  Future<PrayerTimes> _fetchPrayerTimes(String city, String country) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final url =
        'http://api.aladhan.com/v1/timingsByCity/$today?city=$city&country=$country&method=8';

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return PrayerTimes.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal memuat jadwal ($city): ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error koneksi ($city): $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Memuat jadwal sholat HANYA untuk lokasi yang dipilih di dropdown
  void _loadSelectedPrayerTimes() {
    if (_selectedLocationKey != null) {
      final params = _locations[_selectedLocationKey!];
      if (params != null) {
        setState(() {
          _prayerTimesFuture =
              _fetchPrayerTimes(params['city']!, params['country']!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisikan warna oranye di sini atau ambil dari globals.dart
    final Color orangeColor = primary; // Ganti jika perlu

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text("Jadwal Sholat Global"),
        backgroundColor: background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Dropdown Pemilihan Kota ---
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: gray, // Warna background dropdown
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocationKey,
                  isExpanded: true,
                  dropdownColor: gray, // Warna menu dropdown
                  icon: Icon(Icons.arrow_drop_down, color: primary),
                  // Style untuk teks yang TAMPIL di button (yang terpilih)
                  style: GoogleFonts.poppins(
                      color: orangeColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  items: _locations.keys.map((String key) {
                    // --- Logika Warna Item Dropdown ---
                    final bool isSelected = key == _selectedLocationKey;
                    final Color itemColor = isSelected
                        ? orangeColor
                        : orange; // 'text' adalah warna abu dari globals

                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(
                        key,
                        // Style untuk teks DI DALAM DAFTAR dropdown
                        style: GoogleFonts.poppins(
                          color: itemColor, // Terapkan warna di sini
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    );
                    // --- Akhir Logika Warna ---
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLocationKey = newValue;
                        _prayerTimesFuture = null; // Reset future
                      });
                      _loadSelectedPrayerTimes(); // Panggil API untuk kota baru
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Tampilan Hasil Jadwal Sholat ---
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : (_prayerTimesFuture == null
                      ? Center(
                          child: CircularProgressIndicator(
                              color: primary)) // Loading awal
                      : FutureBuilder<PrayerTimes>(
                          future: _prayerTimesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !_isLoading) {
                              return Center(
                                  child: CircularProgressIndicator(
                                      color: primary));
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}',
                                      style: TextStyle(color: Colors.red)));
                            } else if (snapshot.hasData) {
                              final times = snapshot.data!;
                              return _buildPrayerTimeCard(
                                  _selectedLocationKey!, times);
                            } else {
                              return const Center(
                                  child: Text('Tidak ada data jadwal.',
                                      style: TextStyle(color: Colors.white)));
                            }
                          },
                        )),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan Card Jadwal Sholat
  Widget _buildPrayerTimeCard(String locationName, PrayerTimes times) {
    return Card(
      color: gray,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Agar card tidak memenuhi layar
          children: [
            Text(
              locationName,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              "${times.date} (${times.timezone})",
              style: GoogleFonts.poppins(fontSize: 12, color: text),
            ),
            const Divider(height: 20, color: Colors.white30),
            _buildTimeRow('Imsak', times.imsak),
            _buildTimeRow('Subuh', times.fajr),
            _buildTimeRow(
                'Syuruq', times.sunrise), // Sunrise ditampilkan sbg Syuruq
            _buildTimeRow('Dzuhur', times.dhuhr),
            _buildTimeRow('Ashar', times.asr),
            _buildTimeRow('Maghrib', times.maghrib),
            _buildTimeRow('Isya', times.isha),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk baris waktu sholat
  Widget _buildTimeRow(String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: primary),
          ),
        ],
      ),
    );
  }
}
