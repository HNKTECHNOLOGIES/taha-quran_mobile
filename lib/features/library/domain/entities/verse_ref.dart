/// Référence d'un verset (sans copie du texte coranique).
class VerseRef {
  const VerseRef({required this.surahId, required this.ayahNumber});

  final int surahId;
  final int ayahNumber;

  String get key => '$surahId:$ayahNumber';

  factory VerseRef.fromKey(String key) {
    final parts = key.split(':');
    return VerseRef(
      surahId: int.parse(parts[0]),
      ayahNumber: int.parse(parts[1]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VerseRef &&
      other.surahId == surahId &&
      other.ayahNumber == ayahNumber;

  @override
  int get hashCode => Object.hash(surahId, ayahNumber);
}

class FavoriteEntry {
  const FavoriteEntry({
    required this.ref,
    required this.createdAtMs,
  });

  final VerseRef ref;
  final int createdAtMs;
}

class BookmarkEntry {
  const BookmarkEntry({
    required this.id,
    required this.ref,
    required this.createdAtMs,
    this.label,
  });

  final String id;
  final VerseRef ref;
  final int createdAtMs;
  final String? label;
}

class ReadingPosition {
  const ReadingPosition({
    required this.ref,
    required this.updatedAtMs,
  });

  final VerseRef ref;
  final int updatedAtMs;
}
