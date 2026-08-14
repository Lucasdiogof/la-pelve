import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class ProfileStrings {
  const ProfileStrings(this.language);

  final AppLanguage language;

  String get languageRowLabel => switch (language) {
    AppLanguage.portuguese => 'Idioma',
    AppLanguage.english => 'Language',
  };

  String get languagePageTitle => switch (language) {
    AppLanguage.portuguese => 'Idioma',
    AppLanguage.english => 'Language',
  };

  String get languagePageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Escolha o idioma do app',
    AppLanguage.english => 'Choose the app language',
  };

  String languageOptionDescription(AppLanguage option) => switch (option) {
    AppLanguage.portuguese => switch (language) {
      AppLanguage.portuguese => 'Textos do app em português',
      AppLanguage.english => 'App text in Portuguese',
    },
    AppLanguage.english => switch (language) {
      AppLanguage.portuguese => 'Textos do app em inglês',
      AppLanguage.english => 'App text in English',
    },
  };

  String get profilePageTitle => switch (language) {
    AppLanguage.portuguese => 'Perfil',
    AppLanguage.english => 'Profile',
  };

  String get profilePageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Gerencie seu perfil',
    AppLanguage.english => 'Manage your profile',
  };

  String get profilePhotoTitle => switch (language) {
    AppLanguage.portuguese => 'Foto de perfil',
    AppLanguage.english => 'Profile photo',
  };

  String get nameRowLabel => switch (language) {
    AppLanguage.portuguese => 'Nome',
    AppLanguage.english => 'Name',
  };

  String get emailRowLabel => switch (language) {
    AppLanguage.portuguese => 'E-mail',
    AppLanguage.english => 'Email',
  };

  String get crefitoRowLabel => switch (language) {
    AppLanguage.portuguese => 'Crefito',
    AppLanguage.english => 'License number',
  };

  String get biometricsRowLabel => switch (language) {
    AppLanguage.portuguese => 'Biometria',
    AppLanguage.english => 'Biometrics',
  };

  String get themeRowLabel => switch (language) {
    AppLanguage.portuguese => 'Tema',
    AppLanguage.english => 'Theme',
  };

  String get statusEnabled => switch (language) {
    AppLanguage.portuguese => 'Ativada',
    AppLanguage.english => 'Enabled',
  };

  String get statusDisabled => switch (language) {
    AppLanguage.portuguese => 'Desativada',
    AppLanguage.english => 'Disabled',
  };

  String get nameUpdatedSuccessMessage => switch (language) {
    AppLanguage.portuguese => 'Nome atualizado com sucesso.',
    AppLanguage.english => 'Name updated successfully.',
  };

  String get signOutTitle => switch (language) {
    AppLanguage.portuguese => 'Sair',
    AppLanguage.english => 'Sign out',
  };

  String get signOutConfirmDescription => switch (language) {
    AppLanguage.portuguese => 'Deseja sair da sua conta?',
    AppLanguage.english => 'Do you want to sign out of your account?',
  };

  String get signOutButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Sair da conta',
    AppLanguage.english => 'Sign out',
  };

  String get deleteAccountLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir minha conta',
    AppLanguage.english => 'Delete my account',
  };

  String get deleteAccountConfirmDescription => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja excluir sua conta? Isso apaga permanentemente '
          'todos os pacientes, evoluções, lançamentos, agendamentos e anexos. '
          'Essa ação não pode ser desfeita.',
    AppLanguage.english =>
      'Are you sure you want to delete your account? This permanently erases '
          'all patients, evolutions, entries, appointments and attachments. '
          'This action cannot be undone.',
  };

  String get deleteAccountConfirmLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir conta',
    AppLanguage.english => 'Delete account',
  };

  String get biometricUnsupportedDescription => switch (language) {
    AppLanguage.portuguese =>
      'Este dispositivo não oferece suporte à biometria ou não possui um '
          'bloqueio de tela configurado.',
    AppLanguage.english =>
      'This device does not support biometrics or does not have a screen '
          'lock configured.',
  };

  String get biometricAuthReason => switch (language) {
    AppLanguage.portuguese => 'Confirme sua identidade para ativar a biometria',
    AppLanguage.english => 'Confirm your identity to enable biometrics',
  };

  String get biometricPageTitle => switch (language) {
    AppLanguage.portuguese => 'Biometria',
    AppLanguage.english => 'Biometrics',
  };

  String get biometricPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Proteja o acesso ao app',
    AppLanguage.english => 'Protect access to the app',
  };

  String get biometricSwitchTitle => switch (language) {
    AppLanguage.portuguese => 'Entrar com biometria',
    AppLanguage.english => 'Sign in with biometrics',
  };

  String get biometricSwitchSubtitle => switch (language) {
    AppLanguage.portuguese =>
      'Exige biometria para reabrir o app depois de minimizado.',
    AppLanguage.english =>
      'Requires biometrics to reopen the app after it has been minimized.',
  };

  String get editNamePageTitle => switch (language) {
    AppLanguage.portuguese => 'Editar nome',
    AppLanguage.english => 'Edit name',
  };

  String get editNamePageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Atualize seu nome de exibição',
    AppLanguage.english => 'Update your display name',
  };

  String get editNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome completo',
    AppLanguage.english => 'Full name',
  };

  String get saveButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Salvar',
    AppLanguage.english => 'Save',
  };

  String get themePageTitle => switch (language) {
    AppLanguage.portuguese => 'Tema',
    AppLanguage.english => 'Theme',
  };

  String get themePageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Escolha a aparência do app',
    AppLanguage.english => 'Choose the app appearance',
  };

  String themeOptionDescription(ThemeMode mode) => switch (mode) {
    ThemeMode.system => switch (language) {
      AppLanguage.portuguese => 'Segue a configuração do seu aparelho',
      AppLanguage.english => 'Follows your device settings',
    },
    ThemeMode.light => switch (language) {
      AppLanguage.portuguese => 'Fundo claro em todas as telas',
      AppLanguage.english => 'Light background on every screen',
    },
    ThemeMode.dark => switch (language) {
      AppLanguage.portuguese => 'Fundo escuro em todas as telas',
      AppLanguage.english => 'Dark background on every screen',
    },
  };

  String get photoPickerTitle => switch (language) {
    AppLanguage.portuguese => 'Foto de perfil',
    AppLanguage.english => 'Profile photo',
  };

  String get takePhotoLabel => switch (language) {
    AppLanguage.portuguese => 'Tirar foto',
    AppLanguage.english => 'Take photo',
  };

  String get chooseFromGalleryLabel => switch (language) {
    AppLanguage.portuguese => 'Escolher da galeria',
    AppLanguage.english => 'Choose from gallery',
  };

  String get notInformedLabel => switch (language) {
    AppLanguage.portuguese => 'Não informado',
    AppLanguage.english => 'Not informed',
  };
}
