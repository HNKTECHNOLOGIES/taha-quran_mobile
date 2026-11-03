import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../library/domain/entities/verse_ref.dart';
import '../../domain/entities/tafsir_passage.dart';
import '../providers/tafsir_providers.dart';

/// Panneau repliable « تفسير ابن كثير » — charge le texte au premier ouverture.
class IbnKathirExpandable extends ConsumerStatefulWidget {
  const IbnKathirExpandable({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.strings,
    this.fontSize = 17,
  });

  final int surahId;
  final int ayahNumber;
  final AppStrings strings;
  final double fontSize;

  @override
  ConsumerState<IbnKathirExpandable> createState() =>
      _IbnKathirExpandableState();
}

class _IbnKathirExpandableState extends ConsumerState<IbnKathirExpandable> {
  bool _expanded = false;
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    final verse = VerseRef(
      surahId: widget.surahId,
      ayahNumber: widget.ayahNumber,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, end: 8, top: 4),
      child: Material(
        color: AppColors.creamDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _expanded = !_expanded;
              if (_expanded) _requested = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.menu_book_outlined,
                      color: AppColors.emerald,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.strings.ibnKathirTitle,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
                if (_expanded && _requested) ...[
                  const SizedBox(height: 10),
                  _TafsirBody(
                    verse: verse,
                    strings: widget.strings,
                    fontSize: widget.fontSize,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TafsirBody extends ConsumerWidget {
  const _TafsirBody({
    required this.verse,
    required this.strings,
    required this.fontSize,
  });

  final VerseRef verse;
  final AppStrings strings;
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ibnKathirPassageProvider(verse));

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              strings.loading,
              style: TextStyle(
                fontFamily: 'SourceSerif4',
                fontSize: 13,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Text(
        '${strings.tafsirUnavailable}\n$e',
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          color: Colors.redAccent,
        ),
      ),
      data: (passage) {
        if (passage == null) {
          return Text(
            strings.tafsirUnavailable,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              color: AppColors.inkMuted,
            ),
          );
        }
        return _PassageView(
          passage: passage,
          strings: strings,
          fontSize: fontSize,
        );
      },
    );
  }
}

class _PassageView extends StatelessWidget {
  const _PassageView({
    required this.passage,
    required this.strings,
    required this.fontSize,
  });

  final TafsirPassage passage;
  final AppStrings strings;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${passage.workAr} — ${passage.commentatorAr}',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.emeraldDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${strings.tafsirVerseRef}: ${passage.verseRefLabel}'
          '${passage.isMultiAyah ? ' (${strings.tafsirMultiAyahNote})' : ''}',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'SourceSerif4',
            fontSize: 12,
            color: AppColors.inkMuted.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 10),
        SelectableText(
          passage.textAr,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize,
            height: 1.85,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
