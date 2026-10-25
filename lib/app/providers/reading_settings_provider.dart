import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kShowTranslation = 'reading_show_translation_fr';

class ReadingSettings {
  const ReadingSettings({this.showFrenchTranslation = true});

  final bool showFrenchTranslation;

  ReadingSettings copyWith({bool? showFrenchTranslation}) {
    return ReadingSettings(
      showFrenchTranslation:
          showFrenchTranslation ?? this.showFrenchTranslation,
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
      state = ReadingSettings(showFrenchTranslation: show);
    } catch (_) {
      // Tests / plateformes sans prefs : garder la valeur par défaut.
    }
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
}
