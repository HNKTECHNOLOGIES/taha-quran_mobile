import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../surahs/domain/entities/ayah.dart';
import 'verse_marker.dart';

/// Une page de Mushaf : texte arabe justifié avec marqueurs inline.
class MushafPage extends StatelessWidget {
  const MushafPage({
    super.key,
    required this.ayahs,
    this.showBasmala = false,
    this.arabicFontSize = 27,
  });

  final List<Ayah> ayahs;
  final bool showBasmala;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: arabicFontSize,
      height: 2.05,
      color: AppColors.ink,
      wordSpacing: 2,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showBasmala) ...[
              Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: baseStyle.copyWith(
                  fontSize: arabicFontSize + 2,
                  color: AppColors.emeraldDark,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text.rich(
              TextSpan(children: _buildSpans(baseStyle)),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildSpans(TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    for (final ayah in ayahs) {
      spans.add(TextSpan(text: ayah.textAr, style: baseStyle));
      spans.add(const TextSpan(text: ' '));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: VerseMarker(
            number: ayah.number,
            size: arabicFontSize * 0.95,
          ),
        ),
      );
      spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }
}

/// Découpe les versets en pages approximatives (style Mushaf).
List<List<Ayah>> paginateAyahs(
  List<Ayah> ayahs, {
  int charsPerPage = 360,
}) {
  if (ayahs.isEmpty) return const [];

  final pages = <List<Ayah>>[];
  var current = <Ayah>[];
  var count = 0;

  for (final ayah in ayahs) {
    final len = ayah.textAr.length + 4;
    if (current.isNotEmpty && count + len > charsPerPage) {
      pages.add(current);
      current = <Ayah>[];
      count = 0;
    }
    current.add(ayah);
    count += len;
  }
  if (current.isNotEmpty) pages.add(current);
  return pages;
}
