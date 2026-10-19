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
      'Sua conta não tem pacientes nem outros registros. Ao continuar, a conta '
          'e o acesso ao aplicativo serão apagados definitivamente. Não há como '
          'desfazer.',
    AppLanguage.english =>
      'Your account has no patients or other records. By continuing, the '
          'account and app access will be permanently deleted. This cannot be '
          'undone.',
    AppLanguage.spanish =>
      'Tu cuenta no tiene pacientes ni otros registros. Al continuar, la '
          'cuenta y el acceso a la app se eliminarán definitivamente. No se '
          'puede deshacer.',
  };

  // ----- Exclusão definitiva de todos os dados (30 dias para desistir) -----
  String get dataDeletionTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir todos os meus dados',
    AppLanguage.english => 'Delete all my data',
    AppLanguage.spanish => 'Eliminar todos mis datos',
  };

  String get dataDeletionDescription => switch (language) {
    AppLanguage.portuguese =>
      'Sua conta tem pacientes, prontuários e outros registros. Se continuar, '
          'TUDO será apagado definitivamente: pacientes (inclusive os já '
          'removidos da lista), anamneses, evoluções, agenda, financeiro, '
          'consentimentos, fotos e documentos.\n\n'
          'Você tem 30 dias para desistir: entre de novo no app e toque em '
          'Restaurar. Depois disso não há como recuperar. Os lembretes de '
          'WhatsApp são pausados agora.\n\n'
          'Prontuários podem ter prazo legal de guarda. A responsabilidade por '
          'guardar uma cópia é sua: exporte antes.',
    AppLanguage.english =>
      'Your account has patients, medical records and other data. If you '
          'continue, EVERYTHING will be permanently erased: patients (including '
          'those already removed from the list), medical histories, '
          'evolutions, agenda, finances, consents, photos and documents.\n\n'
          'You have 30 days to change your mind: sign in again and tap '
          'Restore. After that it cannot be recovered. WhatsApp reminders are '
          'paused now.\n\n'
          'Medical records may have a legal retention period. Keeping a copy '
          'is your responsibility: export first.',
    AppLanguage.spanish =>
      'Tu cuenta tiene pacientes, historias clínicas y otros registros. Si '
          'continúas, TODO se borrará definitivamente: pacientes (incluso los '
          'ya quitados de la lista), anamnesis, evoluciones, agenda, finanzas, '
          'consentimientos, fotos y documentos.\n\n'
          'Tienes 30 días para arrepentirte: entra de nuevo en la app y toca '
          'Restaurar. Después no hay forma de recuperar. Los recordatorios de '
          'WhatsApp se pausan ahora.\n\n'
          'Las historias clínicas pueden tener un plazo legal de conservación. '
          'Guardar una copia es responsabilidad tuya: exporta antes.',
  };

  String get dataDeletionTypeToConfirm => switch (language) {
    AppLanguage.portuguese => 'Para confirmar, digite EXCLUIR',
    AppLanguage.english => 'To confirm, type DELETE',
    AppLanguage.spanish => 'Para confirmar, escribe ELIMINAR',
  };

  /// Palavra que a pessoa precisa digitar (sem diferenciar maiúsculas).
  String get dataDeletionKeyword => switch (language) {
    AppLanguage.portuguese => 'EXCLUIR',
    AppLanguage.english => 'DELETE',
    AppLanguage.spanish => 'ELIMINAR',
  };

  String get dataDeletionExportFirst => switch (language) {
    AppLanguage.portuguese => 'Exportar meus dados primeiro',
    AppLanguage.english => 'Export my data first',
    AppLanguage.spanish => 'Exportar mis datos primero',
  };

  String get dataDeletionConfirmLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir tudo em 30 dias',
    AppLanguage.english => 'Delete everything in 30 days',
    AppLanguage.spanish => 'Eliminar todo en 30 días',
  };

  String dataDeletionScheduledDone(DateTime purgeAfter) => switch (language) {
    AppLanguage.portuguese =>
      'Exclusão agendada para ${formatDate(purgeAfter)}. Até lá você pode '
          'entrar e restaurar a conta.',
    AppLanguage.english =>
      'Deletion scheduled for ${formatDate(purgeAfter)}. Until then you '
          'can sign in and restore the account.',
    AppLanguage.spanish =>
      'Eliminación programada para ${formatDate(purgeAfter)}. Hasta '
          'entonces puedes entrar y restaurar la cuenta.',
  };

  String get scheduledPageTitle => switch (language) {
    AppLanguage.portuguese => 'Exclusão agendada',
    AppLanguage.english => 'Deletion scheduled',
    AppLanguage.spanish => 'Eliminación programada',
  };

  String scheduledPageBody(DateTime purgeAfter) => switch (language) {
    AppLanguage.portuguese =>
      'Todos os dados desta conta serão apagados definitivamente em '
          '${formatDate(purgeAfter)}. Se foi engano, restaure agora: nada '
          'será perdido. Os lembretes de WhatsApp foram pausados e podem '
          'precisar ser reconectados.',
    AppLanguage.english =>
      'All data in this account will be permanently erased on '
          '${formatDate(purgeAfter)}. If this was a mistake, restore now: '
          'nothing will be lost. WhatsApp reminders were paused and may need '
          'to be reconnected.',
    AppLanguage.spanish =>
      'Todos los datos de esta cuenta se borrarán definitivamente el '
          '${formatDate(purgeAfter)}. Si fue un error, restaura ahora: no se '
          'perderá nada. Los recordatorios de WhatsApp se pausaron y quizá '
          'haya que reconectarlos.',
  };

  String get restoreAccountLabel => switch (language) {
    AppLanguage.portuguese => 'Restaurar minha conta',
    AppLanguage.english => 'Restore my account',
    AppLanguage.spanish => 'Restaurar mi cuenta',
  };

  String get restoreFailedMessage => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível restaurar agora. Verifique a conexão e tente de novo.',
    AppLanguage.english =>
      'Could not restore right now. Check your connection and try again.',
    AppLanguage.spanish =>
      'No se pudo restaurar ahora. Revisa la conexión e inténtalo de nuevo.',
  };

  String get dataDeletionFailedMessage => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível agendar a exclusão. Nada foi apagado. Tente de novo.',
    AppLanguage.english =>
      'Could not schedule the deletion. Nothing was deleted. Try again.',
    AppLanguage.spanish =>
      'No se pudo programar la eliminación. No se borró nada. Inténtalo de nuevo.',
  };

  static String formatDate(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }

  String get exportRowLabel => switch (language) {
    AppLanguage.portuguese => 'Exportar meus dados',
    AppLanguage.english => 'Export my data',
    AppLanguage.spanish => 'Exportar mis datos',
  };

  String get exportConfirmDescription => switch (language) {
    AppLanguage.portuguese =>
      'Gera um pacote ZIP com pacientes, anamneses, evoluções, agenda, '
          'financeiro, consentimentos e todos os anexos originais, com uma '
          'lista de conferência. Pode demorar e usar bastante dados. O arquivo '
          'contém dados sensíveis de saúde: guarde em local seguro.',
    AppLanguage.english =>
      'Creates a ZIP package with patients, medical histories, evolutions, '
          'agenda, financial entries, consents and all original attachments, '
          'with a checklist. It may take a while and use a lot of data. The '
          'file holds sensitive health data: keep it somewhere safe.',
    AppLanguage.spanish =>
      'Genera un paquete ZIP con pacientes, anamnesis, evoluciones, agenda, '
          'finanzas, consentimientos y todos los adjuntos originales, con una '
          'lista de verificación. Puede tardar y usar muchos datos. El archivo '
          'contiene datos sensibles de salud: guárdalo en un lugar seguro.',
  };

  String get exportConfirmLabel => switch (language) {
    AppLanguage.portuguese => 'Exportar',
    AppLanguage.english => 'Export',
    AppLanguage.spanish => 'Exportar',
  };

  String get exportDoneDescription => switch (language) {
    AppLanguage.portuguese =>
      'O pacote foi gerado, conferido e entregue ao sistema para salvar. '
          'Confira que o arquivo está no local escolhido e guarde uma cópia '
          'segura. Isso não substitui a orientação sobre a guarda legal dos '
          'prontuários.',
    AppLanguage.english =>
      'The package was generated, verified and handed to the system to save. '
          'Check that the file is where you chose and keep a safe copy. This '
          'does not replace guidance on the legal retention of records.',
    AppLanguage.spanish =>
      'El paquete se generó, verificó y entregó al sistema para guardarlo. '
          'Comprueba que el archivo está donde elegiste y guarda una copia '
          'segura. Esto no sustituye la orientación sobre la conservación '
          'legal de las historias clínicas.',
  };

  String get exportPendingSyncMessage => switch (language) {
    AppLanguage.portuguese =>
      'Há alterações neste aparelho que ainda não foram enviadas. Conecte-se '
          'à internet, aguarde a sincronização terminar e tente de novo.',
    AppLanguage.english =>
      'There are changes on this device not yet uploaded. Connect to the '
          'internet, wait for sync to finish and try again.',
    AppLanguage.spanish =>
      'Hay cambios en este dispositivo que aún no se enviaron. Conéctate a '
          'internet, espera a que termine la sincronización e inténtalo de '
          'nuevo.',
  };

  String get exportIncompleteMessage => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível gerar um pacote completo e conferido, então nenhum '
          'arquivo foi salvo. Seus dados não foram alterados. Tente novamente '
          'com boa conexão; se persistir, fale com o suporte (marketing@lucksrei.com).',
    AppLanguage.english =>
      'We could not produce a complete, verified package, so no file was '
          'saved. Your data was not changed. Try again with a good connection; '
          'if it persists, contact support (marketing@lucksrei.com).',
    AppLanguage.spanish =>
      'No se pudo generar un paquete completo y verificado, así que no se '
          'guardó ningún archivo. Tus datos no cambiaron. Inténtalo de nuevo '
          'con buena conexión; si persiste, contacta al soporte (marketing@lucksrei.com).',
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
    AppLanguage.portuguese => 'Lembretes e confirmações',
    AppLanguage.english => 'Reminders and confirmations',
    AppLanguage.spanish => 'Recordatorios y confirmaciones',
  };

  String get connectWhatsappButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Conectar WhatsApp',
    AppLanguage.english => 'Connect WhatsApp',
    AppLanguage.spanish => 'Conectar WhatsApp',
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

  String get clinicWhatsappTitle => switch (language) {
    AppLanguage.portuguese => 'WhatsApp da clínica',
    AppLanguage.english => "Clinic's WhatsApp",
    AppLanguage.spanish => 'WhatsApp de la clínica',
  };

  String get whatsappIntroMessage => switch (language) {
    AppLanguage.portuguese =>
      'Conecte o WhatsApp da sua clínica para automatizar a comunicação com '
          'suas pacientes.',
    AppLanguage.english =>
      "Connect your clinic's WhatsApp to automate communication with your "
          'patients.',
    AppLanguage.spanish =>
      'Conecta el WhatsApp de tu clínica para automatizar la comunicación '
          'con tus pacientes.',
  };

  String get whatsappBenefitReminders => switch (language) {
    AppLanguage.portuguese => 'Lembretes automáticos de consultas',
    AppLanguage.english => 'Automatic appointment reminders',
    AppLanguage.spanish => 'Recordatorios automáticos de citas',
  };

  String get whatsappBenefitConfirmation => switch (language) {
    AppLanguage.portuguese => 'Confirmação de atendimento pelo WhatsApp',
    AppLanguage.english => 'Appointment confirmation via WhatsApp',
    AppLanguage.spanish => 'Confirmación de la cita por WhatsApp',
  };

  String get whatsappBenefitAgendaSync => switch (language) {
    AppLanguage.portuguese =>
      'Atualização automática da agenda após a confirmação',
    AppLanguage.english => 'Schedule updated automatically after confirmation',
    AppLanguage.spanish =>
      'Actualización automática de la agenda tras la confirmación',
  };

  String get whatsappStatusInSetup => switch (language) {
    AppLanguage.portuguese => 'Em configuração',
    AppLanguage.english => 'Being set up',
    AppLanguage.spanish => 'En configuración',
  };

  String get whatsappStatusPending => switch (language) {
    AppLanguage.portuguese => 'Em andamento',
    AppLanguage.english => 'In progress',
    AppLanguage.spanish => 'En curso',
  };

  String get whatsappStatusDisconnected => switch (language) {
    AppLanguage.portuguese => 'Desconectado',
    AppLanguage.english => 'Disconnected',
    AppLanguage.spanish => 'Desconectado',
  };

  String get whatsappStatusError => switch (language) {
    AppLanguage.portuguese => 'Erro na conexão',
    AppLanguage.english => 'Connection error',
    AppLanguage.spanish => 'Error de conexión',
  };

  String get whatsappPreparingTitle => switch (language) {
    AppLanguage.portuguese => 'Integração em preparação',
    AppLanguage.english => 'Integration in preparation',
    AppLanguage.spanish => 'Integración en preparación',
  };

  String get whatsappPreparingMessage => switch (language) {
    AppLanguage.portuguese =>
      'Estamos finalizando a configuração para que você possa conectar o '
          'número da sua clínica com segurança.',
    AppLanguage.english =>
      "We're finishing the setup so you can safely connect your clinic's "
          'number.',
    AppLanguage.spanish =>
      'Estamos terminando la configuración para que puedas conectar el '
          'número de tu clínica con seguridad.',
  };

  String get comingSoonBadge => switch (language) {
    AppLanguage.portuguese => 'Em breve',
    AppLanguage.english => 'Coming soon',
    AppLanguage.spanish => 'Próximamente',
  };

  String get whatsappCheckingStatus => switch (language) {
    AppLanguage.portuguese => 'Verificando a conexão…',
    AppLanguage.english => 'Checking the connection…',
    AppLanguage.spanish => 'Verificando la conexión…',
  };

  String get whatsappConnectingTitle => switch (language) {
    AppLanguage.portuguese => 'Finalize a conexão na Meta',
    AppLanguage.english => 'Finish the connection on Meta',
    AppLanguage.spanish => 'Finaliza la conexión en Meta',
  };

  String get whatsappConnectingMessage => switch (language) {
    AppLanguage.portuguese =>
      'Autorize o seu número na janela da Meta. Quando terminar, volte aqui '
          'e toque em "Atualizar status".',
    AppLanguage.english =>
      'Authorize your number in the Meta window. When you are done, come '
          'back here and tap "Refresh status".',
    AppLanguage.spanish =>
      'Autoriza tu número en la ventana de Meta. Al terminar, vuelve aquí y '
          'toca "Actualizar estado".',
  };

  String get whatsappStatusConnecting => switch (language) {
    AppLanguage.portuguese => 'Conectando',
    AppLanguage.english => 'Connecting',
    AppLanguage.spanish => 'Conectando',
  };

  String get whatsappStartFailedMessage => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível iniciar a conexão. Tente novamente em instantes.',
    AppLanguage.english =>
      "We couldn't start the connection. Please try again shortly.",
    AppLanguage.spanish =>
      'No fue posible iniciar la conexión. Inténtalo de nuevo en unos '
          'instantes.',
  };

  String get disconnectWhatsappButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Desconectar',
    AppLanguage.english => 'Disconnect',
    AppLanguage.spanish => 'Desconectar',
  };

  String get disconnectWhatsappDialogTitle => switch (language) {
    AppLanguage.portuguese => 'Desconectar o WhatsApp?',
    AppLanguage.english => 'Disconnect WhatsApp?',
    AppLanguage.spanish => '¿Desconectar WhatsApp?',
  };

  String get disconnectWhatsappDialogMessage => switch (language) {
    AppLanguage.portuguese =>
      'Os lembretes e avisos deixarão de ser enviados. Você pode conectar '
          'novamente depois.',
    AppLanguage.english =>
      'Reminders and notices will stop being sent. You can connect again '
          'later.',
    AppLanguage.spanish =>
      'Los recordatorios y avisos dejarán de enviarse. Puedes conectar de '
          'nuevo después.',
  };

  String get cancelButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Cancelar',
    AppLanguage.english => 'Cancel',
    AppLanguage.spanish => 'Cancelar',
  };

  String get whatsappDisconnectFailedMessage => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível desconectar. A conexão continua ativa.',
    AppLanguage.english =>
      "We couldn't disconnect. The connection is still active.",
    AppLanguage.spanish =>
      'No fue posible desconectar. La conexión sigue activa.',
  };

  /// Motivo da pendência/erro vindo de `whatsapp_connections.last_error.code`.
  /// null = sem texto específico (usa a mensagem genérica).
  String? whatsappReasonMessage(String? code) {
    const known = {
      'templates_pending',
      'templates_rejected',
      'webhook_subscription_failed',
      'phone_pin_required',
      'phone_registration_rate_limited',
      'phone_registration_retry_later',
      'phone_registration_failed',
      'phone_not_connected',
      'account_limited',
      'account_blocked',
      'account_restricted',
      'account_disabled',
      'credential_store_failed',
      'credential_missing',
      'revoked_by_meta',
      'token_invalid',
    };
    if (code == null || !known.contains(code)) return null;
    return switch (language) {
      AppLanguage.portuguese => switch (code) {
        'templates_pending' =>
          'Aguardando a Meta aprovar os modelos de mensagem. Isso pode levar '
              'algumas horas.',
        'templates_rejected' =>
          'A Meta recusou um dos modelos de mensagem. Fale com o suporte.',
        'webhook_subscription_failed' =>
          'Não conseguimos ativar o recebimento das confirmações. Toque em '
              '"Atualizar status" para tentar de novo.',
        'phone_pin_required' =>
          'Este número já usa verificação em duas etapas. É preciso o PIN '
              'existente para concluir; fale com o suporte.',
        'phone_registration_rate_limited' =>
          'O registro do número atingiu o limite da Meta. Tente novamente em '
              'até 72 horas.',
        'phone_registration_retry_later' =>
          'A ativação do número está em andamento. Aguarde alguns minutos e '
              'toque em "Atualizar status".',
        'phone_registration_failed' || 'phone_not_connected' =>
          'O número ainda não está ativo na API do WhatsApp. Toque em '
              '"Atualizar status" para tentar de novo.',
        'credential_store_failed' || 'credential_missing' =>
          'Não foi possível guardar a autorização com segurança. Conecte '
              'novamente.',
        'revoked_by_meta' => 'A Meta encerrou a autorização desta conexão.',
        'token_invalid' =>
          'A autorização da Meta venceu ou foi revogada. Reconecte para voltar '
              'a enviar os lembretes.',
        _ =>
          'A conta do WhatsApp Business está com restrição na Meta. Verifique '
              'o WhatsApp Manager.',
      },
      AppLanguage.english => switch (code) {
        'templates_pending' =>
          'Waiting for Meta to approve the message templates. This can take '
              'a few hours.',
        'templates_rejected' =>
          'Meta rejected one of the message templates. Please contact '
              'support.',
        'webhook_subscription_failed' =>
          "We couldn't enable confirmation replies. Tap 'Refresh status' "
              'to try again.',
        'phone_pin_required' =>
          'This number already uses two-step verification. The existing PIN '
              'is required to finish; please contact support.',
        'phone_registration_rate_limited' =>
          "The number's registration hit Meta's limit. Try again within 72 "
              'hours.',
        'phone_registration_retry_later' =>
          "The number's activation is in progress. Wait a few minutes and "
              "tap 'Refresh status'.",
        'phone_registration_failed' || 'phone_not_connected' =>
          "The number is not active on the WhatsApp API yet. Tap 'Refresh "
              "status' to try again.",
        'credential_store_failed' || 'credential_missing' =>
          "We couldn't store the authorization securely. Please connect "
              'again.',
        'revoked_by_meta' =>
          'Meta ended the authorization for this connection.',
        'token_invalid' =>
          'The Meta authorization expired or was revoked. Reconnect to resume '
              'sending reminders.',
        _ =>
          'The WhatsApp Business account is restricted by Meta. Check '
              'WhatsApp Manager.',
      },
      AppLanguage.spanish => switch (code) {
        'templates_pending' =>
          'Esperando que Meta apruebe las plantillas de mensajes. Puede '
              'tardar algunas horas.',
        'templates_rejected' =>
          'Meta rechazó una de las plantillas de mensajes. Habla con '
              'soporte.',
        'webhook_subscription_failed' =>
          'No pudimos activar la recepción de confirmaciones. Toca '
              "'Actualizar estado' para intentarlo de nuevo.",
        'phone_pin_required' =>
          'Este número ya usa verificación en dos pasos. Se necesita el PIN '
              'existente para terminar; habla con soporte.',
        'phone_registration_rate_limited' =>
          'El registro del número alcanzó el límite de Meta. Inténtalo de '
              'nuevo en hasta 72 horas.',
        'phone_registration_retry_later' =>
          'La activación del número está en curso. Espera unos minutos y '
              "toca 'Actualizar estado'.",
        'phone_registration_failed' || 'phone_not_connected' =>
          'El número aún no está activo en la API de WhatsApp. Toca '
              "'Actualizar estado' para intentarlo de nuevo.",
        'credential_store_failed' || 'credential_missing' =>
          'No se pudo guardar la autorización de forma segura. Conecta de '
              'nuevo.',
        'revoked_by_meta' => 'Meta finalizó la autorización de esta conexión.',
        'token_invalid' =>
          'La autorización de Meta venció o fue revocada. Reconecta para volver '
              'a enviar los recordatorios.',
        _ =>
          'La cuenta de WhatsApp Business tiene una restricción en Meta. '
              'Revisa WhatsApp Manager.',
      },
    };
  }

  String get whatsappStatusTokenExpiring => switch (language) {
    AppLanguage.portuguese => 'Autorização vencendo',
    AppLanguage.english => 'Authorization expiring',
    AppLanguage.spanish => 'Autorización por vencer',
  };

  String get whatsappStatusTokenExpired => switch (language) {
    AppLanguage.portuguese => 'Autorização vencida',
    AppLanguage.english => 'Authorization expired',
    AppLanguage.spanish => 'Autorización vencida',
  };

  /// [date] já formatada.
  String whatsappTokenValidUntil(String date) => switch (language) {
    AppLanguage.portuguese => 'Autorização da Meta válida até $date.',
    AppLanguage.english => 'Meta authorization valid until $date.',
    AppLanguage.spanish => 'Autorización de Meta válida hasta $date.',
  };

  String get whatsappStatusStaleNotice => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível atualizar o status agora (verifique a internet). '
          'Mostrando o último estado salvo.',
    AppLanguage.english =>
      "We couldn't refresh the status right now (check your connection). "
          'Showing the last saved state.',
    AppLanguage.spanish =>
      'No fue posible actualizar el estado ahora (revisa tu conexión). '
          'Mostrando el último estado guardado.',
  };

  String get whatsappReconnectButtonLabel => switch (language) {
    AppLanguage.portuguese => 'Reconectar',
    AppLanguage.english => 'Reconnect',
    AppLanguage.spanish => 'Reconectar',
  };

  /// [date] já formatada (a autorização da Meta vence nesse dia).
  String whatsappTokenExpiringMessage(String date) => switch (language) {
    AppLanguage.portuguese =>
      'A autorização da Meta vence em $date. Reconecte antes disso para não '
          'interromper os lembretes.',
    AppLanguage.english =>
      'The Meta authorization expires on $date. Reconnect before then so '
          'reminders are not interrupted.',
    AppLanguage.spanish =>
      'La autorización de Meta vence el $date. Reconecta antes para no '
          'interrumpir los recordatorios.',
  };

  String get whatsappBillingNote => switch (language) {
    AppLanguage.portuguese =>
      'Confirme a forma de pagamento no WhatsApp Manager para que as '
          'mensagens sejam entregues.',
    AppLanguage.english =>
      'Confirm your payment method in WhatsApp Manager so messages can be '
          'delivered.',
    AppLanguage.spanish =>
      'Confirma el método de pago en WhatsApp Manager para que los mensajes '
          'se entreguen.',
  };
}
