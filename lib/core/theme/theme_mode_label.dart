import 'package:flutter/material.dart';
import 'package:la_pelve/core/l10n/app_language.dart';

String themeModeLabel(ThemeMode mode, AppLanguage language) =>
    switch ((mode, language)) {
      (ThemeMode.system, AppLanguage.portuguese) => 'Automático',
      (ThemeMode.system, AppLanguage.english) => 'Automatic',
      (ThemeMode.system, AppLanguage.spanish) => 'Automático',
      (ThemeMode.light, AppLanguage.portuguese) => 'Claro',
      (ThemeMode.light, AppLanguage.english) => 'Light',
      (ThemeMode.light, AppLanguage.spanish) => 'Claro',
      (ThemeMode.dark, AppLanguage.portuguese) => 'Escuro',
      (ThemeMode.dark, AppLanguage.english) => 'Dark',
      (ThemeMode.dark, AppLanguage.spanish) => 'Oscuro',
    };
