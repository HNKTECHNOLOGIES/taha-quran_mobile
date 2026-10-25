import 'package:flutter/material.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/surah.dart';

class SurahListTile extends StatelessWidget {
  const SurahListTile({
    super.key,
    required this.surah,
    required this.strings,
    required this.onTap,
  });

  final Surah surah;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: isDark ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${surah.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.emerald,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameAr,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 22,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.transliteration} · ${strings.verseCountLabel(surah.versesCount)}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.inkMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                strings.revelationLabel(surah.revelationType),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gold.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
