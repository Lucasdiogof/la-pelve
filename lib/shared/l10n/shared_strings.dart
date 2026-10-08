import 'package:la_pelve/core/l10n/app_language.dart';

class SharedStrings {
  const SharedStrings(this.language);

  final AppLanguage language;

  String get cancel => switch (language) {
    AppLanguage.portuguese => 'Cancelar',
    AppLanguage.english => 'Cancel',
    AppLanguage.spanish => 'Cancelar',
  };

  String get yes => switch (language) {
    AppLanguage.portuguese => 'Sim',
    AppLanguage.english => 'Yes',
    AppLanguage.spanish => 'Sí',
  };

  String get no => switch (language) {
    AppLanguage.portuguese => 'Não',
    AppLanguage.english => 'No',
    AppLanguage.spanish => 'No',
  };

  String get nextButton => switch (language) {
    AppLanguage.portuguese => 'Próximo',
    AppLanguage.english => 'Next',
    AppLanguage.spanish => 'Siguiente',
  };

  String get saveEditButton => switch (language) {
    AppLanguage.portuguese => 'Salvar edição',
    AppLanguage.english => 'Save edit',
    AppLanguage.spanish => 'Guardar edición',
  };

  String stepOf(int current, int total) => switch (language) {
    AppLanguage.portuguese => 'Etapa $current de $total',
    AppLanguage.english => 'Step $current of $total',
    AppLanguage.spanish => 'Paso $current de $total',
  };

  String get understood => switch (language) {
    AppLanguage.portuguese => 'Entendi',
    AppLanguage.english => 'Got it',
    AppLanguage.spanish => 'Entendido',
  };

  String get errorTitle => switch (language) {
    AppLanguage.portuguese => 'Não foi possível continuar',
    AppLanguage.english => "Couldn't continue",
    AppLanguage.spanish => 'No fue posible continuar',
  };

  String get successTitle => switch (language) {
    AppLanguage.portuguese => 'Tudo certo!',
    AppLanguage.english => 'All set!',
    AppLanguage.spanish => '¡Todo listo!',
  };

  String get infoTitle => switch (language) {
    AppLanguage.portuguese => 'Informação',
    AppLanguage.english => 'Information',
    AppLanguage.spanish => 'Información',
  };

  String get invalidAge => switch (language) {
    AppLanguage.portuguese => 'Informe uma idade válida.',
    AppLanguage.english => 'Enter a valid age.',
    AppLanguage.spanish => 'Ingresa una edad válida.',
  };

  String get invalidPhone => switch (language) {
    AppLanguage.portuguese => 'Informe um telefone válido.',
    AppLanguage.english => 'Enter a valid phone number.',
    AppLanguage.spanish => 'Ingresa un teléfono válido.',
  };

  String get invalidCrefito => switch (language) {
    AppLanguage.portuguese => 'Informe um Crefito com 4 a 10 números.',
    AppLanguage.english => 'Enter a Crefito number with 4 to 10 digits.',
    AppLanguage.spanish => 'Ingresa un Crefito con 4 a 10 números.',
  };

  String get loadErrorTitle => switch (language) {
    AppLanguage.portuguese => 'Não foi possível carregar',
    AppLanguage.english => "Couldn't load",
    AppLanguage.spanish => 'No fue posible cargar',
  };

  String get loadErrorMessage => switch (language) {
    AppLanguage.portuguese =>
      'Verifique sua conexão. Seus dados continuam salvos.',
    AppLanguage.english => 'Check your connection. Your data is still saved.',
    AppLanguage.spanish => 'Verifica tu conexión. Tus datos siguen guardados.',
  };

  String get sessionLoadErrorTitle => switch (language) {
    AppLanguage.portuguese => 'Não foi possível carregar sua clínica',
    AppLanguage.english => "Couldn't load your clinic",
    AppLanguage.spanish => 'No fue posible cargar tu clínica',
  };

  String get retry => switch (language) {
    AppLanguage.portuguese => 'Tentar novamente',
    AppLanguage.english => 'Try again',
    AppLanguage.spanish => 'Intentar de nuevo',
  };

  String get refreshFailed => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível atualizar. Mostrando os últimos dados carregados.',
    AppLanguage.english => "Couldn't refresh. Showing the last loaded data.",
    AppLanguage.spanish =>
      'No fue posible actualizar. Mostrando los últimos datos cargados.',
  };
}
