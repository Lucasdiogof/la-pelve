import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class SharedStrings {
  const SharedStrings(this.language);

  final AppLanguage language;

  String get cancel => switch (language) {
    AppLanguage.portuguese => 'Cancelar',
    AppLanguage.english => 'Cancel',
  };

  String get yes => switch (language) {
    AppLanguage.portuguese => 'Sim',
    AppLanguage.english => 'Yes',
  };

  String get no => switch (language) {
    AppLanguage.portuguese => 'Não',
    AppLanguage.english => 'No',
  };

  String get nextButton => switch (language) {
    AppLanguage.portuguese => 'Próximo',
    AppLanguage.english => 'Next',
  };

  String get saveEditButton => switch (language) {
    AppLanguage.portuguese => 'Salvar edição',
    AppLanguage.english => 'Save edit',
  };

  String stepOf(int current, int total) => switch (language) {
    AppLanguage.portuguese => 'Etapa $current de $total',
    AppLanguage.english => 'Step $current of $total',
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
