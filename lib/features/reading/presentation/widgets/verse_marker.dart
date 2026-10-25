import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numerals.dart';

/// Marqueur de fin de verset style Mushaf (cercle vert + chiffre arabe).
class VerseMarker extends StatelessWidget {
  const VerseMarker({
    super.key,
    required this.number,
    this.size = 26,
  });

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = toArabicNumerals(number);
    final fontSize = number >= 100 ? size * 0.38 : size * 0.48;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFDCEFDC),
          border: Border.all(color: AppColors.emerald, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.12),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.emeraldDark,
          ),
        ),
      ),
    );
  }
}
