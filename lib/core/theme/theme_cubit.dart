import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/utils/theme_preference.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final mode = await ThemePreference.getMode();
    emit(mode);
  }

  Future<void> setMode(ThemeMode mode) async {
    await ThemePreference.setMode(mode);
    emit(mode);
  }
}
