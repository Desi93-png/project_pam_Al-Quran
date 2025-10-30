// Salin dan timpa seluruh file: lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math'; // <-- BARU: Import untuk fungsi acak (Random)

// --- BARU: Model Sederhana untuk Ayat Pilihan ---
class AyatPilihan {
  final String surah;
  final int ayatKe;
  final String teks; // Teks terjemahan

  AyatPilihan({required this.surah, required this.ayatKe, required this.teks});
}
// ---------------------------------------------

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Detail channel notifikasi (Tidak berubah)
  static const String _channelId = 'daily_reminder_channel_id';
  static const String _channelName = 'Pengingat Harian Quran';
  static const String _channelDesc =
      'Notifikasi harian pengingat membaca Al-Quran';

  static const NotificationDetails _platformChannelSpecifics =
      NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher', // Pastikan ikon ini ada
            // --- BARU: Style agar teks notifikasi bisa panjang ---
            styleInformation: BigTextStyleInformation(''),
            // --------------------------------------------------
          ),
          iOS: DarwinNotificationDetails());

  // --- BARU: Daftar Ayat Pilihan (Silakan Tambah/Ubah Sesuai Keinginan) ---
  final List<AyatPilihan> _ayatPilihanList = [
    AyatPilihan(
        surah: "Al-Baqarah",
        ayatKe: 255,
        teks:
            "Allah, tidak ada tuhan selain Dia. Yang Maha Hidup, Yang terus menerus mengurus (makhluk-Nya)... (Ayat Kursi)"),
    AyatPilihan(
        surah: "Al-Ikhlas",
        ayatKe: 1,
        teks: "Katakanlah (Muhammad), Dialah Allah, Yang Maha Esa."),
    AyatPilihan(
        surah: "Ar-Rahman",
        ayatKe: 13,
        teks: "Maka nikmat Tuhanmu manakah yang kamu dustakan?"),
    AyatPilihan(
        surah: "Al-Asr",
        ayatKe: 2 - 3,
        teks:
            "Sungguh, manusia berada dalam kerugian, kecuali orang-orang yang beriman dan mengerjakan kebajikan serta saling menasihati untuk kebenaran dan kesabaran."),
    AyatPilihan(
        surah: "Al-Insyirah",
        ayatKe: 5,
        teks: "Maka sesungguhnya beserta kesulitan ada kemudahan."),
    AyatPilihan(
        surah: "Al-Insyirah",
        ayatKe: 6,
        teks: "Sesungguhnya beserta kesulitan itu ada kemudahan."),
    AyatPilihan(
        surah: "Ali 'Imran",
        ayatKe: 139,
        teks:
            "Dan janganlah kamu (merasa) lemah, dan jangan (pula) bersedih hati, sebab kamu paling tinggi (derajatnya), jika kamu orang beriman."),
    AyatPilihan(
        surah: "Al-Fatihah",
        ayatKe: 5,
        teks:
            "Hanya kepada Engkaulah kami menyembah dan hanya kepada Engkaulah kami mohon pertolongan."),
    AyatPilihan(
        surah: "At-Talaq",
        ayatKe: 3,
        teks:
            "Barangsiapa bertakwa kepada Allah niscaya Dia akan membukakan jalan keluar baginya, dan Dia memberinya rezeki dari arah yang tidak disangka-sangkanya."),
    AyatPilihan(
        surah: "Al-Baqarah",
        ayatKe: 286,
        teks:
            "Allah tidak membebani seseorang melainkan sesuai dengan kesanggupannya..."),
    AyatPilihan(
        surah: "Az-Zumar",
        ayatKe: 53,
        teks:
            "Wahai hamba-hamba-Ku yang melampaui batas terhadap diri mereka sendiri! Janganlah kamu berputus asa dari rahmat Allah."),
  ];
  // ---------------------------------------------------------------------

  // Fungsi initNotification (Tidak berubah)
  Future<void> initNotification() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // Default

    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true, /*...*/
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initSettingsAndroid, iOS: initSettingsIOS);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  // Handler onDidReceiveNotificationResponse (Tidak berubah)
  Future<void> onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    debugPrint('NOTIFICATION PAYLOAD: ${notificationResponse.payload}');
  }

  // --- FUNGSI 1: Penjadwalan Harian (DIUBAH) ---
  Future<void> scheduleDailyReminderNotification() async {
    print("Mencoba menjadwalkan 'Ayat Harian'...");

    // --- BARU: Pilih Ayat Acak ---
    final random = Random();
    final AyatPilihan ayat =
        _ayatPilihanList[random.nextInt(_ayatPilihanList.length)];
    // ----------------------------

    final String notifTitle =
        "📖 Ayat Hari Ini (${ayat.surah} : ${ayat.ayatKe})";
    final String notifBody = ayat.teks; // Tampilkan terjemahan ayat

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 8); // Jam 8:00 Pagi
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // ID 0 untuk notifikasi harian
        notifTitle, // --- DIUBAH ---
        notifBody, // --- DIUBAH ---
        scheduledDate,
        _platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
    print(
        "Notifikasi Ayat Harian ($notifTitle) berhasil dijadwalkan untuk $scheduledDate");
  }

  // --- FUNGSI 2: Tombol Demo (DIUBAH) ---
  Future<void> showNowReminderNotification() async {
    print("Menampilkan notifikasi demo 'Ayat Harian'...");

    // --- BARU: Pilih Ayat Acak ---
    final random = Random();
    final AyatPilihan ayat =
        _ayatPilihanList[random.nextInt(_ayatPilihanList.length)];
    // ----------------------------

    final String notifTitle =
        "📖 Ayat Hari Ini (${ayat.surah} : ${ayat.ayatKe})";
    final String notifBody = ayat.teks;

    await flutterLocalNotificationsPlugin.show(
        1, // ID 1 untuk notifikasi instan
        notifTitle, // --- DIUBAH ---
        notifBody, // --- DIUBAH ---
        _platformChannelSpecifics,
        payload: 'ayat_harian_demo_payload');
    print("Notifikasi instan '$notifTitle' berhasil ditampilkan.");
  }
}
