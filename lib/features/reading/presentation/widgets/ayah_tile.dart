import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../surahs/domain/entities/ayah.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VerseNumber(number: ayah.number),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ayah.textAr,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: arabicFontSize,
                    height: 2.0,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerseNumber extends StatelessWidget {
  const _VerseNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 1.4),
        color: AppColors.emerald.withValues(alpha: 0.08),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.emerald,
        ),
      ),
    );
  }
}
