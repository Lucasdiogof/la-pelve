import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/utils/locale_preference.dart';

class LocaleCubit extends Cubit<AppLanguage> {
  LocaleCubit() : super(AppLanguage.fromDeviceLocale()) {
    _load();
  }

  Future<void> _load() async {
    final saved = await LocalePreference.getLanguage();
    if (saved != null) emit(saved);
  }

  Future<void> setLanguage(AppLanguage language) async {
    await LocalePreference.setLanguage(language);
    emit(language);
  }
}
