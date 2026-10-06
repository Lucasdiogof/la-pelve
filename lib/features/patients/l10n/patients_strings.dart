import 'package:la_pelve/core/l10n/app_language.dart';

class PatientsStrings {
  const PatientsStrings(this.language);

  final AppLanguage language;

  String get notInformed => switch (language) {
    AppLanguage.portuguese => 'Não informado',
    AppLanguage.english => 'Not informed',
    AppLanguage.spanish => 'No informado',
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

  String get newPatientButton => switch (language) {
    AppLanguage.portuguese => 'Novo paciente',
    AppLanguage.english => 'New patient',
    AppLanguage.spanish => 'Nuevo paciente',
  };

  String get listTitle => switch (language) {
    AppLanguage.portuguese => 'Pacientes',
    AppLanguage.english => 'Patients',
    AppLanguage.spanish => 'Pacientes',
  };

  String get listSubtitle => switch (language) {
    AppLanguage.portuguese => 'Gerencie seus pacientes',
    AppLanguage.english => 'Manage your patients',
    AppLanguage.spanish => 'Gestiona tus pacientes',
  };

  String patientCount(int count) => switch (language) {
    AppLanguage.portuguese => count == 1 ? '1 paciente' : '$count pacientes',
    AppLanguage.english => count == 1 ? '1 patient' : '$count patients',
    AppLanguage.spanish => count == 1 ? '1 paciente' : '$count pacientes',
  };

  String patientCountWithDischarged(
    int count,
    int discharged,
  ) => switch (language) {
    AppLanguage.portuguese => '${patientCount(count)} · $discharged com alta',
    AppLanguage.english => '${patientCount(count)} · $discharged discharged',
    AppLanguage.spanish => '${patientCount(count)} · $discharged con alta',
  };

  String get dischargedSectionTitle => switch (language) {
    AppLanguage.portuguese => 'Com alta',
    AppLanguage.english => 'Discharged',
    AppLanguage.spanish => 'Con alta',
  };

  String get emptyPatientsTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhum paciente cadastrado',
    AppLanguage.english => 'No patients registered',
    AppLanguage.spanish => 'Ningún paciente registrado',
  };

  String get emptyPatientsMessage => switch (language) {
    AppLanguage.portuguese => 'Toque em "Novo paciente" para começar.',
    AppLanguage.english => 'Tap "New patient" to get started.',
    AppLanguage.spanish => 'Toca en "Nuevo paciente" para empezar.',
  };

  String get noNamePlaceholder => switch (language) {
    AppLanguage.portuguese => 'Sem nome',
    AppLanguage.english => 'No name',
    AppLanguage.spanish => 'Sin nombre',
  };

