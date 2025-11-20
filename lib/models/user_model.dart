class User {
  final int? id;
  final String namaLengkap;
  final String nim;
  final String kelas;
  final String email;
  final String password;

  final String? profileImagePath;

  User({
    this.id,
    required this.namaLengkap,
    required this.nim,
    required this.kelas,
    required this.email,
    required this.password,
    this.profileImagePath,
  });

  factory User.fromDbMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      namaLengkap: map['namaLengkap'],
      nim: map['nim'],
      kelas: map['kelas'],
      email: map['email'],
      password: '',
      profileImagePath: map['profileImagePath'],
    );
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'namaLengkap': namaLengkap,
      'nim': nim,
      'kelas': kelas,
      'email': email,
      'profileImagePath': profileImagePath,
    };
  }

  User copyWith({
    int? id,
    String? namaLengkap,
    String? nim,
    String? kelas,
    String? email,
    String? password,
    String? profileImagePath,
  }) {
    return User(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      nim: nim ?? this.nim,
      kelas: kelas ?? this.kelas,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
