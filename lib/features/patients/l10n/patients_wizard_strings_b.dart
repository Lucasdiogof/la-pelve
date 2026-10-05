import 'package:la_pelve/core/l10n/app_language.dart';

class PatientsWizardStringsB {
  const PatientsWizardStringsB(this.language);

  final AppLanguage language;

  String get detailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe',
    AppLanguage.english => 'Details',
    AppLanguage.spanish => 'Detalle',
  };

  String get urinaryUrgencyLabel => switch (language) {
    AppLanguage.portuguese => 'Urgência?',
    AppLanguage.english => 'Urinary urgency?',
    AppLanguage.spanish => '¿Urgencia urinaria?',
  };

  String get leakageAssociatedWithUrgencyLabel => switch (language) {
    AppLanguage.portuguese => 'Perda associada à urgência?',
    AppLanguage.english => 'Leakage associated with urgency?',
    AppLanguage.spanish => '¿Pérdida asociada a la urgencia?',
  };

  String get stressIncontinenceLabel => switch (language) {
    AppLanguage.portuguese => 'Incontinência de esforço?',
    AppLanguage.english => 'Stress incontinence?',
    AppLanguage.spanish => '¿Incontinencia de esfuerzo?',
  };

  String get otherTriggerHint => switch (language) {
    AppLanguage.portuguese => 'Qual outro gatilho?',
    AppLanguage.english => 'What other trigger?',
    AppLanguage.spanish => '¿Cuál otro desencadenante?',
  };

  String get usesPadsLabel => switch (language) {
    AppLanguage.portuguese => 'Utiliza absorvente ou protetor?',
    AppLanguage.english => 'Uses pads or panty liners?',
    AppLanguage.spanish => '¿Utiliza compresas o protectores?',
  };

  String get padsPerDayHint => switch (language) {
    AppLanguage.portuguese => 'Quantos por dia?',
    AppLanguage.english => 'How many per day?',
    AppLanguage.spanish => '¿Cuántos por día?',
  };

  String get painOrBurningWhenUrinatingLabel => switch (language) {
    AppLanguage.portuguese => 'Dor ou ardência ao urinar?',
    AppLanguage.english => 'Pain or burning when urinating?',
    AppLanguage.spanish => '¿Dolor o ardor al orinar?',
  };

  String get weakUrinaryStreamLabel => switch (language) {
    AppLanguage.portuguese => 'Jato urinário fraco?',
    AppLanguage.english => 'Weak urinary stream?',
    AppLanguage.spanish => '¿Chorro urinario débil?',
  };

  String get nocturnalEnuresisLabel => switch (language) {
    AppLanguage.portuguese => 'Enurese noturna?',
    AppLanguage.english => 'Nocturnal enuresis?',
    AppLanguage.spanish => '¿Enuresis nocturna?',
  };

  String get hesitancyLabel => switch (language) {
    AppLanguage.portuguese => 'Hesitação?',
    AppLanguage.english => 'Urinary hesitancy?',
    AppLanguage.spanish => '¿Vacilación urinaria?',
  };

  String get urinaryStrainingLabel => switch (language) {
    AppLanguage.portuguese => 'Esforço miccional?',
    AppLanguage.english => 'Straining to urinate?',
    AppLanguage.spanish => '¿Esfuerzo miccional?',
  };

  String get postVoidDribblingLabel => switch (language) {
    AppLanguage.portuguese => 'Gotejamento pós miccional?',
    AppLanguage.english => 'Post-void dribbling?',
    AppLanguage.spanish => '¿Goteo posmiccional?',
  };

  String get incompleteEmptyingUrinaryLabel => switch (language) {
    AppLanguage.portuguese => 'Esvaziamento incompleto?',
    AppLanguage.english => 'Incomplete bladder emptying?',
    AppLanguage.spanish => '¿Vaciado incompleto?',
  };

  String get sexuallyActiveLabel => switch (language) {
    AppLanguage.portuguese => 'Vida sexual ativa?',
    AppLanguage.english => 'Sexually active?',
    AppLanguage.spanish => '¿Vida sexual activa?',
  };

  String get sexualActivityFrequencyHint => switch (language) {
    AppLanguage.portuguese => 'Frequência de atividade sexual',
    AppLanguage.english => 'Frequency of sexual activity',
    AppLanguage.spanish => 'Frecuencia de actividad sexual',
  };

  String get needsLubricantLabel => switch (language) {
    AppLanguage.portuguese => 'Precisa usar lubrificante?',
    AppLanguage.english => 'Needs to use lubricant?',
    AppLanguage.spanish => '¿Necesita usar lubricante?',
  };

  String get drynessLabel => switch (language) {
    AppLanguage.portuguese => 'Sensação de ressecamento?',
    AppLanguage.english => 'Sensation of vaginal dryness?',
    AppLanguage.spanish => '¿Sensación de resequedad?',
  };

  String get orgasmDifficultyLabel => switch (language) {
    AppLanguage.portuguese => 'Dificuldade para atingir o orgasmo?',
    AppLanguage.english => 'Difficulty reaching orgasm?',
    AppLanguage.spanish => '¿Dificultad para llegar al orgasmo?',
  };

  String get painSectionHeader => switch (language) {
    AppLanguage.portuguese => 'DOR',
    AppLanguage.english => 'PAIN',
    AppLanguage.spanish => 'DOLOR',
  };

  String get painDuringPenetrationLabel => switch (language) {
    AppLanguage.portuguese => 'Dor na penetração?',
    AppLanguage.english => 'Pain during penetration?',
    AppLanguage.spanish => '¿Dolor en la penetración?',
  };

  String get painDuringOrAfterIntercourseLabel => switch (language) {
    AppLanguage.portuguese => 'Dor durante ou depois da relação?',
    AppLanguage.english => 'Pain during or after intercourse?',
    AppLanguage.spanish => '¿Dolor durante o después de la relación?',
  };

  String get painIntensityLabel => switch (language) {
    AppLanguage.portuguese => 'Intensidade da dor',
    AppLanguage.english => 'Pain intensity',
    AppLanguage.spanish => 'Intensidad del dolor',
  };

  String get sexualDesireSectionHeader => switch (language) {
    AppLanguage.portuguese => 'DESEJO SEXUAL',
    AppLanguage.english => 'SEXUAL DESIRE',
    AppLanguage.spanish => 'DESEO SEXUAL',
  };

  String get bowelFrequencySectionHeader => switch (language) {
    AppLanguage.portuguese => 'FREQUÊNCIA EVACUATÓRIA',
    AppLanguage.english => 'BOWEL MOVEMENT FREQUENCY',
    AppLanguage.spanish => 'FRECUENCIA EVACUATORIA',
  };

  String get timesPerWeekHint => switch (language) {
    AppLanguage.portuguese => 'Quantas vezes por semana?',
    AppLanguage.english => 'How many times per week?',
    AppLanguage.spanish => '¿Cuántas veces por semana?',
  };

  String get usesLaxativeLabel => switch (language) {
    AppLanguage.portuguese => 'Usa laxante?',
    AppLanguage.english => 'Uses laxatives?',
    AppLanguage.spanish => '¿Usa laxante?',
  };

  String get laxativeDescriptionHint => switch (language) {
    AppLanguage.portuguese => 'Qual laxante e frequência?',
    AppLanguage.english => 'Which laxative and how often?',
    AppLanguage.spanish => '¿Cuál laxante y frecuencia?',
  };

  String get strainsToDefecateLabel => switch (language) {
    AppLanguage.portuguese => 'Faz força para evacuar?',
    AppLanguage.english => 'Strains to defecate?',
    AppLanguage.spanish => '¿Hace fuerza para evacuar?',
  };

  String get painToDefecateLabel => switch (language) {
    AppLanguage.portuguese => 'Sente dor para evacuar?',
    AppLanguage.english => 'Pain when defecating?',
    AppLanguage.spanish => '¿Siente dolor al evacuar?',
  };

  String get incompleteEmptyingBowelLabel => switch (language) {
    AppLanguage.portuguese => 'Sensação de esvaziamento incompleto?',
    AppLanguage.english => 'Sensation of incomplete emptying?',
    AppLanguage.spanish => '¿Sensación de vaciado incompleto?',
  };

  String get obstructionSensationLabel => switch (language) {
    AppLanguage.portuguese => 'Sensação de obstrução?',
    AppLanguage.english => 'Sensation of obstruction?',
    AppLanguage.spanish => '¿Sensación de obstrucción?',
  };

  String get fecalUrgencyLabel => switch (language) {
    AppLanguage.portuguese => 'Urgência fecal?',
    AppLanguage.english => 'Fecal urgency?',
    AppLanguage.spanish => '¿Urgencia fecal?',
  };

  String get hemorrhoidsLabel => switch (language) {
    AppLanguage.portuguese => 'Presença de hemorroidas?',
    AppLanguage.english => 'Hemorrhoids present?',
    AppLanguage.spanish => '¿Presencia de hemorroides?',
  };

  String get gasIncontinenceLabel => switch (language) {
    AppLanguage.portuguese => 'Perde gases?',
    AppLanguage.english => 'Gas incontinence?',
    AppLanguage.spanish => '¿Pierde gases?',
  };

  String get fecalIncontinenceLabel => switch (language) {
    AppLanguage.portuguese => 'Perde fezes?',
    AppLanguage.english => 'Fecal incontinence?',
    AppLanguage.spanish => '¿Pierde heces?',
  };

  String get bristolScaleSectionHeader => switch (language) {
    AppLanguage.portuguese => 'ESCALA DE BRISTOL',
    AppLanguage.english => 'BRISTOL STOOL SCALE',
    AppLanguage.spanish => 'ESCALA DE BRISTOL',
  };

  String get bristolScaleInfoTooltip => switch (language) {
    AppLanguage.portuguese => 'Ver escala de Bristol',
    AppLanguage.english => 'View Bristol stool scale',
    AppLanguage.spanish => 'Ver escala de Bristol',
  };

  String get bristolScaleImageTitle => switch (language) {
    AppLanguage.portuguese => 'Escala de Bristol',
    AppLanguage.english => 'Bristol Stool Scale',
    AppLanguage.spanish => 'Escala de Bristol',
  };

  String get physiotherapyDiagnosisHint => switch (language) {
    AppLanguage.portuguese => 'Diagnóstico fisioterapêutico',
    AppLanguage.english => 'Physiotherapy diagnosis',
    AppLanguage.spanish => 'Diagnóstico fisioterapéutico',
  };

  String get treatmentGoalHint => switch (language) {
    AppLanguage.portuguese => 'Objetivo do tratamento',
    AppLanguage.english => 'Treatment goal',
    AppLanguage.spanish => 'Objetivo del tratamiento',
  };

  String get treatmentApproachHint => switch (language) {
    AppLanguage.portuguese => 'Conduta / plano de tratamento',
    AppLanguage.english => 'Approach / treatment plan',
    AppLanguage.spanish => 'Conducta / plan de tratamiento',
  };

  String get suggestedFrequencyHint => switch (language) {
    AppLanguage.portuguese => 'Frequência sugerida (opcional)',
    AppLanguage.english => 'Suggested frequency (optional)',
    AppLanguage.spanish => 'Frecuencia sugerida (opcional)',
  };

  String get assessmentFormDescription => switch (language) {
    AppLanguage.portuguese =>
      'Anexe a ficha de avaliação física do paciente, como fotos ou PDFs. '
          'Você pode adicionar mais de um arquivo. Esse passo é opcional e pode '
          'ser feito depois, pela aba Anexos.',
    AppLanguage.english =>
      'Attach the patient\'s physical assessment file, such as photos or '
          'PDFs. You can add more than one file. This step is optional and can '
          'be done later, from the Attachments tab.',
    AppLanguage.spanish =>
      'Adjunta la ficha de evaluación física del paciente, como fotos o '
          'PDFs. Puedes añadir más de un archivo. Este paso es opcional y se '
          'puede hacer después, desde la pestaña Adjuntos.',
  };

  String get noFileSelected => switch (language) {
    AppLanguage.portuguese => 'Nenhum arquivo selecionado.',
    AppLanguage.english => 'No file selected.',
    AppLanguage.spanish => 'Ningún archivo seleccionado.',
  };

  String get selectFileButton => switch (language) {
    AppLanguage.portuguese => 'Selecionar arquivo',
    AppLanguage.english => 'Select file',
    AppLanguage.spanish => 'Seleccionar archivo',
  };

  String get addAnotherFileButton => switch (language) {
    AppLanguage.portuguese => 'Adicionar outro arquivo',
    AppLanguage.english => 'Add another file',
    AppLanguage.spanish => 'Añadir otro archivo',
  };

  String get physicalAssessmentFileLabel => switch (language) {
    AppLanguage.portuguese => 'Avaliação Física',
    AppLanguage.english => 'Physical Assessment',
    AppLanguage.spanish => 'Evaluación Física',
  };

  String get consultationFeeDescription => switch (language) {
    AppLanguage.portuguese =>
      'Valor cobrado nesta primeira consulta. Campo apenas informativo — '
          'não entra no controle financeiro.',
    AppLanguage.english =>
      'Amount charged for this first consultation. Informational field '
          'only — it is not included in the financial records.',
    AppLanguage.spanish =>
      'Valor cobrado en esta primera consulta. Campo solo informativo — '
          'no entra en el control financiero.',
  };

  String get consultationFeeHint => switch (language) {
    AppLanguage.portuguese => 'Valor da consulta',
    AppLanguage.english => 'Consultation fee',
    AppLanguage.spanish => 'Valor de la consulta',
  };

  String get nextButton => switch (language) {
    AppLanguage.portuguese => 'Próximo',
    AppLanguage.english => 'Next',
    AppLanguage.spanish => 'Siguiente',
  };

  String get saveButton => switch (language) {
    AppLanguage.portuguese => 'Salvar',
    AppLanguage.english => 'Save',
    AppLanguage.spanish => 'Guardar',
  };

  String get saveChangesButton => switch (language) {
    AppLanguage.portuguese => 'Salvar alterações',
    AppLanguage.english => 'Save changes',
    AppLanguage.spanish => 'Guardar cambios',
  };

  String get patientCreatedSuccessMessage => switch (language) {
    AppLanguage.portuguese => 'Paciente cadastrado com sucesso.',
    AppLanguage.english => 'Patient successfully registered.',
    AppLanguage.spanish => 'Paciente registrado con éxito.',
  };

  String get patientUpdatedSuccessMessage => switch (language) {
    AppLanguage.portuguese => 'Paciente atualizado com sucesso.',
    AppLanguage.english => 'Patient successfully updated.',
    AppLanguage.spanish => 'Paciente actualizado con éxito.',
  };

  String get whatsappConsentSaveErrorMessage => switch (language) {
    AppLanguage.portuguese =>
      'O paciente foi salvo, mas não foi possível atualizar o '
          'consentimento de lembretes pelo WhatsApp. Tente novamente na '
          'edição do paciente.',
    AppLanguage.english =>
      'The patient was saved, but the WhatsApp reminder consent could '
          'not be updated. Try again from the patient edit screen.',
    AppLanguage.spanish =>
      'El paciente se guardó, pero no fue posible actualizar el '
          'consentimiento de recordatorios por WhatsApp. Inténtalo de nuevo '
          'desde la edición del paciente.',
  };

  String get whatsappConsentSaveErrorTitle => switch (language) {
    AppLanguage.portuguese => 'Paciente salvo',
    AppLanguage.english => 'Patient saved',
    AppLanguage.spanish => 'Paciente guardado',
  };

  String get consentLoadErrorMessage => switch (language) {
    AppLanguage.portuguese =>
      'Não foi possível verificar o consentimento de lembretes pelo '
          'WhatsApp deste paciente. Tente novamente.',
    AppLanguage.english =>
      "Couldn't check this patient's WhatsApp reminder consent. "
          'Try again.',
    AppLanguage.spanish =>
      'No fue posible verificar el consentimiento de recordatorios por '
          'WhatsApp de este paciente. Inténtalo de nuevo.',
  };

  String get retryButton => switch (language) {
    AppLanguage.portuguese => 'Tentar novamente',
    AppLanguage.english => 'Try again',
    AppLanguage.spanish => 'Intentar de nuevo',
  };

  String get backButton => switch (language) {
    AppLanguage.portuguese => 'Voltar',
    AppLanguage.english => 'Back',
    AppLanguage.spanish => 'Volver',
  };
}
