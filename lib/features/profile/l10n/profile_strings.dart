import 'package:flutter/material.dart';
import 'package:la_pelve/core/l10n/app_language.dart';

class ProfileStrings {
  const ProfileStrings(this.language);

  final AppLanguage language;

  String get languageRowLabel => switch (language) {
    AppLanguage.portuguese => 'Idioma',
    AppLanguage.english => 'Language',
    AppLanguage.spanish => 'Idioma',
  };

  String get languagePageTitle => switch (language) {
    AppLanguage.portuguese => 'Idioma',
    AppLanguage.english => 'Language',
    AppLanguage.spanish => 'Idioma',
  };

  String get languagePageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Escolha o idioma do app',
    AppLanguage.english => 'Choose the app language',
    AppLanguage.spanish => 'Elige el idioma de la app',
  };

  String languageOptionDescription(AppLanguage option) => switch (option) {
    AppLanguage.portuguese => switch (language) {
      AppLanguage.portuguese => 'Textos do app em português',
      AppLanguage.english => 'App text in Portuguese',
      AppLanguage.spanish => 'Textos de la app en portugués',
    },
    AppLanguage.english => switch (language) {
      AppLanguage.portuguese => 'Textos do app em inglês',
      AppLanguage.english => 'App text in English',
      AppLanguage.spanish => 'Textos de la app en inglés',
    },
    AppLanguage.spanish => switch (language) {
      AppLanguage.portuguese => 'Textos do app em espanhol',
      AppLanguage.english => 'App text in Spanish',
      AppLanguage.spanish => 'Textos de la app en español',
    },
  };

  String get profilePageTitle => switch (language) {
    AppLanguage.portuguese => 'Perfil',
    AppLanguage.english => 'Profile',
    AppLanguage.spanish => 'Perfil',
  };

  String get profilePageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Gerencie seu perfil',
    AppLanguage.english => 'Manage your profile',
    AppLanguage.spanish => 'Gestiona tu perfil',
  };

  String get profileSectionTitle => switch (language) {
    AppLanguage.portuguese => 'Perfil profissional',
    AppLanguage.english => 'Professional profile',
    AppLanguage.spanish => 'Perfil profesional',
  };

  String get preferencesSectionTitle => switch (language) {
    AppLanguage.portuguese => 'Preferências',
    AppLanguage.english => 'Preferences',
    AppLanguage.spanish => 'Preferencias',
  };

  String get accountSectionTitle => switch (language) {
    AppLanguage.portuguese => 'Conta',
    AppLanguage.english => 'Account',
    AppLanguage.spanish => 'Cuenta',
  };

  String get profilePhotoTitle => switch (language) {
    AppLanguage.portuguese => 'Foto de perfil',
    AppLanguage.english => 'Profile photo',
    AppLanguage.spanish => 'Foto de perfil',
  };

  String get removePhotoTitle => switch (language) {
    AppLanguage.portuguese => 'Remover foto',
    AppLanguage.english => 'Remove photo',
    AppLanguage.spanish => 'Eliminar foto',
  };

  String get removePhotoDescription => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja remover sua foto de perfil?',
    AppLanguage.english =>
      'Are you sure you want to remove your profile photo?',
    AppLanguage.spanish => '¿Seguro que deseas eliminar tu foto de perfil?',
  };

  String get nameRowLabel => switch (language) {
    AppLanguage.portuguese => 'Nome',
    AppLanguage.english => 'Name',
    AppLanguage.spanish => 'Nombre',
  };

  String get emailRowLabel => switch (language) {
    AppLanguage.portuguese => 'E-mail',
    AppLanguage.english => 'Email',
    AppLanguage.spanish => 'Correo electrónico',
  };

  String get crefitoRowLabel => switch (language) {
    AppLanguage.portuguese => 'Crefito',
    AppLanguage.english => 'License number',
    AppLanguage.spanish => 'Número de licencia',
  };

  String get biometricsRowLabel => switch (language) {
    AppLanguage.portuguese => 'Biometria',
    AppLanguage.english => 'Biometrics',
    AppLanguage.spanish => 'Biometría',
  };

  String get changePasswordRowLabel => switch (language) {
    AppLanguage.portuguese => 'Alterar senha',
    AppLanguage.english => 'Change password',
    AppLanguage.spanish => 'Cambiar contraseña',
  };

  String get changePasswordPageTitle => switch (language) {
    AppLanguage.portuguese => 'Alterar senha',
    AppLanguage.english => 'Change password',
    AppLanguage.spanish => 'Cambiar contraseña',
  };

  String get changePasswordPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Informe sua senha atual e a nova senha',
    AppLanguage.english => 'Enter your current password and the new one',
    AppLanguage.spanish => 'Ingresa tu contraseña actual y la nueva',
  };

  String get currentPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Senha atual',
    AppLanguage.english => 'Current password',
    AppLanguage.spanish => 'Contraseña actual',
  };

  String get newPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Nova senha',
    AppLanguage.english => 'New password',
    AppLanguage.spanish => 'Nueva contraseña',
  };

  String get confirmNewPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Confirmar nova senha',
    AppLanguage.english => 'Confirm new password',
    AppLanguage.spanish => 'Confirmar nueva contraseña',
  };

  String get currentPasswordIncorrectError => switch (language) {
    AppLanguage.portuguese => 'Senha atual incorreta.',
    AppLanguage.english => 'Current password is incorrect.',
    AppLanguage.spanish => 'La contraseña actual es incorrecta.',
  };

  String get passwordChangedSuccessMessage => switch (language) {
    AppLanguage.portuguese => 'Senha alterada com sucesso.',
    AppLanguage.english => 'Password changed successfully.',
    AppLanguage.spanish => 'Contraseña cambiada con éxito.',
  };

  String get themeRowLabel => switch (language) {
    AppLanguage.portuguese => 'Tema',
    AppLanguage.english => 'Theme',
    AppLanguage.spanish => 'Tema',
  };

  String get statusEnabled => switch (language) {
    AppLanguage.portuguese => 'Ativada',
    AppLanguage.english => 'Enabled',
    AppLanguage.spanish => 'Activada',
  };

  String get statusDisabled => switch (language) {
    AppLanguage.portuguese => 'Desativada',
    AppLanguage.english => 'Disabled',
    AppLanguage.spanish => 'Desactivada',
  };

  String get nameUpdatedSuccessMessage => switch (language) {
    AppLanguage.portuguese => 'Nome atualizado com sucesso.',
    AppLanguage.english => 'Name updated successfully.',
    AppLanguage.spanish => 'Nombre actualizado con éxito.',
  };

  String get signOutTitle => switch (language) {
    AppLanguage.portuguese => 'Sair',
    AppLanguage.english => 'Sign out',
    AppLanguage.spanish => 'Cerrar sesión',
  };

  String get signOutConfirmDescription => switch (language) {
    AppLanguage.portuguese => 'Deseja sair da sua conta?',
    AppLanguage.english => 'Do you want to sign out of your account?',
    AppLanguage.spanish => '¿Deseas cerrar sesión de tu cuenta?',
  };

  String get signOutButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Sair da conta',
    AppLanguage.english => 'Sign out',
    AppLanguage.spanish => 'Cerrar sesión',
  };

  String get deleteAccountLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir minha conta',
    AppLanguage.english => 'Delete my account',
    AppLanguage.spanish => 'Eliminar mi cuenta',
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
    AppLanguage.spanish =>
      '¿Seguro que deseas eliminar tu cuenta? Esto borra permanentemente '
          'todos los pacientes, evoluciones, movimientos, citas y adjuntos. '
          'Esta acción no se puede deshacer.',
  };

  String get deleteAccountConfirmLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir conta',
    AppLanguage.english => 'Delete account',
    AppLanguage.spanish => 'Eliminar cuenta',
  };

  String get biometricUnsupportedDescription => switch (language) {
    AppLanguage.portuguese =>
      'Este dispositivo não oferece suporte à biometria ou não possui um '
          'bloqueio de tela configurado.',
    AppLanguage.english =>
      'This device does not support biometrics or does not have a screen '
          'lock configured.',
    AppLanguage.spanish =>
      'Este dispositivo no admite biometría o no tiene un bloqueo de '
          'pantalla configurado.',
  };

  String get biometricAuthReason => switch (language) {
    AppLanguage.portuguese => 'Confirme sua identidade para ativar a biometria',
    AppLanguage.english => 'Confirm your identity to enable biometrics',
    AppLanguage.spanish => 'Confirma tu identidad para activar la biometría',
  };

  String get biometricPageTitle => switch (language) {
    AppLanguage.portuguese => 'Biometria',
    AppLanguage.english => 'Biometrics',
    AppLanguage.spanish => 'Biometría',
  };

  String get biometricPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Proteja o acesso ao app',
    AppLanguage.english => 'Protect access to the app',
    AppLanguage.spanish => 'Protege el acceso a la app',
  };

  String get biometricSwitchTitle => switch (language) {
    AppLanguage.portuguese => 'Entrar com biometria',
    AppLanguage.english => 'Sign in with biometrics',
    AppLanguage.spanish => 'Iniciar sesión con biometría',
  };

  String get biometricSwitchSubtitle => switch (language) {
    AppLanguage.portuguese =>
      'Exige biometria para reabrir o app depois de minimizado.',
    AppLanguage.english =>
      'Requires biometrics to reopen the app after it has been minimized.',
    AppLanguage.spanish =>
      'Exige biometría para volver a abrir la app después de minimizarla.',
  };

  String get editNamePageTitle => switch (language) {
    AppLanguage.portuguese => 'Editar nome',
    AppLanguage.english => 'Edit name',
    AppLanguage.spanish => 'Editar nombre',
  };

  String get editNamePageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Atualize seu nome de exibição',
    AppLanguage.english => 'Update your display name',
    AppLanguage.spanish => 'Actualiza tu nombre de perfil',
  };

  String get editNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome completo',
    AppLanguage.english => 'Full name',
    AppLanguage.spanish => 'Nombre completo',
  };

  String get saveButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Salvar',
    AppLanguage.english => 'Save',
    AppLanguage.spanish => 'Guardar',
  };

  String get themePageTitle => switch (language) {
    AppLanguage.portuguese => 'Tema',
    AppLanguage.english => 'Theme',
    AppLanguage.spanish => 'Tema',
  };

  String get themePageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Escolha a aparência do app',
    AppLanguage.english => 'Choose the app appearance',
    AppLanguage.spanish => 'Elige la apariencia de la app',
  };

  String themeOptionDescription(ThemeMode mode) => switch (mode) {
    ThemeMode.system => switch (language) {
      AppLanguage.portuguese => 'Segue a configuração do seu aparelho',
      AppLanguage.english => 'Follows your device settings',
      AppLanguage.spanish => 'Sigue la configuración de tu dispositivo',
    },
    ThemeMode.light => switch (language) {
      AppLanguage.portuguese => 'Fundo claro em todas as telas',
      AppLanguage.english => 'Light background on every screen',
      AppLanguage.spanish => 'Fondo claro en todas las pantallas',
    },
    ThemeMode.dark => switch (language) {
      AppLanguage.portuguese => 'Fundo escuro em todas as telas',
      AppLanguage.english => 'Dark background on every screen',
      AppLanguage.spanish => 'Fondo oscuro en todas las pantallas',
    },
  };

  String get photoPickerTitle => switch (language) {
    AppLanguage.portuguese => 'Foto de perfil',
    AppLanguage.english => 'Profile photo',
    AppLanguage.spanish => 'Foto de perfil',
  };

  String get takePhotoLabel => switch (language) {
    AppLanguage.portuguese => 'Tirar foto',
    AppLanguage.english => 'Take photo',
    AppLanguage.spanish => 'Tomar foto',
  };

  String get chooseFromGalleryLabel => switch (language) {
    AppLanguage.portuguese => 'Escolher da galeria',
    AppLanguage.english => 'Choose from gallery',
    AppLanguage.spanish => 'Elegir de la galería',
  };

  String get notInformedLabel => switch (language) {
    AppLanguage.portuguese => 'Não informado',
    AppLanguage.english => 'Not informed',
    AppLanguage.spanish => 'No informado',
  };

  String get whatsappRowLabel => switch (language) {
    AppLanguage.portuguese => 'WhatsApp',
    AppLanguage.english => 'WhatsApp',
    AppLanguage.spanish => 'WhatsApp',
  };

  String get whatsappPageTitle => switch (language) {
    AppLanguage.portuguese => 'WhatsApp',
    AppLanguage.english => 'WhatsApp',
    AppLanguage.spanish => 'WhatsApp',
  };

  String get whatsappPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Lembretes de agendamento',
    AppLanguage.english => 'Appointment reminders',
    AppLanguage.spanish => 'Recordatorios de citas',
  };

  String get whatsappNotConnectedTitle => switch (language) {
    AppLanguage.portuguese => 'WhatsApp não conectado',
    AppLanguage.english => 'WhatsApp not connected',
    AppLanguage.spanish => 'WhatsApp no conectado',
  };

  String get whatsappNotConnectedMessage => switch (language) {
    AppLanguage.portuguese =>
      'Conecte seu WhatsApp Business para que o La Pelve possa enviar '
          'lembretes de agendamento aos pacientes que autorizaram esse '
          'contato.',
    AppLanguage.english =>
      'Connect your WhatsApp Business so La Pelve can send appointment '
          'reminders to patients who authorized this contact.',
    AppLanguage.spanish =>
      'Conecta tu WhatsApp Business para que La Pelve pueda enviar '
          'recordatorios de citas a los pacientes que autorizaron este '
          'contacto.',
  };

  String get connectWhatsappButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Conectar WhatsApp',
    AppLanguage.english => 'Connect WhatsApp',
    AppLanguage.spanish => 'Conectar WhatsApp',
  };

  String get whatsappIntegrationInProgressNote => switch (language) {
    AppLanguage.portuguese => 'Integração em configuração',
    AppLanguage.english => 'Integration being configured',
    AppLanguage.spanish => 'Integración en configuración',
  };

  String get whatsappPendingTitle => switch (language) {
    AppLanguage.portuguese => 'Conexão em andamento',
    AppLanguage.english => 'Connection in progress',
    AppLanguage.spanish => 'Conexión en curso',
  };

  String get whatsappPendingMessage => switch (language) {
    AppLanguage.portuguese =>
      'Estamos aguardando a confirmação dessa conexão. Isso pode levar '
          'alguns minutos.',
    AppLanguage.english =>
      "We're waiting for this connection to be confirmed. This can take "
          'a few minutes.',
    AppLanguage.spanish =>
      'Estamos esperando la confirmación de esta conexión. Esto puede '
          'tardar unos minutos.',
  };

  String get refreshStatusButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Atualizar status',
    AppLanguage.english => 'Refresh status',
    AppLanguage.spanish => 'Actualizar estado',
  };

  String get whatsappConnectedStatusLabel => switch (language) {
    AppLanguage.portuguese => 'Conectado',
    AppLanguage.english => 'Connected',
    AppLanguage.spanish => 'Conectado',
  };

  String get connectedPhoneNumberLabel => switch (language) {
    AppLanguage.portuguese => 'Número conectado',
    AppLanguage.english => 'Connected number',
    AppLanguage.spanish => 'Número conectado',
  };

  String whatsappConnectedSinceLabel(String date) => switch (language) {
    AppLanguage.portuguese => 'Conectado desde $date',
    AppLanguage.english => 'Connected since $date',
    AppLanguage.spanish => 'Conectado desde $date',
  };

  String get whatsappDisconnectedTitle => switch (language) {
    AppLanguage.portuguese => 'WhatsApp desconectado',
    AppLanguage.english => 'WhatsApp disconnected',
    AppLanguage.spanish => 'WhatsApp desconectado',
  };

  String whatsappDisconnectedSinceLabel(String date) => switch (language) {
    AppLanguage.portuguese => 'Desconectado em $date',
    AppLanguage.english => 'Disconnected on $date',
    AppLanguage.spanish => 'Desconectado el $date',
  };

  String get whatsappConnectionErrorMessage => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível concluir a conexão com o WhatsApp.',
    AppLanguage.english => 'The WhatsApp connection could not be completed.',
    AppLanguage.spanish => 'No fue posible completar la conexión con WhatsApp.',
  };

  String get whatsappLoadErrorMessage => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível carregar o status da conexão com o WhatsApp.',
    AppLanguage.english => "Couldn't load the WhatsApp connection status.",
    AppLanguage.spanish =>
      'No fue posible cargar el estado de la conexión con WhatsApp.',
  };

  String get retryButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Tentar novamente',
    AppLanguage.english => 'Try again',
    AppLanguage.spanish => 'Intentar de nuevo',
  };

  String get backButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Voltar',
    AppLanguage.english => 'Back',
    AppLanguage.spanish => 'Volver',
  };
}
