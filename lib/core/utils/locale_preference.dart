import 'package:shared_preferences/shared_preferences.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class LocalePreference {
  static const _key = 'app_language';

  static Future<AppLanguage> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_key)) {
      'english' => AppLanguage.english,
      _ => AppLanguage.portuguese,
    };
  }

  static Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.name);
  }
}
