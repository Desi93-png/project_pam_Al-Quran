import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- TAMBAHKAN IMPORT INI
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// ================================================================
// --- CLASS FORMATTER BARU (LANGKAH 1) ---
// ================================================================
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
// ================================================================

class KalkulatorZakatPage extends StatefulWidget {
  const KalkulatorZakatPage({Key? key}) : super(key: key);

  @override
  _KalkulatorZakatPageState createState() => _KalkulatorZakatPageState();
}

class _KalkulatorZakatPageState extends State<KalkulatorZakatPage> {
  // ... (semua variabel Anda tetap sama)
  final String _metalApiKey = "6f7f87826ae9ba492adcc6c885f1f831";
  final String _exchangeRateApiKey = "01573e01cd3549ecbc6f6651";

  final TextEditingController _wealthController = TextEditingController();
  bool _isLoading = false;
  double _nisabInIDR = 0.0;
  double _zakatInIDR = 0.0;
  double _zakatInUSD = 0.0;
  double _zakatInSAR = 0.0;
  String _statusMessage =
      "Silakan masukkan total kekayaan Anda (tabungan, emas, dll) dalam IDR.";

  final formatIDR =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final formatUSD =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
  final formatSAR =
      NumberFormat.currency(locale: 'en_SA', symbol: 'SAR ', decimalDigits: 2);

  // ... (Fungsi _fetchGoldPricePerOunce dan _fetchCurrencyRates tetap sama)
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

  void _calculateZakat() async {
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

      // ================================================================
      // --- PERUBAHAN DI SINI (LANGKAH 2) ---
      // ================================================================
      // Teks dari controller akan berupa "200.000.000"
      // Kita harus hapus titik-titiknya sebelum di-parse
      String cleanWealthText = _wealthController.text.replaceAll('.', '');
      double userWealthIDR = double.tryParse(cleanWealthText) ?? 0;
      // ================================================================

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
        // ... (sisanya sama)
        setState(() {
          _statusMessage =
              "Kekayaan Anda belum mencapai Nisab. Belum wajib Zakat Maal.";
          _nisabInIDR = nisabInIDR;
          _zakatInIDR = 0;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (kode build Anda yang lain)
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color scaffoldBackgroundColor =
        Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text("Kalkulator Zakat Maal"),
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Hitung Zakat Maal Anda",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Text(_statusMessage),
            SizedBox(height: 20),

            // ================================================================
            // --- PERUBAHAN DI SINI (LANGKAH 2) ---
            // ================================================================
            TextField(
              controller: _wealthController,
              keyboardType: TextInputType.number,
              // Tambahkan dua baris ini:
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Hanya izinkan angka
                CurrencyInputFormatter(), // Terapkan formatter kita
              ],
              decoration: InputDecoration(
                labelText: "Total Kekayaan Anda (dalam IDR)",
                // Hapus "Rp " dari sini agar tidak bentrok dengan formatter
                // labelText: "Total Kekayaan Anda (dalam IDR)",
                // prefixText: "Rp ", // Hapus ini
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Tambahkan prefix "Rp " di sini agar lebih rapi
              style: TextStyle(fontSize: 16), // Sesuaikan style
            ),
            // ================================================================

            SizedBox(height: 24),
            // Tombol Hitung
            ElevatedButton(
              onPressed: _isLoading ? null : _calculateZakat,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Hitung Zakat"), // <-- Teks ini akan muncul
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // Warna background tombol (Ungu)

                // --- TAMBAHKAN BARIS INI ---
                foregroundColor: Colors.white, // Warna Teks (Putih)
                // --------------------------

                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 24),

            // ... (Tampilan Hasil tetap sama)
            if (_nisabInIDR > 0)
              Card(
                // ...
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hasil Perhitungan:",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Divider(height: 20),
                      _buildResultRow(
                          "Nisab (85gr Emas):", formatIDR.format(_nisabInIDR)),
                      if (_zakatInIDR > 0) ...[
                        SizedBox(height: 16),
                        Text(
                          "Total Zakat Anda (2.5%):",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
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

  // ... (Widget _buildResultRow tetap sama)
  Widget _buildResultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16)),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
