import 'package:flutter/material.dart';

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Automático',
  ThemeMode.light => 'Claro',
  ThemeMode.dark => 'Escuro',
};
