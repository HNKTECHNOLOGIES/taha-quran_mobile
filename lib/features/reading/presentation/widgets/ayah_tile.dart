import 'package:flutter/material.dart';

import '../../../surahs/domain/entities/ayah.dart';
import 'mushaf_page.dart';

/// Conservé pour compatibilité : délègue au rendu Mushaf d'un seul verset.
class AyahTile extends StatelessWidget {
  const AyahTile({
    super.key,
    required this.ayah,
    this.arabicFontSize = 28,
  });

  final Ayah ayah;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) {
    return MushafPage(
      ayahs: [ayah],
      arabicFontSize: arabicFontSize,
    );
  }
}
