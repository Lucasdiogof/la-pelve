import 'package:flutter/widgets.dart';

enum AppLanguage {
  portuguese,
  english;

  static AppLanguage fromDeviceLocale() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return deviceLocale.languageCode == 'en'
        ? AppLanguage.english
        : AppLanguage.portuguese;
  }

  Locale get locale => switch (this) {
    AppLanguage.portuguese => const Locale('pt', 'BR'),
    AppLanguage.english => const Locale('en'),
  };

  String get label => switch (this) {
    AppLanguage.portuguese => 'Português',
    AppLanguage.english => 'English',
  };

  String get appName => switch (this) {
    AppLanguage.portuguese => 'Fisioterapia Pélvica',
    AppLanguage.english => 'Pelvic Physiotherapy',
  };
}
