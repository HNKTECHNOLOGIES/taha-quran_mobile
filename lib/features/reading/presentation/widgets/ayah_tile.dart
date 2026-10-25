import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../surahs/domain/entities/ayah.dart';

/// Verset : médaillon + arabe RTL + traduction FR optionnelle.
class AyahTile extends StatelessWidget {
  const AyahTile({
    super.key,
    required this.ayah,
    this.showTranslation = true,
    this.arabicFontSize = 30,
  });

  final Ayah ayah;
  final bool showTranslation;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final arabicColor = isDark ? Colors.white : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              VerseMedallion(number: ayah.number),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ayah.textAr,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: arabicFontSize,
                    height: 2.0,
                    color: arabicColor,
                  ),
                ),
              ),
            ],
          ),
          if (showTranslation &&
              ayah.textFr != null &&
              ayah.textFr!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 44),
              child: Text(
                ayah.textFr!,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  height: 1.45,
                  color: isDark
                      ? Colors.white70
                      : AppColors.inkMuted.withValues(alpha: 0.95),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VerseMedallion extends StatelessWidget {
  const VerseMedallion({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emerald.withValues(alpha: 0.12),
            AppColors.gold.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        toArabicNumerals(number),
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.emeraldDark,
          height: 1,
        ),
      ),
    );
  }
}

class AyahSeparator extends StatelessWidget {
  const AyahSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.gold.withValues(alpha: 0.35),
              thickness: 0.8,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.brightness_1,
              size: 6,
              color: AppColors.emerald.withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.gold.withValues(alpha: 0.35),
              thickness: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
