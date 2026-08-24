import 'package:shared_preferences/shared_preferences.dart';

class FinancialVisibilityPreference {
  static const _key = 'home_financial_hidden';

  static Future<bool> isHidden() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setHidden(bool hidden) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, hidden);
  }
}
