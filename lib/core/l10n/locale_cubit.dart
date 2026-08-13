import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/utils/locale_preference.dart';

class LocaleCubit extends Cubit<AppLanguage> {
  LocaleCubit() : super(AppLanguage.portuguese) {
    _load();
  }

  Future<void> _load() async {
    final language = await LocalePreference.getLanguage();
    emit(language);
  }

  Future<void> setLanguage(AppLanguage language) async {
    await LocalePreference.setLanguage(language);
    emit(language);
  }
}
