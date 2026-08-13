import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class PatientsStrings {
  const PatientsStrings(this.language);

  final AppLanguage language;

  String get notInformed => switch (language) {
    AppLanguage.portuguese => 'Não informado',
    AppLanguage.english => 'Not informed',
  };

  String get yes => switch (language) {
    AppLanguage.portuguese => 'Sim',
    AppLanguage.english => 'Yes',
  };

  String get no => switch (language) {
    AppLanguage.portuguese => 'Não',
    AppLanguage.english => 'No',
  };

  String get newPatientButton => switch (language) {
    AppLanguage.portuguese => 'Novo paciente',
    AppLanguage.english => 'New patient',
  };

  String get listTitle => switch (language) {
    AppLanguage.portuguese => 'Pacientes',
    AppLanguage.english => 'Patients',
  };

  String get listSubtitle => switch (language) {
    AppLanguage.portuguese => 'Gerencie seus pacientes',
    AppLanguage.english => 'Manage your patients',
  };

  String get emptyPatientsTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhum paciente cadastrado',
    AppLanguage.english => 'No patients registered',
  };

  String get emptyPatientsMessage => switch (language) {
    AppLanguage.portuguese => 'Toque em "Novo paciente" para começar.',
    AppLanguage.english => 'Tap "New patient" to get started.',
  };

  String get noNamePlaceholder => switch (language) {
    AppLanguage.portuguese => 'Sem nome',
    AppLanguage.english => 'No name',
  };

  String get deletePatientTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir paciente',
    AppLanguage.english => 'Delete patient',
  };

  String get genericPatientLabel => switch (language) {
    AppLanguage.portuguese => 'este paciente',
    AppLanguage.english => 'this patient',
  };

  String deletePatientDescription(String name) => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja excluir $name? '
          'Essa ação não pode ser desfeita e também apaga as evoluções registradas.',
    AppLanguage.english =>
      'Are you sure you want to delete $name? '
          'This action cannot be undone and will also delete the recorded evolution entries.',
  };

  String get deleteLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir',
    AppLanguage.english => 'Delete',
  };

  String get editPatientTooltip => switch (language) {
    AppLanguage.portuguese => 'Editar paciente',
    AppLanguage.english => 'Edit patient',
  };

  String get deletePatientTooltip => switch (language) {
    AppLanguage.portuguese => 'Excluir paciente',
    AppLanguage.english => 'Delete patient',
  };

  String get reopenTreatmentTitle => switch (language) {
    AppLanguage.portuguese => 'Reabrir tratamento',
    AppLanguage.english => 'Reopen treatment',
  };

  String get reopenTreatmentDescription => switch (language) {
    AppLanguage.portuguese =>
      'Isso remove o encerramento atual e volta o tratamento para em andamento.',
    AppLanguage.english =>
      'This removes the current discharge and returns the treatment to in progress.',
  };

  String get reopenLabel => switch (language) {
    AppLanguage.portuguese => 'Reabrir',
    AppLanguage.english => 'Reopen',
  };

  String get treatmentClosedSuccess => switch (language) {
    AppLanguage.portuguese => 'Tratamento encerrado com sucesso.',
    AppLanguage.english => 'Treatment closed successfully.',
  };

  String get treatmentReopenedSuccess => switch (language) {
    AppLanguage.portuguese => 'Tratamento reaberto com sucesso.',
    AppLanguage.english => 'Treatment reopened successfully.',
  };

  String get patientFallbackTitle => switch (language) {
    AppLanguage.portuguese => 'Paciente',
    AppLanguage.english => 'Patient',
  };

  String get tabInformation => switch (language) {
    AppLanguage.portuguese => 'Informações',
    AppLanguage.english => 'Information',
  };

  String get tabAttachments => switch (language) {
    AppLanguage.portuguese => 'Anexos',
    AppLanguage.english => 'Attachments',
  };

  String get sectionPersonalData => switch (language) {
    AppLanguage.portuguese => 'Dados pessoais',
    AppLanguage.english => 'Personal data',
  };

  String get fieldSex => switch (language) {
    AppLanguage.portuguese => 'Sexo',
    AppLanguage.english => 'Sex',
  };

  String get fieldAge => switch (language) {
    AppLanguage.portuguese => 'Idade',
    AppLanguage.english => 'Age',
  };

  String get fieldPhone => switch (language) {
    AppLanguage.portuguese => 'Telefone',
    AppLanguage.english => 'Phone',
  };

  String get fieldOccupation => switch (language) {
    AppLanguage.portuguese => 'Profissão',
    AppLanguage.english => 'Occupation',
  };

  String get sectionConsultationFee => switch (language) {
    AppLanguage.portuguese => 'Valor da consulta',
    AppLanguage.english => 'Consultation fee',
  };

  String get fieldFirstConsultationFee => switch (language) {
    AppLanguage.portuguese => 'Valor da 1ª consulta',
    AppLanguage.english => 'First consultation fee',
  };

  String get closeTreatmentButton => switch (language) {
    AppLanguage.portuguese => 'Encerrar tratamento',
    AppLanguage.english => 'Close treatment',
  };

  String get viewEvolutionButton => switch (language) {
    AppLanguage.portuguese => 'Ver evolução',
    AppLanguage.english => 'View evolution',
  };

  String treatmentClosedOn(String date) => switch (language) {
    AppLanguage.portuguese => 'Tratamento encerrado em $date',
    AppLanguage.english => 'Treatment closed on $date',
  };

  String reasonLabel(String reason) => switch (language) {
    AppLanguage.portuguese => 'Motivo: $reason',
    AppLanguage.english => 'Reason: $reason',
  };

  String pregnancyNumber(int number) => switch (language) {
    AppLanguage.portuguese => 'Gestação $number',
    AppLanguage.english => 'Pregnancy $number',
  };

  String get fieldPregnancyLoss => switch (language) {
    AppLanguage.portuguese => 'Perda gestacional',
    AppLanguage.english => 'Pregnancy loss',
  };

  String get fieldLossDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da perda',
    AppLanguage.english => 'Loss detail',
  };

  String get fieldDeliveryMethod => switch (language) {
    AppLanguage.portuguese => 'Via de parto',
    AppLanguage.english => 'Delivery method',
  };

  String get fieldDeliveryComplication => switch (language) {
    AppLanguage.portuguese => 'Complicação no parto',
    AppLanguage.english => 'Delivery complication',
  };

  String get fieldForcepsOrVacuum => switch (language) {
    AppLanguage.portuguese => 'Uso de fórceps ou vácuo',
    AppLanguage.english => 'Forceps or vacuum use',
  };

  String get fieldApproxBabyWeight => switch (language) {
    AppLanguage.portuguese => 'Peso aproximado do bebê',
    AppLanguage.english => 'Approximate baby weight',
  };

  String get fieldHadComplications => switch (language) {
    AppLanguage.portuguese => 'Teve complicações',
    AppLanguage.english => 'Had complications',
  };

  String get fieldComplicationDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe das complicações',
    AppLanguage.english => 'Complication detail',
  };

  String get newEvolutionButton => switch (language) {
    AppLanguage.portuguese => 'Nova evolução',
    AppLanguage.english => 'New evolution',
  };

  String get evolutionPageTitle => switch (language) {
    AppLanguage.portuguese => 'Evolução',
    AppLanguage.english => 'Evolution',
  };

  String get evolutionPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Acompanhe a evolução do paciente',
    AppLanguage.english => "Track the patient's evolution",
  };

  String get evolutionEmptyTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhuma evolução registrada',
    AppLanguage.english => 'No evolution entries recorded',
  };

  String get evolutionEmptyMessage => switch (language) {
    AppLanguage.portuguese => 'Toque em "Nova evolução" para começar.',
    AppLanguage.english => 'Tap "New evolution" to get started.',
  };

  String editedOn(String date) => switch (language) {
    AppLanguage.portuguese => 'Editado em $date',
    AppLanguage.english => 'Edited on $date',
  };

  String get editEvolutionTitle => switch (language) {
    AppLanguage.portuguese => 'Editar evolução',
    AppLanguage.english => 'Edit evolution',
  };

  String get newEvolutionTitle => switch (language) {
    AppLanguage.portuguese => 'Nova evolução',
    AppLanguage.english => 'New evolution',
  };

  String get dateHint => switch (language) {
    AppLanguage.portuguese => 'Data',
    AppLanguage.english => 'Date',
  };

  String get evolutionDescriptionHint => switch (language) {
    AppLanguage.portuguese => 'O que foi feito no atendimento',
    AppLanguage.english => 'What was done during the session',
  };

  String get evolutionUpdatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Evolução atualizada com sucesso.',
    AppLanguage.english => 'Evolution updated successfully.',
  };

  String get evolutionCreatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Evolução registrada com sucesso.',
    AppLanguage.english => 'Evolution recorded successfully.',
  };

  String get saveChangesLabel => switch (language) {
    AppLanguage.portuguese => 'Salvar alterações',
    AppLanguage.english => 'Save changes',
  };

  String get saveLabel => switch (language) {
    AppLanguage.portuguese => 'Salvar',
    AppLanguage.english => 'Save',
  };

  String get attachmentAddedSuccess => switch (language) {
    AppLanguage.portuguese => 'Anexo adicionado com sucesso.',
    AppLanguage.english => 'Attachment added successfully.',
  };

  String get cannotOpenFileError => switch (language) {
    AppLanguage.portuguese => 'Não foi possível abrir o arquivo.',
    AppLanguage.english => 'Could not open the file.',
  };

  String get deleteAttachmentTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir anexo',
    AppLanguage.english => 'Delete attachment',
  };

  String deleteAttachmentDescription(String category) => switch (language) {
    AppLanguage.portuguese =>
      'Excluir este $category? Essa ação não pode ser desfeita.',
    AppLanguage.english =>
      'Delete this $category? This action cannot be undone.',
  };

  String get addAttachmentButton => switch (language) {
    AppLanguage.portuguese => 'Adicionar anexo',
    AppLanguage.english => 'Add attachment',
  };

  String get attachmentsEmptyTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhum anexo ainda',
    AppLanguage.english => 'No attachments yet',
  };

  String get attachmentsEmptyMessage => switch (language) {
    AppLanguage.portuguese => 'Anexe fotos ou arquivos do paciente.',
    AppLanguage.english => "Attach the patient's photos or files.",
  };

  String get takePhotoOption => switch (language) {
    AppLanguage.portuguese => 'Tirar foto',
    AppLanguage.english => 'Take photo',
  };

  String get chooseFromGalleryOption => switch (language) {
    AppLanguage.portuguese => 'Escolher da galeria',
    AppLanguage.english => 'Choose from gallery',
  };

  String get chooseFileOption => switch (language) {
    AppLanguage.portuguese => 'Escolher arquivo (PDF)',
    AppLanguage.english => 'Choose file (PDF)',
  };

  String get finalNoteHint => switch (language) {
    AppLanguage.portuguese => 'Observação final (opcional)',
    AppLanguage.english => 'Final note (optional)',
  };

  String get confirmCloseTreatmentButton => switch (language) {
    AppLanguage.portuguese => 'Confirmar encerramento',
    AppLanguage.english => 'Confirm closure',
  };

  String get sectionAnamnesis => switch (language) {
    AppLanguage.portuguese => 'Anamnese',
    AppLanguage.english => 'Anamnesis',
  };

  String get fieldChiefComplaint => switch (language) {
    AppLanguage.portuguese => 'Queixa principal',
    AppLanguage.english => 'Chief complaint',
  };

  String get fieldSymptomsOnset => switch (language) {
    AppLanguage.portuguese => 'Início dos sintomas',
    AppLanguage.english => 'Symptom onset',
  };

  String get fieldHasMedicalDiagnosis => switch (language) {
    AppLanguage.portuguese => 'Tem diagnóstico médico',
    AppLanguage.english => 'Has a medical diagnosis',
  };

  String get fieldWhichDiagnosis => switch (language) {
    AppLanguage.portuguese => 'Qual diagnóstico',
    AppLanguage.english => 'Which diagnosis',
  };

  String get fieldHadPreviousTreatment => switch (language) {
    AppLanguage.portuguese => 'Já realizou tratamento',
    AppLanguage.english => 'Has had previous treatment',
  };

  String get fieldWhichTreatment => switch (language) {
    AppLanguage.portuguese => 'Qual tratamento',
    AppLanguage.english => 'Which treatment',
  };

  String get fieldChronicDiseases => switch (language) {
    AppLanguage.portuguese => 'Doenças crônicas',
    AppLanguage.english => 'Chronic diseases',
  };

  String get fieldWhichDiseases => switch (language) {
    AppLanguage.portuguese => 'Quais doenças',
    AppLanguage.english => 'Which diseases',
  };

  String get fieldContinuousMedication => switch (language) {
    AppLanguage.portuguese => 'Uso contínuo de medicamentos',
    AppLanguage.english => 'Continuous medication use',
  };

  String get fieldWhichMedications => switch (language) {
    AppLanguage.portuguese => 'Quais medicamentos',
    AppLanguage.english => 'Which medications',
  };

  String get fieldSmoking => switch (language) {
    AppLanguage.portuguese => 'Tabagismo',
    AppLanguage.english => 'Smoking',
  };

  String get fieldConsumesAlcohol => switch (language) {
    AppLanguage.portuguese => 'Consome álcool',
    AppLanguage.english => 'Consumes alcohol',
  };

  String get fieldPhysicalActivity => switch (language) {
    AppLanguage.portuguese => 'Pratica atividade física',
    AppLanguage.english => 'Practices physical activity',
  };

  String get fieldImagingExams => switch (language) {
    AppLanguage.portuguese => 'Exames de imagem',
    AppLanguage.english => 'Imaging exams',
  };

  String get sectionBowelFunction => switch (language) {
    AppLanguage.portuguese => 'Função intestinal',
    AppLanguage.english => 'Bowel function',
  };

  String get fieldBowelFrequency => switch (language) {
    AppLanguage.portuguese => 'Frequência evacuatória',
    AppLanguage.english => 'Bowel movement frequency',
  };

  String get fieldTimesPerWeek => switch (language) {
    AppLanguage.portuguese => 'Quantas vezes por semana',
    AppLanguage.english => 'How many times per week',
  };

  String get fieldUsesLaxative => switch (language) {
    AppLanguage.portuguese => 'Usa laxante',
    AppLanguage.english => 'Uses laxative',
  };

  String get fieldWhichLaxative => switch (language) {
    AppLanguage.portuguese => 'Qual laxante e frequência',
    AppLanguage.english => 'Which laxative and frequency',
  };

  String get fieldStrainsToDefecate => switch (language) {
    AppLanguage.portuguese => 'Faz força para evacuar',
    AppLanguage.english => 'Strains to defecate',
  };

  String get fieldPainToDefecate => switch (language) {
    AppLanguage.portuguese => 'Sente dor para evacuar',
    AppLanguage.english => 'Feels pain when defecating',
  };

  String get fieldIncompleteEmptying => switch (language) {
    AppLanguage.portuguese => 'Sensação de esvaziamento incompleto',
    AppLanguage.english => 'Feeling of incomplete emptying',
  };

  String get fieldObstructionSensation => switch (language) {
    AppLanguage.portuguese => 'Sensação de obstrução',
    AppLanguage.english => 'Feeling of obstruction',
  };

  String get fieldFecalUrgency => switch (language) {
    AppLanguage.portuguese => 'Urgência fecal',
    AppLanguage.english => 'Fecal urgency',
  };

  String get fieldHemorrhoids => switch (language) {
    AppLanguage.portuguese => 'Presença de hemorroidas',
    AppLanguage.english => 'Presence of hemorrhoids',
  };

  String get fieldGasIncontinence => switch (language) {
    AppLanguage.portuguese => 'Perde gases',
    AppLanguage.english => 'Gas incontinence',
  };

  String get fieldFecalIncontinence => switch (language) {
    AppLanguage.portuguese => 'Perde fezes',
    AppLanguage.english => 'Fecal incontinence',
  };

  String get fieldBristolScale => switch (language) {
    AppLanguage.portuguese => 'Escala de Bristol',
    AppLanguage.english => 'Bristol stool scale',
  };

  String get sectionSexualFunction => switch (language) {
    AppLanguage.portuguese => 'Função sexual',
    AppLanguage.english => 'Sexual function',
  };

  String get fieldSexuallyActive => switch (language) {
    AppLanguage.portuguese => 'Vida sexual ativa',
    AppLanguage.english => 'Sexually active',
  };

  String get fieldSexualActivityFrequency => switch (language) {
    AppLanguage.portuguese => 'Frequência de atividade sexual',
    AppLanguage.english => 'Sexual activity frequency',
  };

  String get fieldNeedsLubricant => switch (language) {
    AppLanguage.portuguese => 'Precisa usar lubrificante',
    AppLanguage.english => 'Needs lubricant',
  };

  String get fieldDryness => switch (language) {
    AppLanguage.portuguese => 'Sensação de ressecamento',
    AppLanguage.english => 'Feeling of dryness',
  };

  String get fieldOrgasmDifficulty => switch (language) {
    AppLanguage.portuguese => 'Dificuldade para atingir o orgasmo',
    AppLanguage.english => 'Difficulty reaching orgasm',
  };

  String get fieldDetailGeneric => switch (language) {
    AppLanguage.portuguese => 'Detalhe',
    AppLanguage.english => 'Detail',
  };

  String get fieldPainDuringPenetration => switch (language) {
    AppLanguage.portuguese => 'Dor na penetração',
    AppLanguage.english => 'Pain during penetration',
  };

  String get fieldPainType => switch (language) {
    AppLanguage.portuguese => 'Tipo de dor',
    AppLanguage.english => 'Pain type',
  };

  String get fieldPainDuringOrAfterIntercourse => switch (language) {
    AppLanguage.portuguese => 'Dor durante ou depois da relação',
    AppLanguage.english => 'Pain during or after intercourse',
  };

  String get fieldPainIntensity0to10 => switch (language) {
    AppLanguage.portuguese => 'Intensidade da dor (0-10)',
    AppLanguage.english => 'Pain intensity (0-10)',
  };

  String get fieldSexualDesire => switch (language) {
    AppLanguage.portuguese => 'Desejo sexual',
    AppLanguage.english => 'Sexual desire',
  };

  String get sectionUrinaryFunction => switch (language) {
    AppLanguage.portuguese => 'Função urinária',
    AppLanguage.english => 'Urinary function',
  };

  String get fieldUrgency => switch (language) {
    AppLanguage.portuguese => 'Urgência',
    AppLanguage.english => 'Urgency',
  };

  String get fieldUrgencyDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da urgência',
    AppLanguage.english => 'Urgency detail',
  };

  String get fieldUrgencyAssociatedLeakage => switch (language) {
    AppLanguage.portuguese => 'Perda associada à urgência',
    AppLanguage.english => 'Leakage associated with urgency',
  };

  String get fieldStressIncontinence => switch (language) {
    AppLanguage.portuguese => 'Incontinência de esforço',
    AppLanguage.english => 'Stress incontinence',
  };

  String get fieldTriggers => switch (language) {
    AppLanguage.portuguese => 'Gatilhos',
    AppLanguage.english => 'Triggers',
  };

  String get fieldWhichOtherTrigger => switch (language) {
    AppLanguage.portuguese => 'Qual outro gatilho',
    AppLanguage.english => 'Which other trigger',
  };

  String get fieldLeakageAmount => switch (language) {
    AppLanguage.portuguese => 'Quantidade aproximada da perda',
    AppLanguage.english => 'Approximate leakage amount',
  };

  String get fieldUsesPads => switch (language) {
    AppLanguage.portuguese => 'Utiliza absorvente ou protetor',
    AppLanguage.english => 'Uses pads or liners',
  };

  String get fieldHowManyPerDay => switch (language) {
    AppLanguage.portuguese => 'Quantos por dia',
    AppLanguage.english => 'How many per day',
  };

  String get fieldPainOrBurningUrinating => switch (language) {
    AppLanguage.portuguese => 'Dor ou ardência ao urinar',
    AppLanguage.english => 'Pain or burning when urinating',
  };

  String get fieldWeakStream => switch (language) {
    AppLanguage.portuguese => 'Jato urinário fraco',
    AppLanguage.english => 'Weak urinary stream',
  };

  String get fieldNocturnalEnuresis => switch (language) {
    AppLanguage.portuguese => 'Enurese noturna',
    AppLanguage.english => 'Nocturnal enuresis',
  };

  String get fieldEnuresisDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da enurese',
    AppLanguage.english => 'Enuresis detail',
  };

  String get fieldHesitancy => switch (language) {
    AppLanguage.portuguese => 'Hesitação',
    AppLanguage.english => 'Hesitancy',
  };

  String get fieldHesitancyDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da hesitação',
    AppLanguage.english => 'Hesitancy detail',
  };

  String get fieldUrinaryStraining => switch (language) {
    AppLanguage.portuguese => 'Esforço miccional',
    AppLanguage.english => 'Urinary straining',
  };

  String get fieldUrinaryStrainingDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe do esforço miccional',
    AppLanguage.english => 'Urinary straining detail',
  };

  String get fieldPostVoidDribbling => switch (language) {
    AppLanguage.portuguese => 'Gotejamento pós miccional',
    AppLanguage.english => 'Post-void dribbling',
  };

  String get fieldDribblingDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe do gotejamento',
    AppLanguage.english => 'Dribbling detail',
  };

  String get fieldIncompleteEmptyingDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe do esvaziamento',
    AppLanguage.english => 'Emptying detail',
  };

  String get sectionSurgicalHistory => switch (language) {
    AppLanguage.portuguese => 'Histórico cirúrgico',
    AppLanguage.english => 'Surgical history',
  };

  String get fieldSurgeries => switch (language) {
    AppLanguage.portuguese => 'Cirurgias',
    AppLanguage.english => 'Surgeries',
  };

  String get fieldWhichSurgery => switch (language) {
    AppLanguage.portuguese => 'Qual cirurgia',
    AppLanguage.english => 'Which surgery',
  };

  String get sectionGynecologicalHistory => switch (language) {
    AppLanguage.portuguese => 'Histórico ginecológico',
    AppLanguage.english => 'Gynecological history',
  };

  String get fieldAgeAtMenarche => switch (language) {
    AppLanguage.portuguese => 'Idade da primeira menstruação',
    AppLanguage.english => 'Age at first menstruation',
  };

  String get fieldMenstrualFlow => switch (language) {
    AppLanguage.portuguese => 'Fluxo menstrual',
    AppLanguage.english => 'Menstrual flow',
  };

  String get fieldCrampsScore => switch (language) {
    AppLanguage.portuguese => 'Presença de cólica (0-10)',
    AppLanguage.english => 'Cramps intensity (0-10)',
  };

  String get fieldCurrentlyMenstruating => switch (language) {
    AppLanguage.portuguese => 'Menstrua atualmente',
    AppLanguage.english => 'Currently menstruating',
  };

  String get fieldInMenopause => switch (language) {
    AppLanguage.portuguese => 'Está na menopausa',
    AppLanguage.english => 'In menopause',
  };

  String get fieldApproxLastMenstruationDate => switch (language) {
    AppLanguage.portuguese => 'Data aproximada da última menstruação',
    AppLanguage.english => 'Approximate date of last menstruation',
  };

  String get fieldRegularCycle => switch (language) {
    AppLanguage.portuguese => 'Ciclo regular',
    AppLanguage.english => 'Regular cycle',
  };

  String get fieldMenopause => switch (language) {
    AppLanguage.portuguese => 'Menopausa',
    AppLanguage.english => 'Menopause',
  };

  String get fieldHormoneReplacement => switch (language) {
    AppLanguage.portuguese => 'Faz reposição hormonal',
    AppLanguage.english => 'Uses hormone replacement therapy',
  };

  String get fieldHormoneReplacementDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da reposição hormonal',
    AppLanguage.english => 'Hormone replacement detail',
  };

  String get fieldContraceptiveMethod => switch (language) {
    AppLanguage.portuguese => 'Método contraceptivo',
    AppLanguage.english => 'Contraceptive method',
  };

  String get fieldPelvicPainOutsidePeriod => switch (language) {
    AppLanguage.portuguese => 'Dor pélvica fora do período menstrual',
    AppLanguage.english => 'Pelvic pain outside the menstrual period',
  };

  String get fieldBleedingOutsidePeriod => switch (language) {
    AppLanguage.portuguese => 'Sangramento fora do período menstrual',
    AppLanguage.english => 'Bleeding outside the menstrual period',
  };

  String get fieldEndometriosis => switch (language) {
    AppLanguage.portuguese => 'Endometriose',
    AppLanguage.english => 'Endometriosis',
  };

  String get fieldPolycysticOvarySyndrome => switch (language) {
    AppLanguage.portuguese => 'Síndrome dos ovários policísticos',
    AppLanguage.english => 'Polycystic ovary syndrome',
  };

  String get fieldRecurrentUrinaryInfections => switch (language) {
    AppLanguage.portuguese => 'Infecções urinárias recorrentes',
    AppLanguage.english => 'Recurrent urinary infections',
  };

  String get fieldRecurrentVaginalInfections => switch (language) {
    AppLanguage.portuguese => 'Infecções vaginais recorrentes',
    AppLanguage.english => 'Recurrent vaginal infections',
  };

  String get sectionObstetricHistory => switch (language) {
    AppLanguage.portuguese => 'Histórico obstétrico',
    AppLanguage.english => 'Obstetric history',
  };

  String get fieldCurrentlyPregnant => switch (language) {
    AppLanguage.portuguese => 'Está gestante atualmente',
    AppLanguage.english => 'Currently pregnant',
  };

  String get fieldDesiredDeliveryMethod => switch (language) {
    AppLanguage.portuguese => 'Via de parto desejado',
    AppLanguage.english => 'Desired delivery method',
  };

  String get fieldGestationWeeks => switch (language) {
    AppLanguage.portuguese => 'Quantas semanas',
    AppLanguage.english => 'How many weeks',
  };

  String get fieldEstimatedDeliveryDate => switch (language) {
    AppLanguage.portuguese => 'Data provável do parto',
    AppLanguage.english => 'Estimated delivery date',
  };

  String get fieldHighRiskPregnancy => switch (language) {
    AppLanguage.portuguese => 'Gestação de risco',
    AppLanguage.english => 'High-risk pregnancy',
  };

  String get fieldHighRiskPregnancyDetail => switch (language) {
    AppLanguage.portuguese => 'Detalhe da gestação de risco',
    AppLanguage.english => 'High-risk pregnancy detail',
  };

  String get fieldHasBeenPregnant => switch (language) {
    AppLanguage.portuguese => 'Já engravidou',
    AppLanguage.english => 'Has been pregnant before',
  };

  String get fieldPregnancyCount => switch (language) {
    AppLanguage.portuguese => 'Quantas gestações',
    AppLanguage.english => 'How many pregnancies',
  };

  String get sectionTreatmentPlan => switch (language) {
    AppLanguage.portuguese => 'Plano de tratamento',
    AppLanguage.english => 'Treatment plan',
  };

  String get fieldPhysiotherapyDiagnosis => switch (language) {
    AppLanguage.portuguese => 'Diagnóstico fisioterapêutico',
    AppLanguage.english => 'Physiotherapy diagnosis',
  };

  String get fieldTreatmentGoal => switch (language) {
    AppLanguage.portuguese => 'Objetivo do tratamento',
    AppLanguage.english => 'Treatment goal',
  };

  String get fieldTreatmentApproach => switch (language) {
    AppLanguage.portuguese => 'Conduta / plano de tratamento',
    AppLanguage.english => 'Approach / treatment plan',
  };

  String get fieldSuggestedFrequency => switch (language) {
    AppLanguage.portuguese => 'Frequência sugerida',
    AppLanguage.english => 'Suggested frequency',
  };
}
