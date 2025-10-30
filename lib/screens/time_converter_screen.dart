import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_pam/globals.dart'; // Import globals untuk warna
import 'package:google_fonts/google_fonts.dart';

// --- Import untuk LBS ---
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// -----------------------

// Model PrayerTimes (dengan Imsak & Sunrise)
class PrayerTimes {
  final String imsak;
  final String fajr;
  final String sunrise; // Syuruq
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;
  final String timezone;

  PrayerTimes(
      {required this.imsak,
      required this.fajr,
      required this.sunrise,
      required this.dhuhr,
      required this.asr,
      required this.maghrib,
      required this.isha,
      required this.date,
      required this.timezone});

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'];
    final dateInfo = json['data']['date']['readable'];
    final timezone = json['data']['meta']['timezone'];
    String formatTime(String time) => time.split(' ')[0]; // Ambil HH:mm

    return PrayerTimes(
      imsak: formatTime(timings['Imsak']),
      fajr: formatTime(timings['Fajr']),
      sunrise: formatTime(timings['Sunrise']),
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
  // --- BARU: Kunci untuk LBS ---
  static const String _currentLocationKey = '📍 Lokasi Saat Ini';

  // Daftar lokasi (Map<String, Map<String, String>?>)
  // Value dibuat nullable (?) untuk handle 'Lokasi Saat Ini'
  final Map<String, Map<String, String>?> _locations = {
    _currentLocationKey: null, // Opsi pertama untuk LBS
    'Jakarta (WIB)': {'city': 'Jakarta', 'country': 'Indonesia'},
    'Makassar (WITA)': {'city': 'Makassar', 'country': 'Indonesia'},
    'Jayapura (WIT)': {'city': 'Jayapura', 'country': 'Indonesia'},
    'London (GMT/BST)': {'city': 'London', 'country': 'UK'},
    'Sydney (AEDT/AEST)': {'city': 'Sydney', 'country': 'Australia'},
    'Nagoya (JST)': {'city': 'Nagoya', 'country': 'Japan'},
  };

  // State
  String _selectedLocationKey = _currentLocationKey; // Default pilihan
  Future<PrayerTimes>? _prayerTimesFuture;
  String _currentDisplayLocationName = "Memuat lokasi..."; // Nama di card
  bool _isLoading = false; // Status loading umum

  @override
  void initState() {
    super.initState();
    // Langsung muat data untuk pilihan default ('Lokasi Saat Ini')
    _loadPrayerTimes();
  }

  // --- Fungsi Utama Pengambilan Data ---
  Future<void> _loadPrayerTimes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      // Set future ke null agar FutureBuilder menampilkan loading
      _prayerTimesFuture = null;
    });

    try {
      PrayerTimes times;
      if (_selectedLocationKey == _currentLocationKey) {
        // --- LOGIKA LBS (Lokasi Saat Ini) ---
        print("Memulai LBS: Mendapatkan lokasi saat ini...");
        // 1. Ambil izin dan posisi
        Position position = await _getPermissionAndPosition();

        // 2. (Opsional) Ubah koordinat jadi nama kota
        String cityName = "Lokasi Saat Ini";
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            // Ambil nama kota atau daerah
            cityName = placemarks.first.locality ??
                placemarks.first.subAdministrativeArea ??
                "Lokasi Terdeteksi";
          }
        } catch (geoError) {
          print("Gagal geocoding: $geoError. Menggunakan nama default.");
          cityName = "Lokasi Saat Ini"; // Fallback
        }

        // 3. Panggil API pakai koordinat
        times = await _fetchPrayerTimesByCoords(
            position.latitude, position.longitude);

        if (mounted) {
          setState(() {
            _currentDisplayLocationName = "$cityName (${times.timezone})";
            _prayerTimesFuture = Future.value(times); // Set future dengan hasil
          });
        }
      } else {
        // --- LOGIKA MANUAL (Dropdown Kota) ---
        print("Memulai Manual: Mengambil data untuk $_selectedLocationKey");
        final params = _locations[_selectedLocationKey];
        if (params != null) {
          times = await _fetchPrayerTimesByCity(
              params['city']!, params['country']!);
          if (mounted) {
            setState(() {
              _currentDisplayLocationName =
                  "$_selectedLocationKey (${times.timezone})";
              _prayerTimesFuture =
                  Future.value(times); // Set future dengan hasil
            });
          }
        } else {
          throw Exception("Parameter lokasi tidak ditemukan.");
        }
      }
    } catch (e) {
      // Tangani semua error (dari LBS atau API)
      print("Error di _loadPrayerTimes: $e");
      if (mounted) {
        setState(() {
          // Set future agar FutureBuilder menampilkan error
          _prayerTimesFuture =
              Future.error(e.toString().replaceAll("Exception: ", ""));
        });
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  // --- Fungsi API (Berdasarkan Kota) ---
  Future<PrayerTimes> _fetchPrayerTimesByCity(
      String city, String country) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final url =
        'http://api.aladhan.com/v1/timingsByCity/$today?city=$city&country=$country&method=8';
    print("Fetching by City: $url");

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return PrayerTimes.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat jadwal ($city)');
    }
  }

  // --- Fungsi API (Berdasarkan Koordinat LBS) ---
  Future<PrayerTimes> _fetchPrayerTimesByCoords(double lat, double lon) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final url =
        'http://api.aladhan.com/v1/timings/$today?latitude=$lat&longitude=$lon&method=8';
    print("Fetching by Coords: $url");

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return PrayerTimes.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat jadwal untuk lokasi Anda');
    }
  }

  // --- Fungsi LBS (Minta Izin & Ambil Posisi) ---
  Future<Position> _getPermissionAndPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi dimatikan. Harap aktifkan GPS.');
    }

    // 2. Cek izin
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 3. Minta izin jika ditolak
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 4. Handle jika izin ditolak permanen
      throw Exception(
          'Izin lokasi ditolak permanen. Harap aktifkan manual di pengaturan.');
    }

    // 5. Jika izin diberikan, ambil lokasi
    print("Izin lokasi diberikan. Mengambil posisi...");
    return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.medium // Cukup medium untuk hemat baterai
        );
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan warna oranye
    final Color orangeColor = orange; // Ambil dari globals.dart
    final Color defaultColor = text; // Warna abu dari globals.dart

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          "Jadwal Sholat Global",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
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
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: gray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocationKey,
                  isExpanded: true,
                  dropdownColor: gray,
                  icon: Icon(Icons.arrow_drop_down,
                      color: _selectedLocationKey == _currentLocationKey
                          ? primary // Warna ikon ungu jika LBS
                          : defaultColor), // Warna ikon abu jika manual
                  // Style teks yang terpilih (yang tampil di button)
                  style: GoogleFonts.poppins(
                      color: _selectedLocationKey == _currentLocationKey
                          ? orangeColor // Oranye jika LBS
                          : Colors.white, // Putih jika manual
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  items: _locations.keys.map((String key) {
                    final bool isSelected = key == _selectedLocationKey;
                    // final bool isLBS = key == _currentLocationKey;

                    Color itemColor = isSelected
                        ? orangeColor
                        : defaultColor; // Oranye jika terpilih, abu jika tidak

                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(
                        key,
                        style: GoogleFonts.poppins(
                            color: itemColor,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != _selectedLocationKey) {
                      setState(() {
                        _selectedLocationKey = newValue;
                        _currentDisplayLocationName =
                            "Memuat..."; // Set nama sementara
                      });
                      _loadPrayerTimes(); // Panggil ulang API untuk lokasi baru
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Tampilan Hasil Jadwal Sholat ---
            Expanded(
              child: FutureBuilder<PrayerTimes>(
                future: _prayerTimesFuture,
                builder: (context, snapshot) {
                  // Tampilkan loading jika _isLoading true (saat ganti dropdown)
                  // atau saat future sedang menunggu (load awal)
                  if (_isLoading ||
                      snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(color: primary));
                  }

                  // Tampilkan error
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: Colors.red[300], fontSize: 16),
                        ),
                      ),
                    );
                  }

                  // Tampilkan data jika berhasil
                  if (snapshot.hasData) {
                    final times = snapshot.data!;
                    return _buildPrayerTimeCard(
                        _currentDisplayLocationName, times);
                  }

                  // Fallback jika state tidak terduga
                  return Center(
                      child: Text("Silakan pilih lokasi.",
                          style: GoogleFonts.poppins(color: text)));
                },
              ),
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
      elevation: 0, // Desain flat
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Padding lebih besar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locationName, // Tampilkan nama lokasi dinamis
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              times.date, // Tampilkan tanggal
              style: GoogleFonts.poppins(fontSize: 12, color: text),
            ),
            const Divider(height: 24, color: Colors.white30),
            _buildTimeRow('Imsak', times.imsak),
            _buildTimeRow('Subuh', times.fajr),
            _buildTimeRow('Syuruq', times.sunrise), // Sunrise -> Syuruq
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
