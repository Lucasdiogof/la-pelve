import 'package:flutter/material.dart';

enum AppLanguage {
  portuguese,
  english;

  Locale get locale => switch (this) {
    AppLanguage.portuguese => const Locale('pt', 'BR'),
    AppLanguage.english => const Locale('en'),
  };

  String get label => switch (this) {
    AppLanguage.portuguese => 'Português',
    AppLanguage.english => 'English',
  };
}
