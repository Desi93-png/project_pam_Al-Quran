import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_pam/globals.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PrayerTimes {
  final String imsak;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String timezone;

  PrayerTimes(
      {required this.imsak,
      required this.fajr,
      required this.sunrise,
      required this.dhuhr,
      required this.asr,
      required this.maghrib,
      required this.isha,
      required this.timezone});

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'];
    final timezone = json['data']['meta']['timezone'];
    String formatTime(String time) => time.split(' ')[0];

    return PrayerTimes(
      imsak: formatTime(timings['Imsak']),
      fajr: formatTime(timings['Fajr']),
      sunrise: formatTime(timings['Sunrise']),
      dhuhr: formatTime(timings['Dhuhr']),
      asr: formatTime(timings['Asr']),
      maghrib: formatTime(timings['Maghrib']),
      isha: formatTime(timings['Isha']),
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
  static const String _currentLocationKey = '📍 Lokasi Saat Ini';
  static const String _searchedLocationKey = '🔍 Lokasi Pencarian';
  Timer? _debounce;

  DateTime _selectedDate = DateTime.now();
  double? _lastSearchedLat;
  double? _lastSearchedLon;
  String? _lastSearchedName;

  String _selectedLocationKey = _currentLocationKey;
  Future<PrayerTimes>? _prayerTimesFuture;
  String _currentDisplayLocationName = "Memuat lokasi...";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _prayerTimesFuture = null;
      _selectedLocationKey = _currentLocationKey;
      _lastSearchedLat = null;
      _lastSearchedLon = null;
      _lastSearchedName = null;
    });

    try {
      PrayerTimes times;
      print("Memulai LBS: Mendapatkan lokasi saat ini...");
      Position position = await _getPermissionAndPosition();

      String cityName = "Lokasi Saat Ini";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          cityName = placemarks.first.locality ??
              placemarks.first.subAdministrativeArea ??
              "Lokasi Terdeteksi";
        }
      } catch (geoError) {
        print("Gagal geocoding: $geoError. Menggunakan nama default.");
        cityName = "Lokasi Saat Ini";
      }

      times = await _fetchPrayerTimesByCoords(
          position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          final String ianaZone = times.timezone;
          final String indoAbbr = _getIndonesianTimezoneAbbreviation(ianaZone);
          final String displayZone =
              indoAbbr.isNotEmpty ? "$ianaZone / $indoAbbr" : ianaZone;

          _currentDisplayLocationName = "$cityName ($displayZone)";
          _prayerTimesFuture = Future.value(times);
        });
      }
    } catch (e) {
      print("Error di _loadPrayerTimes: $e");
      if (mounted) {
        setState(() {
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

  Future<PrayerTimes> _fetchPrayerTimesByCoords(double lat, double lon) async {
    final String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final url =
        'http://api.aladhan.com/v1/timings/$dateString?latitude=$lat&longitude=$lon&method=20';
    print("Fetching by Coords: $url");

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return PrayerTimes.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat jadwal untuk lokasi Anda');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCitySuggestions(
      TextEditingValue textEditingValue) async {
    if (textEditingValue.text.isEmpty || textEditingValue.text.length < 3) {
      return const [];
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final completer = Completer<List<Map<String, dynamic>>>();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final query = Uri.encodeComponent(textEditingValue.text);
        final url =
            'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1';
        print("Fetching suggestions: $url");
        final response = await http.get(Uri.parse(url),
            headers: {'User-Agent': 'FlutterPrayTimeApp/1.0'});
        if (response.statusCode == 200) {
          final List<dynamic> results = jsonDecode(response.body);
          final suggestions = results.map((item) {
            String displayName = item['display_name'];
            final address = item['address'];
            if (address != null) {
              String name = address['name'] ??
                  address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  '';
              String country = address['country'] ?? '';
              if (name.isNotEmpty && country.isNotEmpty) {
                displayName = "$name, $country";
              }
            }
            return {
              'display_name': displayName,
              'lat': item['lat'],
              'lon': item['lon'],
            };
          }).toList();
          completer.complete(suggestions);
        } else {
          print("Error fetching suggestions: ${response.body}");
          completer.complete(const []);
        }
      } catch (e) {
        print("Exception fetching suggestions: $e");
        completer.complete(const []);
      }
    });
    return completer.future;
  }

  Future<Position> _getPermissionAndPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi dimatikan. Harap aktifkan GPS.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Izin lokasi ditolak permanen. Harap aktifkan manual di pengaturan.');
    }
    print("Izin lokasi diberikan. Mengambil posisi...");
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium);
  }

  String _getIndonesianTimezoneAbbreviation(String ianaTimezone) {
    switch (ianaTimezone) {
      case 'Asia/Jakarta':
      case 'Asia/Pontianak':
      case 'Asia/Bangka':
      case 'Asia/Bintan':
      case 'Asia/Palembang':
        return 'WIB';
      case 'Asia/Makassar':
      case 'Asia/Balikpapan':
      case 'Asia/Banjarmasin':
      case 'Asia/Kupang':
        return 'WITA';
      case 'Asia/Jayapura':
      case 'Asia/Ambon':
      case 'Asia/Manokwari':
        return 'WIT';
      default:
        return '';
    }
  }

  Future<void> _showDatePicker() async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primary,
              onPrimary: Colors.white,
              surface: background,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: gray,
          ),
          child: child!,
        );
      },
    );

    if (newDate != null && newDate != _selectedDate) {
      setState(() {
        _selectedDate = newDate;
      });

      if (_selectedLocationKey == _currentLocationKey) {
        _loadPrayerTimes();
      } else if (_selectedLocationKey == _searchedLocationKey &&
          _lastSearchedLat != null) {
        _loadTimesFromSearch(
            _lastSearchedLat!, _lastSearchedLon!, _lastSearchedName!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color orangeColor = orange;
    final Color defaultColor = text;

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
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (option) => option['display_name'],
              optionsBuilder: _fetchCitySuggestions,
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    color: gray,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                option['display_name'],
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (Map<String, dynamic> selection) {
                print("Selected: ${selection['display_name']}");
                FocusScope.of(context).unfocus();
                try {
                  final lat = double.parse(selection['lat']);
                  final lon = double.parse(selection['lon']);
                  final displayName = selection['display_name'];

                  _lastSearchedLat = lat;
                  _lastSearchedLon = lon;
                  _lastSearchedName = displayName;

                  _loadTimesFromSearch(lat, lon, displayName);
                } catch (e) {
                  print("Error parsing lat/lon: $e");
                  setState(() {
                    _prayerTimesFuture =
                        Future.error("Format lokasi tidak valid.");
                  });
                }
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: "Cari kota",
                    hintStyle: GoogleFonts.poppins(
                        color: defaultColor,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: gray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                    prefixIcon: Icon(
                      Icons.location_pin,
                      color: orangeColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: defaultColor),
                      onPressed: () {
                        if (_selectedLocationKey != _currentLocationKey) {
                          print("Kembali ke Lokasi Saat Ini (LBS)");
                          controller.clear();
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _selectedDate = DateTime.now();
                          });
                          _loadPrayerTimes();
                        } else {
                          controller.clear();
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<PrayerTimes>(
                future: _prayerTimesFuture,
                builder: (context, snapshot) {
                  if (_isLoading ||
                      snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(color: primary));
                  }

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

                  if (snapshot.hasData) {
                    final times = snapshot.data!;
                    return SingleChildScrollView(
                      child: _buildPrayerTimeCard(
                          _currentDisplayLocationName, times, _selectedDate),
                    );
                  }

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

  Future<void> _loadTimesFromSearch(
      double lat, double lon, String displayName) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _prayerTimesFuture = null;
      _selectedLocationKey = _searchedLocationKey;
    });

    try {
      final times = await _fetchPrayerTimesByCoords(lat, lon);

      if (mounted) {
        setState(() {
          final String ianaZone = times.timezone;
          final String indoAbbr = _getIndonesianTimezoneAbbreviation(ianaZone);
          final String displayZone =
              indoAbbr.isNotEmpty ? "$ianaZone / $indoAbbr" : ianaZone;

          _currentDisplayLocationName = "$displayName ($displayZone)";
          _prayerTimesFuture = Future.value(times);
        });
      }
    } catch (e) {
      print("Error di _loadTimesFromSearch: $e");
      if (mounted) {
        setState(() {
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

  Widget _buildPrayerTimeCard(
      String locationName, PrayerTimes times, DateTime displayDate) {
    final String formattedDate = DateFormat('dd MMM yyyy').format(displayDate);

    final Color defaultColor = text;
    final Color primaryColor = primary;

    return Card(
      color: gray,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locationName,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(fontSize: 12, color: defaultColor),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: primaryColor),
                  iconSize: 20.0,
                  onPressed: _showDatePicker,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white30),
            _buildTimeRow('Imsak', times.imsak),
            _buildTimeRow('Subuh', times.fajr),
            _buildTimeRow('Syuruq', times.sunrise),
            _buildTimeRow('Dzuhur', times.dhuhr),
            _buildTimeRow('Ashar', times.asr),
            _buildTimeRow('Maghrib', times.maghrib),
            _buildTimeRow('Isya', times.isha),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String name, String time) {
    final Color primaryColor = primary;

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
                fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
