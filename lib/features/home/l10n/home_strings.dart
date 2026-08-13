import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class HomeStrings {
  const HomeStrings(this.language);

  final AppLanguage language;

  String get navHome => switch (language) {
    AppLanguage.portuguese => 'Início',
    AppLanguage.english => 'Home',
  };

  String get navPatients => switch (language) {
    AppLanguage.portuguese => 'Pacientes',
    AppLanguage.english => 'Patients',
  };

  String get navAgenda => switch (language) {
    AppLanguage.portuguese => 'Agenda',
    AppLanguage.english => 'Agenda',
  };

  String get navFinancial => switch (language) {
    AppLanguage.portuguese => 'Financeiro',
    AppLanguage.english => 'Financial',
  };
}
