import 'package:la_pelve/core/l10n/app_language.dart';

/// Textos do indicador e da central de sincronização (pt/en/es).
///
/// Regra de redação: "salvo neste dispositivo" nunca é apresentado como
/// "salvo no servidor"; nenhuma mensagem contém dado clínico.
class SyncStrings {
  const SyncStrings(this.language);

  final AppLanguage language;

  String _t(String pt, String en, String es) => switch (language) {
    AppLanguage.portuguese => pt,
    AppLanguage.english => en,
    AppLanguage.spanish => es,
  };

  String offline(int pending) => pending > 0
      ? _t(
          'Sem internet — suas alterações estão salvas neste dispositivo.',
          'No internet — your changes are saved on this device.',
          'Sin internet: tus cambios están guardados en este dispositivo.',
        )
      : _t(
          'Sem internet — mostrando os dados já sincronizados.',
          'No internet — showing the data already synced.',
          'Sin internet: mostrando los datos ya sincronizados.',
        );

  String pending(int n) => n == 1
      ? _t(
          '1 alteração aguardando sincronização.',
          '1 change waiting to sync.',
          '1 cambio esperando sincronización.',
        )
      : _t(
          '$n alterações aguardando sincronização.',
          '$n changes waiting to sync.',
          '$n cambios esperando sincronización.',
        );

  String get syncing => _t(
    'Sincronizando suas alterações…',
    'Syncing your changes…',
    'Sincronizando tus cambios…',
  );

  String get synced => _t(
    'Todos os dados sincronizados.',
    'All data synced.',
    'Todos los datos sincronizados.',
  );

  String error(int n) => n == 1
      ? _t(
          '1 alteração não pôde ser sincronizada. Toque para ver.',
          '1 change could not be synced. Tap to review.',
          '1 cambio no pudo sincronizarse. Toca para ver.',
        )
      : _t(
          '$n alterações não puderam ser sincronizadas. Toque para ver.',
          '$n changes could not be synced. Tap to review.',
          '$n cambios no pudieron sincronizarse. Toca para ver.',
        );

  String conflict(int n) => n == 1
      ? _t(
          '1 conflito precisa da sua decisão. Toque para resolver.',
          '1 conflict needs your decision. Tap to resolve.',
          '1 conflicto necesita tu decisión. Toca para resolver.',
        )
      : _t(
          '$n conflitos precisam da sua decisão. Toque para resolver.',
          '$n conflicts need your decision. Tap to resolve.',
          '$n conflictos necesitan tu decisión. Toca para resolver.',
        );

  String get savedOnDevice => _t(
    'Salvo neste dispositivo. Será enviado ao servidor quando houver conexão.',
    'Saved on this device. It will be sent to the server when a connection '
        'is available.',
    'Guardado en este dispositivo. Se enviará al servidor cuando haya '
        'conexión.',
  );

  String get onlineStepsPending => _t(
    'Paciente salvo neste dispositivo. Anexos e consentimento de WhatsApp '
        'precisam de internet: edite o paciente quando estiver online.',
    'Patient saved on this device. Attachments and WhatsApp consent need '
        'internet: edit the patient when you are online.',
    'Paciente guardado en este dispositivo. Los adjuntos y el '
        'consentimiento de WhatsApp necesitan internet: edita al paciente '
        'cuando estés en línea.',
  );

  String get consentNeedsInternet => _t(
    'Sem internet: o consentimento de WhatsApp não pode ser alterado agora e '
        'será mantido como está.',
    'No internet: WhatsApp consent cannot be changed now and will stay as '
        'it is.',
    'Sin internet: el consentimiento de WhatsApp no se puede cambiar ahora y '
        'se mantendrá como está.',
  );

  // --- central de sincronização -------------------------------------------

  String get centerTitle => _t(
    'Sincronização',
    'Synchronization',
    'Sincronización',
  );

  String get syncNow => _t('Sincronizar agora', 'Sync now', 'Sincronizar ahora');

  String get centerExplain => _t(
    'Suas alterações são salvas primeiro neste dispositivo e enviadas ao '
        'servidor quando houver conexão. Até lá, elas existem só aqui.',
    'Your changes are saved on this device first and sent to the server '
        'when a connection is available. Until then, they exist only here.',
    'Tus cambios se guardan primero en este dispositivo y se envían al '
        'servidor cuando hay conexión. Hasta entonces, existen solo aquí.',
  );

  String get conflictsTitle =>
      _t('Conflitos', 'Conflicts', 'Conflictos');

