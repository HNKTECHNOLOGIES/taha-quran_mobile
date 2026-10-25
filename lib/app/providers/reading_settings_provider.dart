import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kShowTranslation = 'reading_show_translation_fr';
const _kTranslationFontSize = 'reading_translation_font_size';

class ReadingSettings {
  const ReadingSettings({
    this.showFrenchTranslation = true,
    this.translationFontSize = 16,
  });

  final bool showFrenchTranslation;
  final double translationFontSize;

  ReadingSettings copyWith({
    bool? showFrenchTranslation,
    double? translationFontSize,
  }) {
    return ReadingSettings(
      showFrenchTranslation:
          showFrenchTranslation ?? this.showFrenchTranslation,
      translationFontSize: translationFontSize ?? this.translationFontSize,
    );
  }
}

final readingSettingsProvider =
    NotifierProvider<ReadingSettingsNotifier, ReadingSettings>(
  ReadingSettingsNotifier.new,
);

class ReadingSettingsNotifier extends Notifier<ReadingSettings> {
  @override
  ReadingSettings build() {
    _load();
    return const ReadingSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final show = prefs.getBool(_kShowTranslation) ?? true;
      final size = prefs.getDouble(_kTranslationFontSize) ?? 16;
      state = ReadingSettings(
        showFrenchTranslation: show,
        translationFontSize: size.clamp(12, 28),
      );
    } catch (_) {}
  }

  Future<void> toggleFrenchTranslation() async {
    final next = !state.showFrenchTranslation;
    state = state.copyWith(showFrenchTranslation: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kShowTranslation, next);
    } catch (_) {}
  }

  Future<void> setShowFrenchTranslation(bool value) async {
    state = state.copyWith(showFrenchTranslation: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kShowTranslation, value);
    } catch (_) {}
  }

  Future<void> setTranslationFontSize(double value) async {
    final size = value.clamp(12, 28).toDouble();
    state = state.copyWith(translationFontSize: size);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kTranslationFontSize, size);
    } catch (_) {}
  }
}
