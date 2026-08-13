import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class SharedStrings {
  const SharedStrings(this.language);

  final AppLanguage language;

  String get cancel => switch (language) {
    AppLanguage.portuguese => 'Cancelar',
    AppLanguage.english => 'Cancel',
  };

  String get understood => switch (language) {
    AppLanguage.portuguese => 'Entendi',
    AppLanguage.english => 'Got it',
  };

  String get errorTitle => switch (language) {
    AppLanguage.portuguese => 'Não foi possível continuar',
    AppLanguage.english => "Couldn't continue",
  };

  String get successTitle => switch (language) {
    AppLanguage.portuguese => 'Tudo certo!',
    AppLanguage.english => 'All set!',
  };

  String get infoTitle => switch (language) {
    AppLanguage.portuguese => 'Informação',
    AppLanguage.english => 'Information',
  };

  String get invalidAge => switch (language) {
    AppLanguage.portuguese => 'Informe uma idade válida.',
    AppLanguage.english => 'Enter a valid age.',
  };

  String get invalidPhone => switch (language) {
    AppLanguage.portuguese => 'Informe um telefone válido.',
    AppLanguage.english => 'Enter a valid phone number.',
  };

  String get invalidCrefito => switch (language) {
    AppLanguage.portuguese => 'Informe um Crefito válido (ex: 123456-F3).',
    AppLanguage.english => 'Enter a valid Crefito number (e.g. 123456-F3).',
  };
}