  String get failuresTitle => _t(
    'Alterações com erro',
    'Changes with errors',
    'Cambios con error',
  );

  String get nothingToReview => _t(
    'Nada pendente de revisão.',
    'Nothing to review.',
    'Nada pendiente de revisión.',
  );

  String get retry => _t('Tentar de novo', 'Try again', 'Reintentar');

  String get discard => _t(
    'Descartar alteração',
    'Discard change',
    'Descartar cambio',
  );

  String get discardConfirm => _t(
    'A alteração feita neste dispositivo será descartada e o registro volta '
        'à versão do servidor.',
    'The change made on this device will be discarded and the record goes '
        'back to the server version.',
    'El cambio hecho en este dispositivo se descartará y el registro vuelve '
        'a la versión del servidor.',
  );

  String get lastSync => _t(
    'Última sincronização',
    'Last sync',
    'Última sincronización',
  );

  String get never => _t('ainda não', 'not yet', 'todavía no');

  String get errorServer => _t(
    'O servidor recusou esta alteração.',
    'The server rejected this change.',
    'El servidor rechazó este cambio.',
  );

  // --- resolução de conflito ----------------------------------------------

  String get conflictIntro => _t(
    'Este registro foi alterado em outro lugar enquanto você o editava '
        'neste dispositivo. Nada foi sobrescrito: escolha qual versão manter.',
    'This record was changed elsewhere while you were editing it on this '
        'device. Nothing was overwritten: choose which version to keep.',
    'Este registro se modificó en otro lugar mientras lo editabas en este '
        'dispositivo. Nada se sobrescribió: elige qué versión conservar.',
  );

  String get thisDevice => _t('Neste dispositivo', 'This device', 'Este dispositivo');

  String get onServer => _t('No servidor', 'On the server', 'En el servidor');

  String get deletedOnServer => _t(
    'Este registro foi apagado no servidor.',
    'This record was deleted on the server.',
    'Este registro se eliminó en el servidor.',
  );

  String get keepMine => _t(
    'Manter a minha versão',
    'Keep my version',
    'Conservar mi versión',
  );

  String get keepServer => _t(
    'Manter a do servidor',
    'Keep the server version',
    'Conservar la del servidor',
  );

  String get keepBoth => _t(
    'Manter as duas (salvar a minha como novo registro)',
    'Keep both (save mine as a new record)',
    'Conservar ambas (guardar la mía como nuevo registro)',
  );

  String get empty => _t('(vazio)', '(empty)', '(vacío)');

  String kindLabel(String kind) => switch (kind) {
    'patients' => _t('Paciente', 'Patient', 'Paciente'),
    'appointments' => _t('Consulta', 'Appointment', 'Consulta'),
    'evolution_entries' => _t('Evolução', 'Progress note', 'Evolución'),
    'financial_entries' => _t(
      'Lançamento financeiro',
      'Financial entry',
      'Movimiento financiero',
    ),
    _ => kind,
  };

  String fieldLabel(String key) => switch (key) {
    'name' => _t('Nome', 'Name', 'Nombre'),
    'social_name' => _t('Nome social', 'Social name', 'Nombre social'),
    'phone' => _t('Telefone', 'Phone', 'Teléfono'),
    'age' => _t('Idade', 'Age', 'Edad'),
    'occupation' => _t('Profissão', 'Occupation', 'Profesión'),
    'description' => _t('Descrição', 'Description', 'Descripción'),
    'date' => _t('Data', 'Date', 'Fecha'),
    'time' => _t('Hora', 'Time', 'Hora'),
    'status' => 'Status',
    'amount' => _t('Valor', 'Amount', 'Valor'),
    'notes' => _t('Observações', 'Notes', 'Observaciones'),
    'patient_name' => _t('Paciente', 'Patient', 'Paciente'),
    'consultation_fee' => _t(
      'Valor da consulta',
      'Consultation fee',
      'Valor de la consulta',
    ),
    _ => key,
  };

  // --- logout --------------------------------------------------------------

  String signOutUnsynced(int n) => _t(
    'Há $n alteração(ões) que ainda não chegaram ao servidor. Sair agora '
        'APAGA essas alterações deste aparelho. Conecte-se e aguarde a '
        'sincronização antes de sair.',
    'There are $n change(s) that have not reached the server yet. Signing '
        'out now ERASES them from this device. Connect and wait for the sync '
        'before signing out.',
    'Hay $n cambio(s) que aún no llegaron al servidor. Salir ahora los '
        'BORRA de este dispositivo. Conéctate y espera la sincronización '
        'antes de salir.',
  );
}
