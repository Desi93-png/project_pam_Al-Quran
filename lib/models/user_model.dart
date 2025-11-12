// Salin dan timpa seluruh file models/user_model.dart

class User {
  final int? id;
  final String namaLengkap;
  final String nim;
  final String kelas;
  final String email;
  final String password; // Ini akan diisi '' oleh fromDbMap, JANGAN DISIMPAN KEMBALI

  // --- BARU: Tambahkan field ini ---
  final String? profileImagePath; // Path untuk foto profil

  User({
    this.id,
    required this.namaLengkap,
    required this.nim,
    required this.kelas,
    required this.email,
    required this.password,
    this.profileImagePath, // Tambahkan di constructor
  });

  // Factory constructor dari DB (sesuai kodemu)
  // --- DIUBAH: Ditambahkan 'profileImagePath' ---
  factory User.fromDbMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      namaLengkap: map['namaLengkap'],
      nim: map['nim'],
      kelas: map['kelas'],
      email: map['email'],
      password: '', // Password asli tidak disimpan/dikirim ke state
      profileImagePath: map['profileImagePath'], // Ambil path foto
    );
  }

  // --- BARU: Fungsi toMap (untuk UPDATE ke DB) ---
  // Perhatikan: Kita HANYA memasukkan data yang ingin kita update.
  // Kita tidak memasukkan password, karena password di state kita adalah ''
  // Kita juga tidak memasukkan ID
  Map<String, dynamic> toMapForUpdate() {
    return {
      'namaLengkap': namaLengkap,
      'nim': nim,
      'kelas': kelas,
      'email': email, // Kita update username juga (walau tidak diedit)
      'profileImagePath': profileImagePath,
    };
  }

  // --- BARU: Buat fungsi 'copyWith' ---
  // Ini SANGAT PENTING untuk update data
  User copyWith({
    int? id,
    String? namaLengkap,
    String? nim,
    String? kelas,
    String? email,
    String? password, // biarkan ini, tapi jangan dipakai di toMap
    String? profileImagePath,
  }) {
    return User(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      nim: nim ?? this.nim,
      kelas: kelas ?? this.kelas,
      email: email ?? this.email,
      password: password ?? this.password, // Akan tetap ''
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}