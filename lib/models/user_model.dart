class User {
  final int? id; // Nullable karena ID baru ada setelah disimpan di DB
  final String namaLengkap;
  final String nim;
  final String kelas;
  final String username;
  final String password; // Hanya digunakan saat registrasi, TIDAK DISIMPAN
  // Tambahkan path foto jika perlu
  // final String? fotoPath; 

  User({
    this.id,
    required this.namaLengkap,
    required this.nim,
    required this.kelas,
    required this.username,
    required this.password, // Dibutuhkan saat membuat objek User baru
    // this.fotoPath,
  });

  // Factory constructor untuk membuat User dari Map database (TANPA password asli)
  factory User.fromDbMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      namaLengkap: map['namaLengkap'],
      nim: map['nim'],
      kelas: map['kelas'],
      username: map['username'],
      password: '', // Password asli tidak disimpan/dikirim
      // fotoPath: map['fotoPath'],
    );
  }
}
