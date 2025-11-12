import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pam/globals.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final formatter = NumberFormat.decimalPattern('id');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanText.isEmpty) {
      return TextEditingValue.empty;
    }

    double value = double.parse(cleanText);
    String formattedText = formatter.format(value);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class KalkulatorZakatPage extends StatefulWidget {
  const KalkulatorZakatPage({Key? key}) : super(key: key);

  @override
  _KalkulatorZakatPageState createState() => _KalkulatorZakatPageState();
}

class _KalkulatorZakatPageState extends State<KalkulatorZakatPage> {
  // --- VARIABEL STATE ---
  final String _metalApiKey = "6f7f87826ae9ba492adcc6c885f1f831";
  final String _exchangeRateApiKey = "01573e01cd3549ecbc6f6651";

  final TextEditingController _wealthController = TextEditingController();
  bool _isLoading = false;
  double _nisabInIDR = 0.0;
  double _zakatInIDR = 0.0;
  double _zakatInUSD = 0.0;
  double _zakatInSAR = 0.0;

  // --- PERUBAHAN 1: Mengosongkan status message awal ---
  String _statusMessage = "";

  final formatIDR =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final formatUSD =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
  final formatSAR =
      NumberFormat.currency(locale: 'en_SA', symbol: 'SAR ', decimalDigits: 2);

  // --- FUNGSI API (Tidak Berubah) ---
  Future<double> _fetchGoldPricePerOunce() async {
    String url =
        "https://api.metalpriceapi.com/v1/latest?api_key=$_metalApiKey&base=USD&currencies=XAU";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double pricePerOunce = 1 / (data['rates']['XAU'] as double);
      return pricePerOunce;
    } else {
      throw Exception('Gagal memuat harga emas');
    }
  }

  Future<Map<String, dynamic>> _fetchCurrencyRates() async {
    String url =
        "https://v6.exchangerate-api.com/v6/$_exchangeRateApiKey/latest/USD";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double idrRate = data['conversion_rates']['IDR'];
      double sarRate = data['conversion_rates']['SAR'];
      return {'IDR': idrRate, 'SAR': sarRate};
    } else {
      throw Exception('Gagal memuat kurs mata uang');
    }
  }

  // --- FUNGSI KALKULASI ---
  void _calculateZakat() async {
    // --- PERUBAHAN 2: Menambahkan validasi input kosong ---
    if (_wealthController.text.isEmpty) {
      setState(() {
        _statusMessage = "Mohon masukkan total kekayaan Anda.";
        _nisabInIDR = 0; // Sembunyikan card hasil jika input kosong
        _zakatInIDR = 0;
      });
      return; // Hentikan eksekusi fungsi
    }
    // --- Akhir Perubahan 2 ---

    setState(() {
      _isLoading = true;
      _statusMessage = "Mengambil data kurs terbaru...";
      _nisabInIDR = 0;
      _zakatInIDR = 0;
    });

    try {
      final List<dynamic> results =
          await Future.wait([_fetchGoldPricePerOunce(), _fetchCurrencyRates()]);

      final double goldPricePerOunce = results[0] as double;
      final Map<String, dynamic> rates = results[1] as Map<String, dynamic>;

      double usdToIDRRate = rates['IDR'] as double;
      double usdToSARRate = rates['SAR'] as double;

      double goldPricePerGramUSD = goldPricePerOunce / 31.1035;
      double nisabInUSD = 85 * goldPricePerGramUSD;
      double nisabInIDR = nisabInUSD * usdToIDRRate;

      String cleanWealthText = _wealthController.text.replaceAll('.', '');
      double userWealthIDR = double.tryParse(cleanWealthText) ?? 0;

      if (userWealthIDR >= nisabInIDR) {
        double zakatInIDR = userWealthIDR * 0.025;
        double zakatInUSD = zakatInIDR / usdToIDRRate;
        double zakatInSAR = zakatInUSD * usdToSARRate;

        setState(() {
          _statusMessage =
              "Kalkulasi Zakat Berhasil (Kekayaan Anda di atas Nisab)";
          _nisabInIDR = nisabInIDR;
          _zakatInIDR = zakatInIDR;
          _zakatInUSD = zakatInUSD;
          _zakatInSAR = zakatInSAR;
        });
      } else {
        setState(() {
          _statusMessage =
              "Kekayaan Anda belum mencapai Nisab. Belum wajib Zakat Maal.";
          _nisabInIDR = nisabInIDR;
          _zakatInIDR = 0;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: Terjadi kesalahan saat mengambil data.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          "Kalkulator Zakat Maal",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Hitung Zakat Maal Anda",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // --- PERUBAHAN 3: Memindahkan _statusMessage ---
            // Text(_statusMessage) dihapus dari sini

            const SizedBox(height: 24),
            TextField(
              controller: _wealthController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: "Total Kekayaan Anda (IDR)",
                labelStyle: GoogleFonts.poppins(color: text),
                prefixText: "Rp ",
                prefixStyle: GoogleFonts.poppins(color: text, fontSize: 16),
                filled: true,
                fillColor: gray,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: gray,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _calculateZakat,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text("Hitung Zakat"),
            ),
            const SizedBox(height: 24),

            // --- PERUBAHAN 3: _statusMessage dipindahkan ke sini ---
            // Hanya tampilkan widget Text jika _statusMessage tidak kosong
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0), // Ganti SizedBox
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center, // Agar teks rata tengah
                  style: GoogleFonts.poppins(
                    color: text, // Warna teks abu-abu
                    fontSize: 14,
                  ),
                ),
              ),
            // --- Akhir Perubahan 3 ---

            // Card Hasil (Hanya tampil jika Nisab sudah dihitung)
            if (_nisabInIDR > 0)
              Container(
                decoration: BoxDecoration(
                  color: gray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hasil Perhitungan:",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(
                        height: 24,
                        color: text.withOpacity(0.2),
                      ),
                      _buildResultRow(
                          "Nisab (85gr Emas):", formatIDR.format(_nisabInIDR)),

                      // Tampilkan detail zakat hanya jika wajib (zakatInIDR > 0)
                      if (_zakatInIDR > 0) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Total Zakat Anda (2.5%):",
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildResultRow(
                            "Dalam Rupiah:", formatIDR.format(_zakatInIDR)),
                        _buildResultRow(
                            "Dalam Dolar AS:", formatUSD.format(_zakatInUSD)),
                        _buildResultRow("Dalam Riyal Saudi:",
                            formatSAR.format(_zakatInSAR)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- INI PERBAIKANNYA ---
          Flexible(
            // 1. Bungkus Text dengan Flexible
            child: Text(
              title,
              style: GoogleFonts.poppins(color: text, fontSize: 16),
            ),
          ),
          // --- BATAS PERBAIKAN ---

          const SizedBox(width: 16), // 2. Beri jarak aman

          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wealthController.dispose();
    super.dispose();
  }
}
