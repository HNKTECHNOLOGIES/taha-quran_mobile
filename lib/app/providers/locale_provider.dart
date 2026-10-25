import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';

final localeProvider =
    NotifierProvider<LocaleNotifier, AppStrings>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<AppStrings> {
  @override
  AppStrings build() => AppStrings.fr;

  void setFrench() => state = AppStrings.fr;
  void setArabic() => state = AppStrings.ar;

  void toggle() {
    state = state.language == AppLanguage.french ? AppStrings.ar : AppStrings.fr;
  }
}
