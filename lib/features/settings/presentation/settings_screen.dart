import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/locale_provider.dart';
import '../../../app/providers/reading_settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../audio/data/reciter_catalog.dart';
import '../../audio/presentation/providers/audio_providers.dart';
import '../../audio/presentation/providers/download_providers.dart';
import '../../tafsir/presentation/providers/tafsir_providers.dart';
import '../../translations/presentation/providers/translation_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final settings = ref.watch(readingSettingsProvider);
    final info = ref.watch(frenchTranslationInfoProvider).asData?.value;
    final reciter = ref.watch(selectedReciterProvider);
    final tafsirInfo = ref.watch(ibnKathirInfoProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.mushafCream,
      appBar: AppBar(
        title: Text(s.settings),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionTitle(s.reciterSection),
          for (final r in ReciterCatalog.all)
            ListTile(
              title: Text(r.nameEn),
              subtitle: Text(
                '${r.nameAr} · ${r.bitrateLabel}',
                textDirection: TextDirection.rtl,
              ),
              trailing: Icon(
                r.id == reciter.id
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: r.id == reciter.id
                    ? AppColors.emerald
                    : AppColors.creamDark,
              ),
              onTap: () => ref
                  .read(audioControllerProvider.notifier)
                  .changeReciter(r),
            ),
          const SizedBox(height: 8),
          _SectionTitle(s.downloadsSection),
          SwitchListTile(
            value: ref.watch(wifiOnlyDownloadProvider),
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.emerald.withValues(alpha: 0.45),
            title: Text(s.wifiOnlyDownloads),
            subtitle: Text(s.wifiOnlyDownloadsHint),
            onChanged: (v) =>
                ref.read(wifiOnlyDownloadProvider.notifier).setWifiOnly(v),
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined,
                color: AppColors.emerald),
            title: Text(s.myDownloads),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/downloads'),
          ),
          const SizedBox(height: 8),
          _SectionTitle(s.aboutAudio),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.creamDark),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${reciter.sourceAttribution}\n'
                '${reciter.supportsVerseSync ? 'Fichiers par verset (everyayah.com). ' : 'Fichier par sourate (mp3quran.net) — pas de sync. verset sans minutage. '}'
                'Streamés par défaut ; téléchargeables hors-ligne à la demande (non inclus dans le binaire).',
                style: TextStyle(
                  fontFamily: 'SourceSerif4',
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(s.translationSection),
          SwitchListTile(
            value: settings.showFrenchTranslation,
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.emerald.withValues(alpha: 0.45),
            title: Text(s.showTranslation),
            subtitle: Text(
              settings.showFrenchTranslation
                  ? s.translationVisible
                  : s.translationHidden,
            ),
            onChanged: (v) => ref
                .read(readingSettingsProvider.notifier)
                .setShowFrenchTranslation(v),
          ),
          ListTile(
            title: Text(s.translationFontSize),
            subtitle: Slider(
              value: settings.translationFontSize,
              min: 12,
              max: 28,
              divisions: 16,
              activeColor: AppColors.emerald,
              label: settings.translationFontSize.round().toString(),
              onChanged: (v) => ref
                  .read(readingSettingsProvider.notifier)
                  .setTranslationFontSize(v),
            ),
            trailing: Text(
              '${settings.translationFontSize.round()}',
              style: const TextStyle(
                fontFamily: 'SourceSerif4',
                fontWeight: FontWeight.w600,
                color: AppColors.emeraldDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionTitle(s.aboutTranslation),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.creamDark),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: info == null
                  ? Text(s.noTranslationInstalled)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.translator,
                          style: const TextStyle(
                            fontFamily: 'SourceSerif4',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${s.editionLabel}: ${info.edition}',
                          style: const TextStyle(fontFamily: 'SourceSerif4'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.licenseLabel}: ${info.license}',
                          style: const TextStyle(fontFamily: 'SourceSerif4'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          info.attribution,
                          style: TextStyle(
                            fontFamily: 'SourceSerif4',
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(s.tafsirSection),
          ListTile(
            title: Text(s.tafsirFontSize),
            subtitle: Slider(
              value: settings.tafsirFontSize,
              min: 14,
              max: 32,
              divisions: 18,
              activeColor: AppColors.emerald,
              label: settings.tafsirFontSize.round().toString(),
              onChanged: (v) => ref
                  .read(readingSettingsProvider.notifier)
                  .setTafsirFontSize(v),
            ),
            trailing: Text(
              '${settings.tafsirFontSize.round()}',
              style: const TextStyle(
                fontFamily: 'SourceSerif4',
                fontWeight: FontWeight.w600,
                color: AppColors.emeraldDark,
              ),
            ),
          ),
          _SectionTitle(s.aboutTafsir),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.creamDark),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: tafsirInfo == null
                  ? Text(s.tafsirUnavailable)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tafsirInfo.workAr,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tafsirInfo.commentatorAr,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${s.licenseLabel}: ${tafsirInfo.license}',
                          style: const TextStyle(fontFamily: 'SourceSerif4'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tafsirInfo.attribution,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.emerald,
        ),
      ),
    );
  }
}
