import 'package:flutter/widgets.dart';

enum AppLanguage {
  portuguese,
  english,
  spanish;

  static AppLanguage fromDeviceLocale() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return switch (deviceLocale.languageCode) {
      'en' => AppLanguage.english,
      'es' => AppLanguage.spanish,
      _ => AppLanguage.portuguese,
    };
  }

  Locale get locale => switch (this) {
    AppLanguage.portuguese => const Locale('pt', 'BR'),
    AppLanguage.english => const Locale('en'),
    AppLanguage.spanish => const Locale('es'),
  };

  String get label => switch (this) {
    AppLanguage.portuguese => 'Português',
    AppLanguage.english => 'English',
    AppLanguage.spanish => 'Español',
  };

  String get appName => switch (this) {
    AppLanguage.portuguese => 'La Pelve',
    AppLanguage.english => 'La Pelve',
    AppLanguage.spanish => 'La Pelve',
  };
}
