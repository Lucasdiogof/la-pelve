import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

String themeModeLabel(ThemeMode mode, AppLanguage language) =>
    switch ((mode, language)) {
      (ThemeMode.system, AppLanguage.portuguese) => 'Automático',
      (ThemeMode.system, AppLanguage.english) => 'Automatic',
      (ThemeMode.light, AppLanguage.portuguese) => 'Claro',
      (ThemeMode.light, AppLanguage.english) => 'Light',
      (ThemeMode.dark, AppLanguage.portuguese) => 'Escuro',
      (ThemeMode.dark, AppLanguage.english) => 'Dark',
    };