  String get deletePatientTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir paciente',
    AppLanguage.english => 'Delete patient',
    AppLanguage.spanish => 'Eliminar paciente',
  };

  String get genericPatientLabel => switch (language) {
    AppLanguage.portuguese => 'este paciente',
    AppLanguage.english => 'this patient',
    AppLanguage.spanish => 'este paciente',
  };

  String deletePatientDescription(String name) => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja excluir $name? '
          'Essa ação não pode ser desfeita e também apaga as evoluções registradas.',
    AppLanguage.english =>
      'Are you sure you want to delete $name? '
          'This action cannot be undone and will also delete the recorded evolution entries.',
    AppLanguage.spanish =>
      '¿Seguro que deseas eliminar a $name? '
          'Esta acción no se puede deshacer y también eliminará las evoluciones registradas.',
  };

  String get deleteLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir',
    AppLanguage.english => 'Delete',
    AppLanguage.spanish => 'Eliminar',
  };

  String get editPatientTooltip => switch (language) {
    AppLanguage.portuguese => 'Editar paciente',
    AppLanguage.english => 'Edit patient',
    AppLanguage.spanish => 'Editar paciente',
  };

  String get deletePatientTooltip => switch (language) {
    AppLanguage.portuguese => 'Excluir paciente',
    AppLanguage.english => 'Delete patient',
    AppLanguage.spanish => 'Eliminar paciente',
  };

  String get reopenTreatmentTitle => switch (language) {
    AppLanguage.portuguese => 'Reabrir tratamento',
    AppLanguage.english => 'Reopen treatment',
    AppLanguage.spanish => 'Reabrir tratamiento',
  };

  String get reopenTreatmentDescription => switch (language) {
    AppLanguage.portuguese =>
      'Isso remove o encerramento atual e volta o tratamento para em andamento.',
    AppLanguage.english =>
      'This removes the current discharge and returns the treatment to in progress.',
    AppLanguage.spanish =>
      'Esto elimina el cierre actual y vuelve a dejar el tratamiento en curso.',
  };

  String get reopenLabel => switch (language) {
    AppLanguage.portuguese => 'Reabrir',
    AppLanguage.english => 'Reopen',
    AppLanguage.spanish => 'Reabrir',
  };

  String get treatmentClosedSuccess => switch (language) {
    AppLanguage.portuguese => 'Tratamento encerrado com sucesso.',
    AppLanguage.english => 'Treatment closed successfully.',
    AppLanguage.spanish => 'Tratamiento cerrado con éxito.',
  };

  String get treatmentReopenedSuccess => switch (language) {
    AppLanguage.portuguese => 'Tratamento reaberto com sucesso.',
    AppLanguage.english => 'Treatment reopened successfully.',
    AppLanguage.spanish => 'Tratamiento reabierto con éxito.',
  };

  String get patientFallbackTitle => switch (language) {
    AppLanguage.portuguese => 'Paciente',
    AppLanguage.english => 'Patient',
    AppLanguage.spanish => 'Paciente',
  };

  String get tabInformation => switch (language) {
    AppLanguage.portuguese => 'Informações',
    AppLanguage.english => 'Information',
    AppLanguage.spanish => 'Información',
  };

  String get tabAttachments => switch (language) {
    AppLanguage.portuguese => 'Anexos',
    AppLanguage.english => 'Attachments',
    AppLanguage.spanish => 'Adjuntos',
  };

  String get sectionPersonalData => switch (language) {
    AppLanguage.portuguese => 'Dados pessoais',
    AppLanguage.english => 'Personal data',
    AppLanguage.spanish => 'Datos personales',
  };

  String get fieldSocialName => switch (language) {
    AppLanguage.portuguese => 'Nome social',
    AppLanguage.english => 'Social name',
    AppLanguage.spanish => 'Nombre social',
  };

  String get fieldSex => switch (language) {
    AppLanguage.portuguese => 'Sexo',
    AppLanguage.english => 'Sex',
    AppLanguage.spanish => 'Sexo',
  };

  String get fieldAge => switch (language) {
    AppLanguage.portuguese => 'Idade',
    AppLanguage.english => 'Age',
    AppLanguage.spanish => 'Edad',
  };

  String get fieldPhone => switch (language) {
    AppLanguage.portuguese => 'Telefone',
    AppLanguage.english => 'Phone',
    AppLanguage.spanish => 'Teléfono',
  };

  String get fieldOccupation => switch (language) {
    AppLanguage.portuguese => 'Profissão',
    AppLanguage.english => 'Occupation',
    AppLanguage.spanish => 'Profesión',
  };

  String get whatsappReminderFieldLabel => switch (language) {
    AppLanguage.portuguese => 'Lembretes pelo WhatsApp',
    AppLanguage.english => 'WhatsApp reminders',
    AppLanguage.spanish => 'Recordatorios por WhatsApp',
  };

  String get whatsappReminderInactive => switch (language) {
    AppLanguage.portuguese => 'desativados',
    AppLanguage.english => 'disabled',
    AppLanguage.spanish => 'desactivados',
  };

  String get whatsappReminderActive => switch (language) {
    AppLanguage.portuguese => 'ativados',
    AppLanguage.english => 'enabled',
    AppLanguage.spanish => 'activados',
  };

  String whatsappReminderActiveSince(String date) => switch (language) {
    AppLanguage.portuguese => 'ativados desde $date',
    AppLanguage.english => 'enabled since $date',
    AppLanguage.spanish => 'activados desde $date',
  };

  String get sectionConsultationFee => switch (language) {
    AppLanguage.portuguese => 'Valor da consulta',
    AppLanguage.english => 'Consultation fee',
    AppLanguage.spanish => 'Valor de la consulta',
  };

  String get sectionAssessmentForm => switch (language) {
    AppLanguage.portuguese => 'Ficha de avaliação física',
    AppLanguage.english => 'Physical assessment form',
    AppLanguage.spanish => 'Ficha de evaluación física',
  };

  String get fieldFirstConsultationFee => switch (language) {
    AppLanguage.portuguese => 'Valor da 1ª consulta',
    AppLanguage.english => 'First consultation fee',
    AppLanguage.spanish => 'Valor de la 1ª consulta',
  };

  String get closeTreatmentButton => switch (language) {
    AppLanguage.portuguese => 'Encerrar tratamento',
    AppLanguage.english => 'Close treatment',
    AppLanguage.spanish => 'Cerrar tratamiento',
  };

  String get viewEvolutionButton => switch (language) {
    AppLanguage.portuguese => 'Ver evolução',
    AppLanguage.english => 'View evolution',
    AppLanguage.spanish => 'Ver evolución',
  };

  String treatmentClosedOn(String date) => switch (language) {
    AppLanguage.portuguese => 'Tratamento encerrado em $date',
    AppLanguage.english => 'Treatment closed on $date',
    AppLanguage.spanish => 'Tratamiento cerrado el $date',
  };

  String reasonLabel(String reason) => switch (language) {
    AppLanguage.portuguese => 'Motivo: $reason',
    AppLanguage.english => 'Reason: $reason',
    AppLanguage.spanish => 'Motivo: $reason',
  };

  String pregnancyNumber(int number) => switch (language) {
    AppLanguage.portuguese => 'Gestação $number',
    AppLanguage.english => 'Pregnancy $number',
    AppLanguage.spanish => 'Embarazo $number',
  };

  String get fieldPregnancyLoss => switch (language) {
    AppLanguage.portuguese => 'Perda gestacional',
    AppLanguage.english => 'Pregnancy loss',
    AppLanguage.spanish => 'Pérdida gestacional',
  };

  String get fieldLossDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da perda',
    AppLanguage.english => 'Loss detail',
    AppLanguage.spanish => 'Detalle de la pérdida',
  };

  String get fieldDeliveryMethod => switch (language) {
    AppLanguage.portuguese => 'Via de parto',
    AppLanguage.english => 'Delivery method',
    AppLanguage.spanish => 'Vía de parto',
  };

  String get fieldDeliveryComplication => switch (language) {
    AppLanguage.portuguese => 'Complicação no parto',
    AppLanguage.english => 'Delivery complication',
    AppLanguage.spanish => 'Complicación en el parto',
  };

  String get fieldForcepsOrVacuum => switch (language) {
    AppLanguage.portuguese => 'Uso de fórceps ou vácuo',
    AppLanguage.english => 'Forceps or vacuum use',
    AppLanguage.spanish => 'Uso de fórceps o vacío',
  };

  String get fieldApproxBabyWeight => switch (language) {
    AppLanguage.portuguese => 'Peso aproximado do bebê',
    AppLanguage.english => 'Approximate baby weight',
    AppLanguage.spanish => 'Peso aproximado del bebé',
  };

  String get fieldHadComplications => switch (language) {
    AppLanguage.portuguese => 'Teve complicações',
    AppLanguage.english => 'Had complications',
    AppLanguage.spanish => 'Tuvo complicaciones',
  };

  String get fieldComplicationDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe das complicações',
    AppLanguage.english => 'Complication detail',
    AppLanguage.spanish => 'Detalle de las complicaciones',
  };

  String get newEvolutionButton => switch (language) {
    AppLanguage.portuguese => 'Nova evolução',
    AppLanguage.english => 'New evolution',
    AppLanguage.spanish => 'Nueva evolución',
  };

  String get evolutionPageTitle => switch (language) {
    AppLanguage.portuguese => 'Evolução',
    AppLanguage.english => 'Evolution',
    AppLanguage.spanish => 'Evolución',
  };

  String get evolutionPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Acompanhe a evolução do paciente',
    AppLanguage.english => "Track the patient's evolution",
    AppLanguage.spanish => 'Da seguimiento a la evolución del paciente',
  };

  String get evolutionEmptyTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhuma evolução registrada',
    AppLanguage.english => 'No evolution entries recorded',
    AppLanguage.spanish => 'Ninguna evolución registrada',
  };

  String get evolutionEmptyMessage => switch (language) {
    AppLanguage.portuguese => 'Toque em "Nova evolução" para começar.',
    AppLanguage.english => 'Tap "New evolution" to get started.',
    AppLanguage.spanish => 'Toca en "Nueva evolución" para empezar.',
  };

  String get deleteEvolutionTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir evolução',
    AppLanguage.english => 'Delete evolution',
    AppLanguage.spanish => 'Eliminar evolución',
  };

  String get deleteEvolutionDescription => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja excluir esta evolução? Essa ação não pode ser desfeita.',
    AppLanguage.english =>
      "Are you sure you want to delete this evolution entry? This can't be undone.",
    AppLanguage.spanish =>
      '¿Seguro que deseas eliminar esta evolución? Esta acción no se puede deshacer.',
  };

  String get deleteEvolutionTooltip => switch (language) {
    AppLanguage.portuguese => 'Excluir evolução',
    AppLanguage.english => 'Delete evolution',
    AppLanguage.spanish => 'Eliminar evolución',
  };

  String editedOn(String date) => switch (language) {
    AppLanguage.portuguese => 'Editado em $date',
    AppLanguage.english => 'Edited on $date',
    AppLanguage.spanish => 'Editado el $date',
  };

  String get editEvolutionTitle => switch (language) {
    AppLanguage.portuguese => 'Editar evolução',
    AppLanguage.english => 'Edit evolution',
    AppLanguage.spanish => 'Editar evolución',
  };

  String get newEvolutionTitle => switch (language) {
    AppLanguage.portuguese => 'Nova evolução',
    AppLanguage.english => 'New evolution',
    AppLanguage.spanish => 'Nueva evolución',
  };

  String get dateHint => switch (language) {
    AppLanguage.portuguese => 'Data',
    AppLanguage.english => 'Date',
    AppLanguage.spanish => 'Fecha',
  };

  String get evolutionDescriptionHint => switch (language) {
    AppLanguage.portuguese => 'O que foi feito no atendimento',
    AppLanguage.english => 'What was done during the session',
    AppLanguage.spanish => 'Qué se hizo en la sesión',
  };

  String get evolutionUpdatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Evolução atualizada com sucesso.',
    AppLanguage.english => 'Evolution updated successfully.',
    AppLanguage.spanish => 'Evolución actualizada con éxito.',
  };

  String get evolutionCreatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Evolução registrada com sucesso.',
    AppLanguage.english => 'Evolution recorded successfully.',
    AppLanguage.spanish => 'Evolución registrada con éxito.',
  };

  String get saveChangesLabel => switch (language) {
    AppLanguage.portuguese => 'Salvar alterações',
    AppLanguage.english => 'Save changes',
    AppLanguage.spanish => 'Guardar cambios',
  };

  String get saveLabel => switch (language) {
    AppLanguage.portuguese => 'Salvar',
    AppLanguage.english => 'Save',
    AppLanguage.spanish => 'Guardar',
  };

  String get attachmentAddedSuccess => switch (language) {
    AppLanguage.portuguese => 'Anexo adicionado com sucesso.',
    AppLanguage.english => 'Attachment added successfully.',
    AppLanguage.spanish => 'Adjunto añadido con éxito.',
  };

  String get cannotOpenFileError => switch (language) {
    AppLanguage.portuguese => 'Não foi possível abrir o arquivo.',
    AppLanguage.english => 'Could not open the file.',
    AppLanguage.spanish => 'No se pudo abrir el archivo.',
  };

  String get deleteAttachmentTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir anexo',
    AppLanguage.english => 'Delete attachment',
    AppLanguage.spanish => 'Eliminar adjunto',
  };

  String deleteAttachmentDescription(String category) => switch (language) {
    AppLanguage.portuguese =>
      'Excluir este $category? Essa ação não pode ser desfeita.',
    AppLanguage.english =>
      'Delete this $category? This action cannot be undone.',
    AppLanguage.spanish =>
      '¿Eliminar este $category? Esta acción no se puede deshacer.',
  };

  String get addAttachmentButton => switch (language) {
    AppLanguage.portuguese => 'Adicionar anexo',
    AppLanguage.english => 'Add attachment',
    AppLanguage.spanish => 'Añadir adjunto',
  };

  String get attachmentsEmptyTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhum anexo ainda',
    AppLanguage.english => 'No attachments yet',
    AppLanguage.spanish => 'Aún no hay adjuntos',
  };

  String get attachmentsEmptyMessage => switch (language) {
    AppLanguage.portuguese => 'Anexe fotos ou arquivos do paciente.',
    AppLanguage.english => "Attach the patient's photos or files.",
    AppLanguage.spanish => 'Adjunta fotos o archivos del paciente.',
  };

  String get takePhotoOption => switch (language) {
    AppLanguage.portuguese => 'Tirar foto',
    AppLanguage.english => 'Take photo',
    AppLanguage.spanish => 'Tomar foto',
  };

  String get chooseFromGalleryOption => switch (language) {
    AppLanguage.portuguese => 'Escolher da galeria',
    AppLanguage.english => 'Choose from gallery',
    AppLanguage.spanish => 'Elegir de la galería',
  };

  String get chooseFileOption => switch (language) {
    AppLanguage.portuguese => 'Escolher arquivo (PDF)',
    AppLanguage.english => 'Choose file (PDF)',
    AppLanguage.spanish => 'Elegir archivo (PDF)',
  };

  String get finalNoteHint => switch (language) {
    AppLanguage.portuguese => 'Observação final (opcional)',
    AppLanguage.english => 'Final note (optional)',
    AppLanguage.spanish => 'Observación final (opcional)',
  };

  String get confirmCloseTreatmentButton => switch (language) {
    AppLanguage.portuguese => 'Confirmar encerramento',
    AppLanguage.english => 'Confirm closure',
    AppLanguage.spanish => 'Confirmar cierre',
  };

  String get sectionAnamnesis => switch (language) {
    AppLanguage.portuguese => 'Anamnese',
    AppLanguage.english => 'Anamnesis',
    AppLanguage.spanish => 'Anamnesis',
  };

  String get fieldChiefComplaint => switch (language) {
    AppLanguage.portuguese => 'Queixa principal',
    AppLanguage.english => 'Chief complaint',
    AppLanguage.spanish => 'Motivo principal',
  };

  String get fieldSymptomsOnset => switch (language) {
    AppLanguage.portuguese => 'Início dos sintomas',
    AppLanguage.english => 'Symptom onset',
    AppLanguage.spanish => 'Inicio de los síntomas',
  };

  String get fieldHasMedicalDiagnosis => switch (language) {
    AppLanguage.portuguese => 'Tem diagnóstico médico',
    AppLanguage.english => 'Has a medical diagnosis',
    AppLanguage.spanish => 'Tiene diagnóstico médico',
  };

  String get fieldWhichDiagnosis => switch (language) {
    AppLanguage.portuguese => 'Qual diagnóstico',
    AppLanguage.english => 'Which diagnosis',
    AppLanguage.spanish => 'Cuál diagnóstico',
  };

  String get fieldHadPreviousTreatment => switch (language) {
    AppLanguage.portuguese => 'Já realizou tratamento',
    AppLanguage.english => 'Has had previous treatment',
    AppLanguage.spanish => 'Ya realizó tratamiento',
  };

  String get fieldWhichTreatment => switch (language) {
    AppLanguage.portuguese => 'Qual tratamento',
    AppLanguage.english => 'Which treatment',
    AppLanguage.spanish => 'Cuál tratamiento',
  };

  String get fieldChronicDiseases => switch (language) {
    AppLanguage.portuguese => 'Doenças crônicas',
    AppLanguage.english => 'Chronic diseases',
    AppLanguage.spanish => 'Enfermedades crónicas',
  };

  String get fieldWhichDiseases => switch (language) {
    AppLanguage.portuguese => 'Quais doenças',
    AppLanguage.english => 'Which diseases',
    AppLanguage.spanish => 'Cuáles enfermedades',
  };

  String get fieldContinuousMedication => switch (language) {
    AppLanguage.portuguese => 'Uso contínuo de medicamentos',
    AppLanguage.english => 'Continuous medication use',
    AppLanguage.spanish => 'Uso continuo de medicamentos',
  };

  String get fieldWhichMedications => switch (language) {
    AppLanguage.portuguese => 'Quais medicamentos',
    AppLanguage.english => 'Which medications',
    AppLanguage.spanish => 'Cuáles medicamentos',
  };

  String get fieldSmoking => switch (language) {
    AppLanguage.portuguese => 'Tabagismo',
    AppLanguage.english => 'Smoking',
    AppLanguage.spanish => 'Tabaquismo',
  };

  String get fieldConsumesAlcohol => switch (language) {
    AppLanguage.portuguese => 'Consome álcool',
    AppLanguage.english => 'Consumes alcohol',
    AppLanguage.spanish => 'Consume alcohol',
  };

  String get fieldPhysicalActivity => switch (language) {
    AppLanguage.portuguese => 'Pratica atividade física',
    AppLanguage.english => 'Practices physical activity',
    AppLanguage.spanish => 'Practica actividad física',
  };

  String get fieldImagingExams => switch (language) {
    AppLanguage.portuguese => 'Exames de imagem',
    AppLanguage.english => 'Imaging exams',
    AppLanguage.spanish => 'Exámenes de imagen',
  };

  String get sectionBowelFunction => switch (language) {
    AppLanguage.portuguese => 'Função intestinal',
    AppLanguage.english => 'Bowel function',
    AppLanguage.spanish => 'Función intestinal',
  };

  String get fieldBowelFrequency => switch (language) {
    AppLanguage.portuguese => 'Frequência evacuatória',
    AppLanguage.english => 'Bowel movement frequency',
    AppLanguage.spanish => 'Frecuencia evacuatoria',
  };

  String get fieldTimesPerWeek => switch (language) {
    AppLanguage.portuguese => 'Quantas vezes por semana',
    AppLanguage.english => 'How many times per week',
    AppLanguage.spanish => 'Cuántas veces por semana',
  };

  String get fieldUsesLaxative => switch (language) {
    AppLanguage.portuguese => 'Usa laxante',
    AppLanguage.english => 'Uses laxative',
    AppLanguage.spanish => 'Usa laxante',
  };

  String get fieldWhichLaxative => switch (language) {
    AppLanguage.portuguese => 'Qual laxante e frequência',
    AppLanguage.english => 'Which laxative and frequency',
    AppLanguage.spanish => 'Cuál laxante y frecuencia',
  };

  String get fieldStrainsToDefecate => switch (language) {
    AppLanguage.portuguese => 'Faz força para evacuar',
    AppLanguage.english => 'Strains to defecate',
    AppLanguage.spanish => 'Hace fuerza para evacuar',
  };

  String get fieldPainToDefecate => switch (language) {
    AppLanguage.portuguese => 'Sente dor para evacuar',
    AppLanguage.english => 'Feels pain when defecating',
    AppLanguage.spanish => 'Siente dolor al evacuar',
  };

  String get fieldIncompleteEmptying => switch (language) {
    AppLanguage.portuguese => 'Sensação de esvaziamento incompleto',
    AppLanguage.english => 'Feeling of incomplete emptying',
    AppLanguage.spanish => 'Sensación de vaciado incompleto',
  };

  String get fieldObstructionSensation => switch (language) {
    AppLanguage.portuguese => 'Sensação de obstrução',
    AppLanguage.english => 'Feeling of obstruction',
    AppLanguage.spanish => 'Sensación de obstrucción',
  };

  String get fieldFecalUrgency => switch (language) {
    AppLanguage.portuguese => 'Urgência fecal',
    AppLanguage.english => 'Fecal urgency',
    AppLanguage.spanish => 'Urgencia fecal',
  };

  String get fieldHemorrhoids => switch (language) {
    AppLanguage.portuguese => 'Presença de hemorroidas',
    AppLanguage.english => 'Presence of hemorrhoids',
    AppLanguage.spanish => 'Presencia de hemorroides',
  };

  String get fieldGasIncontinence => switch (language) {
    AppLanguage.portuguese => 'Perde gases',
    AppLanguage.english => 'Gas incontinence',
    AppLanguage.spanish => 'Pérdida de gases',
  };

  String get fieldFecalIncontinence => switch (language) {
    AppLanguage.portuguese => 'Perde fezes',
    AppLanguage.english => 'Fecal incontinence',
    AppLanguage.spanish => 'Pérdida de heces',
  };

  String get fieldBristolScale => switch (language) {
    AppLanguage.portuguese => 'Escala de Bristol',
    AppLanguage.english => 'Bristol stool scale',
    AppLanguage.spanish => 'Escala de Bristol',
  };

  String get sectionSexualFunction => switch (language) {
    AppLanguage.portuguese => 'Função sexual',
    AppLanguage.english => 'Sexual function',
    AppLanguage.spanish => 'Función sexual',
  };

  String get fieldSexuallyActive => switch (language) {
    AppLanguage.portuguese => 'Vida sexual ativa',
    AppLanguage.english => 'Sexually active',
    AppLanguage.spanish => 'Vida sexual activa',
  };

  String get fieldSexualActivityFrequency => switch (language) {
    AppLanguage.portuguese => 'Frequência de atividade sexual',
    AppLanguage.english => 'Sexual activity frequency',
    AppLanguage.spanish => 'Frecuencia de actividad sexual',
  };

  String get fieldNeedsLubricant => switch (language) {
    AppLanguage.portuguese => 'Precisa usar lubrificante',
    AppLanguage.english => 'Needs lubricant',
    AppLanguage.spanish => 'Necesita usar lubricante',
  };

  String get fieldDryness => switch (language) {
    AppLanguage.portuguese => 'Sensação de ressecamento',
    AppLanguage.english => 'Feeling of dryness',
    AppLanguage.spanish => 'Sensación de resequedad',
  };

  String get fieldOrgasmDifficulty => switch (language) {
    AppLanguage.portuguese => 'Dificuldade para atingir o orgasmo',
    AppLanguage.english => 'Difficulty reaching orgasm',
    AppLanguage.spanish => 'Dificultad para llegar al orgasmo',
  };

  String get fieldDetailGeneric => switch (language) {
    AppLanguage.portuguese => 'Detalhe',
    AppLanguage.english => 'Detail',
    AppLanguage.spanish => 'Detalle',
  };

  String get fieldPainDuringPenetration => switch (language) {
    AppLanguage.portuguese => 'Dor na penetração',
    AppLanguage.english => 'Pain during penetration',
    AppLanguage.spanish => 'Dolor en la penetración',
  };

  String get fieldPainType => switch (language) {
    AppLanguage.portuguese => 'Tipo de dor',
    AppLanguage.english => 'Pain type',
    AppLanguage.spanish => 'Tipo de dolor',
  };

  String get fieldPainDuringOrAfterIntercourse => switch (language) {
    AppLanguage.portuguese => 'Dor durante ou depois da relação',
    AppLanguage.english => 'Pain during or after intercourse',
    AppLanguage.spanish => 'Dolor durante o después de la relación',
  };

  String get fieldPainIntensity0to10 => switch (language) {
    AppLanguage.portuguese => 'Intensidade da dor (0-10)',
    AppLanguage.english => 'Pain intensity (0-10)',
    AppLanguage.spanish => 'Intensidad del dolor (0-10)',
  };

  String get fieldSexualDesire => switch (language) {
    AppLanguage.portuguese => 'Desejo sexual',
    AppLanguage.english => 'Sexual desire',
    AppLanguage.spanish => 'Deseo sexual',
  };

  String get sectionUrinaryFunction => switch (language) {
    AppLanguage.portuguese => 'Função urinária',
    AppLanguage.english => 'Urinary function',
    AppLanguage.spanish => 'Función urinaria',
  };

  String get fieldUrgency => switch (language) {
    AppLanguage.portuguese => 'Urgência',
    AppLanguage.english => 'Urgency',
    AppLanguage.spanish => 'Urgencia',
  };

  String get fieldUrgencyDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da urgência',
    AppLanguage.english => 'Urgency detail',
    AppLanguage.spanish => 'Detalle de la urgencia',
  };

  String get fieldUrgencyAssociatedLeakage => switch (language) {
    AppLanguage.portuguese => 'Perda associada à urgência',
    AppLanguage.english => 'Leakage associated with urgency',
    AppLanguage.spanish => 'Pérdida asociada a la urgencia',
  };

  String get fieldStressIncontinence => switch (language) {
    AppLanguage.portuguese => 'Incontinência de esforço',
    AppLanguage.english => 'Stress incontinence',
    AppLanguage.spanish => 'Incontinencia de esfuerzo',
  };

  String get fieldTriggers => switch (language) {
    AppLanguage.portuguese => 'Gatilhos',
    AppLanguage.english => 'Triggers',
    AppLanguage.spanish => 'Desencadenantes',
  };

  String get fieldWhichOtherTrigger => switch (language) {
    AppLanguage.portuguese => 'Qual outro gatilho',
    AppLanguage.english => 'Which other trigger',
    AppLanguage.spanish => 'Cuál otro desencadenante',
  };

  String get fieldLeakageAmount => switch (language) {
    AppLanguage.portuguese => 'Quantidade aproximada da perda',
    AppLanguage.english => 'Approximate leakage amount',
    AppLanguage.spanish => 'Cantidad aproximada de la pérdida',
  };

  String get fieldUsesPads => switch (language) {
    AppLanguage.portuguese => 'Utiliza absorvente ou protetor',
    AppLanguage.english => 'Uses pads or liners',
    AppLanguage.spanish => 'Utiliza compresas o protectores',
  };

  String get fieldHowManyPerDay => switch (language) {
    AppLanguage.portuguese => 'Quantos por dia',
    AppLanguage.english => 'How many per day',
    AppLanguage.spanish => 'Cuántos por día',
  };

  String get fieldPainOrBurningUrinating => switch (language) {
    AppLanguage.portuguese => 'Dor ou ardência ao urinar',
    AppLanguage.english => 'Pain or burning when urinating',
    AppLanguage.spanish => 'Dolor o ardor al orinar',
  };

  String get fieldWeakStream => switch (language) {
    AppLanguage.portuguese => 'Jato urinário fraco',
    AppLanguage.english => 'Weak urinary stream',
    AppLanguage.spanish => 'Chorro urinario débil',
  };

  String get fieldNocturnalEnuresis => switch (language) {
    AppLanguage.portuguese => 'Enurese noturna',
    AppLanguage.english => 'Nocturnal enuresis',
    AppLanguage.spanish => 'Enuresis nocturna',
  };

  String get fieldEnuresisDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da enurese',
    AppLanguage.english => 'Enuresis detail',
    AppLanguage.spanish => 'Detalle de la enuresis',
  };

  String get fieldHesitancy => switch (language) {
    AppLanguage.portuguese => 'Hesitação',
    AppLanguage.english => 'Hesitancy',
    AppLanguage.spanish => 'Vacilación',
  };

  String get fieldHesitancyDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da hesitação',
    AppLanguage.english => 'Hesitancy detail',
    AppLanguage.spanish => 'Detalle de la vacilación',
  };

  String get fieldUrinaryStraining => switch (language) {
    AppLanguage.portuguese => 'Esforço miccional',
    AppLanguage.english => 'Urinary straining',
    AppLanguage.spanish => 'Esfuerzo miccional',
  };

  String get fieldUrinaryStrainingDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe do esforço miccional',
    AppLanguage.english => 'Urinary straining detail',
    AppLanguage.spanish => 'Detalle del esfuerzo miccional',
  };

  String get fieldPostVoidDribbling => switch (language) {
    AppLanguage.portuguese => 'Gotejamento pós miccional',
    AppLanguage.english => 'Post-void dribbling',
    AppLanguage.spanish => 'Goteo posmiccional',
  };

  String get fieldDribblingDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe do gotejamento',
    AppLanguage.english => 'Dribbling detail',
    AppLanguage.spanish => 'Detalle del goteo',
  };

  String get fieldIncompleteEmptyingDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe do esvaziamento',
    AppLanguage.english => 'Emptying detail',
    AppLanguage.spanish => 'Detalle del vaciado',
  };

  String get sectionSurgicalHistory => switch (language) {
    AppLanguage.portuguese => 'Histórico cirúrgico',
    AppLanguage.english => 'Surgical history',
    AppLanguage.spanish => 'Historial quirúrgico',
  };

  String get fieldSurgeries => switch (language) {
    AppLanguage.portuguese => 'Cirurgias',
    AppLanguage.english => 'Surgeries',
    AppLanguage.spanish => 'Cirugías',
  };

  String get fieldWhichSurgery => switch (language) {
    AppLanguage.portuguese => 'Qual cirurgia',
    AppLanguage.english => 'Which surgery',
    AppLanguage.spanish => 'Cuál cirugía',
  };

  String get sectionGynecologicalHistory => switch (language) {
    AppLanguage.portuguese => 'Histórico ginecológico',
    AppLanguage.english => 'Gynecological history',
    AppLanguage.spanish => 'Historial ginecológico',
  };

  String get fieldAgeAtMenarche => switch (language) {
    AppLanguage.portuguese => 'Idade da primeira menstruação',
    AppLanguage.english => 'Age at first menstruation',
    AppLanguage.spanish => 'Edad de la primera menstruación',
  };

  String get fieldMenstrualFlow => switch (language) {
    AppLanguage.portuguese => 'Fluxo menstrual',
    AppLanguage.english => 'Menstrual flow',
    AppLanguage.spanish => 'Flujo menstrual',
  };

  String get fieldCrampsScore => switch (language) {
    AppLanguage.portuguese => 'Presença de cólica (0-10)',
    AppLanguage.english => 'Cramps intensity (0-10)',
    AppLanguage.spanish => 'Presencia de cólicos (0-10)',
  };

  String get fieldCurrentlyMenstruating => switch (language) {
    AppLanguage.portuguese => 'Menstrua atualmente',
    AppLanguage.english => 'Currently menstruating',
    AppLanguage.spanish => 'Menstrúa actualmente',
  };

  String get fieldInMenopause => switch (language) {
    AppLanguage.portuguese => 'Está na menopausa',
    AppLanguage.english => 'In menopause',
    AppLanguage.spanish => 'Está en la menopausia',
  };

  String get fieldApproxLastMenstruationDate => switch (language) {
    AppLanguage.portuguese => 'Data aproximada da última menstruação',
    AppLanguage.english => 'Approximate date of last menstruation',
    AppLanguage.spanish => 'Fecha aproximada de la última menstruación',
  };

  String get fieldRegularCycle => switch (language) {
    AppLanguage.portuguese => 'Ciclo regular',
    AppLanguage.english => 'Regular cycle',
    AppLanguage.spanish => 'Ciclo regular',
  };

  String get fieldMenopause => switch (language) {
    AppLanguage.portuguese => 'Menopausa',
    AppLanguage.english => 'Menopause',
    AppLanguage.spanish => 'Menopausia',
  };

  String get fieldHormoneReplacement => switch (language) {
    AppLanguage.portuguese => 'Faz reposição hormonal',
    AppLanguage.english => 'Uses hormone replacement therapy',
    AppLanguage.spanish => 'Hace reemplazo hormonal',
  };

  String get fieldHormoneReplacementDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da reposição hormonal',
    AppLanguage.english => 'Hormone replacement detail',
    AppLanguage.spanish => 'Detalle del reemplazo hormonal',
  };

  String get fieldContraceptiveMethod => switch (language) {
    AppLanguage.portuguese => 'Método contraceptivo',
    AppLanguage.english => 'Contraceptive method',
    AppLanguage.spanish => 'Método anticonceptivo',
  };

  String get fieldPelvicPainOutsidePeriod => switch (language) {
    AppLanguage.portuguese => 'Dor pélvica fora do período menstrual',
    AppLanguage.english => 'Pelvic pain outside the menstrual period',
    AppLanguage.spanish => 'Dolor pélvico fuera del período menstrual',
  };

  String get fieldBleedingOutsidePeriod => switch (language) {
    AppLanguage.portuguese => 'Sangramento fora do período menstrual',
    AppLanguage.english => 'Bleeding outside the menstrual period',
    AppLanguage.spanish => 'Sangrado fuera del período menstrual',
  };

  String get fieldEndometriosis => switch (language) {
    AppLanguage.portuguese => 'Endometriose',
    AppLanguage.english => 'Endometriosis',
    AppLanguage.spanish => 'Endometriosis',
  };

  String get fieldPolycysticOvarySyndrome => switch (language) {
    AppLanguage.portuguese => 'Síndrome dos ovários policísticos',
    AppLanguage.english => 'Polycystic ovary syndrome',
    AppLanguage.spanish => 'Síndrome de ovario poliquístico',
  };

  String get fieldRecurrentUrinaryInfections => switch (language) {
    AppLanguage.portuguese => 'Infecções urinárias recorrentes',
    AppLanguage.english => 'Recurrent urinary infections',
    AppLanguage.spanish => 'Infecciones urinarias recurrentes',
  };

  String get fieldRecurrentVaginalInfections => switch (language) {
    AppLanguage.portuguese => 'Infecções vaginais recorrentes',
    AppLanguage.english => 'Recurrent vaginal infections',
    AppLanguage.spanish => 'Infecciones vaginales recurrentes',
  };

  String get sectionObstetricHistory => switch (language) {
    AppLanguage.portuguese => 'Histórico obstétrico',
    AppLanguage.english => 'Obstetric history',
    AppLanguage.spanish => 'Historial obstétrico',
  };

  String get fieldCurrentlyPregnant => switch (language) {
    AppLanguage.portuguese => 'Está gestante atualmente',
    AppLanguage.english => 'Currently pregnant',
    AppLanguage.spanish => 'Está embarazada actualmente',
  };

  String get fieldDesiredDeliveryMethod => switch (language) {
    AppLanguage.portuguese => 'Via de parto desejado',
    AppLanguage.english => 'Desired delivery method',
    AppLanguage.spanish => 'Vía de parto deseada',
  };

  String get fieldGestationWeeks => switch (language) {
    AppLanguage.portuguese => 'Quantas semanas',
    AppLanguage.english => 'How many weeks',
    AppLanguage.spanish => 'Cuántas semanas',
  };

  String get fieldEstimatedDeliveryDate => switch (language) {
    AppLanguage.portuguese => 'Data provável do parto',
    AppLanguage.english => 'Estimated delivery date',
    AppLanguage.spanish => 'Fecha probable de parto',
  };

  String get fieldHighRiskPregnancy => switch (language) {
    AppLanguage.portuguese => 'Gestação de risco',
    AppLanguage.english => 'High-risk pregnancy',
    AppLanguage.spanish => 'Embarazo de riesgo',
  };

  String get fieldHighRiskPregnancyDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da gestação de risco',
    AppLanguage.english => 'High-risk pregnancy detail',
    AppLanguage.spanish => 'Detalle del embarazo de riesgo',
  };

  String get fieldHasBeenPregnant => switch (language) {
    AppLanguage.portuguese => 'Já engravidou',
    AppLanguage.english => 'Has been pregnant before',
    AppLanguage.spanish => 'Ya estuvo embarazada',
  };

  String get fieldPregnancyCount => switch (language) {
    AppLanguage.portuguese => 'Quantas gestações',
    AppLanguage.english => 'How many pregnancies',
    AppLanguage.spanish => 'Cuántos embarazos',
  };

  String get sectionTreatmentPlan => switch (language) {
    AppLanguage.portuguese => 'Plano de tratamento',
    AppLanguage.english => 'Treatment plan',
    AppLanguage.spanish => 'Plan de tratamiento',
  };

  String get fieldPhysiotherapyDiagnosis => switch (language) {
    AppLanguage.portuguese => 'Diagnóstico fisioterapêutico',
    AppLanguage.english => 'Physiotherapy diagnosis',
    AppLanguage.spanish => 'Diagnóstico fisioterapéutico',
  };

  String get fieldTreatmentGoal => switch (language) {
    AppLanguage.portuguese => 'Objetivo do tratamento',
    AppLanguage.english => 'Treatment goal',
    AppLanguage.spanish => 'Objetivo del tratamiento',
  };

  String get fieldTreatmentApproach => switch (language) {
    AppLanguage.portuguese => 'Conduta / plano de tratamento',
    AppLanguage.english => 'Approach / treatment plan',
    AppLanguage.spanish => 'Conducta / plan de tratamiento',
  };

  String get fieldSuggestedFrequency => switch (language) {
    AppLanguage.portuguese => 'Frequência sugerida',
    AppLanguage.english => 'Suggested frequency',
    AppLanguage.spanish => 'Frecuencia sugerida',
  };
}
