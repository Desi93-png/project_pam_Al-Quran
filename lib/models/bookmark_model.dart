class Bookmark {
  final int? id;
  final int userId;
  final int surahNomor;
  final int ayatNomor;

  Bookmark({
    this.id,
    required this.userId,
    required this.surahNomor,
    required this.ayatNomor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'surah_nomor': surahNomor,
      'ayat_nomor': ayatNomor,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'],
      userId: map['user_id'],
      surahNomor: map['surah_nomor'],
      ayatNomor: map['ayat_nomor'],
    );
  }
}
