import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class PatientsWizardStringsB {
  const PatientsWizardStringsB(this.language);

  final AppLanguage language;

  String get detailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe',
    AppLanguage.english => 'Details',
  };

  String get urinaryUrgencyLabel => switch (language) {
    AppLanguage.portuguese => 'Urgência?',
    AppLanguage.english => 'Urinary urgency?',
  };

  String get leakageAssociatedWithUrgencyLabel => switch (language) {
    AppLanguage.portuguese => 'Perda associada à urgência?',
    AppLanguage.english => 'Leakage associated with urgency?',
  };

  String get stressIncontinenceLabel => switch (language) {
    AppLanguage.portuguese => 'Incontinência de esforço?',
    AppLanguage.english => 'Stress incontinence?',
  };

  String get otherTriggerHint => switch (language) {
    AppLanguage.portuguese => 'Qual outro gatilho?',
    AppLanguage.english => 'What other trigger?',
  };

  String get usesPadsLabel => switch (language) {
    AppLanguage.portuguese => 'Utiliza absorvente ou protetor?',
    AppLanguage.english => 'Uses pads or panty liners?',
  };

  String get padsPerDayHint => switch (language) {
    AppLanguage.portuguese => 'Quantos por dia?',
    AppLanguage.english => 'How many per day?',
  };

  String get painOrBurningWhenUrinatingLabel => switch (language) {
    AppLanguage.portuguese => 'Dor ou ardência ao urinar?',
    AppLanguage.english => 'Pain or burning when urinating?',
  };

  String get weakUrinaryStreamLabel => switch (language) {
    AppLanguage.portuguese => 'Jato urinário fraco?',
    AppLanguage.english => 'Weak urinary stream?',
  };

  String get nocturnalEnuresisLabel => switch (language) {
    AppLanguage.portuguese => 'Enurese noturna?',
    AppLanguage.english => 'Nocturnal enuresis?',
  };

  String get hesitancyLabel => switch (language) {
    AppLanguage.portuguese => 'Hesitação?',
    AppLanguage.english => 'Urinary hesitancy?',
  };

  String get urinaryStrainingLabel => switch (language) {
    AppLanguage.portuguese => 'Esforço miccional?',
    AppLanguage.english => 'Straining to urinate?',
  };

  String get postVoidDribblingLabel => switch (language) {
    AppLanguage.portuguese => 'Gotejamento pós miccional?',
    AppLanguage.english => 'Post-void dribbling?',
  };

  String get incompleteEmptyingUrinaryLabel => switch (language) {
    AppLanguage.portuguese => 'Esvaziamento incompleto?',
    AppLanguage.english => 'Incomplete bladder emptying?',
  };

  String get sexuallyActiveLabel => switch (language) {
    AppLanguage.portuguese => 'Vida sexual ativa?',
    AppLanguage.english => 'Sexually active?',
  };

  String get sexualActivityFrequencyHint => switch (language) {
    AppLanguage.portuguese => 'Frequência de atividade sexual',
    AppLanguage.english => 'Frequency of sexual activity',
  };

  String get needsLubricantLabel => switch (language) {
    AppLanguage.portuguese => 'Precisa usar lubrificante?',
    AppLanguage.english => 'Needs to use lubricant?',
  };

  String get drynessLabel => switch (language) {
    AppLanguage.portuguese => 'Sensação de ressecamento?',
    AppLanguage.english => 'Sensation of vaginal dryness?',
  };

  String get orgasmDifficultyLabel => switch (language) {
    AppLanguage.portuguese => 'Dificuldade para atingir o orgasmo?',
    AppLanguage.english => 'Difficulty reaching orgasm?',
  };

  String get painSectionHeader => switch (language) {
    AppLanguage.portuguese => 'DOR',
    AppLanguage.english => 'PAIN',
  };

  String get painDuringPenetrationLabel => switch (language) {
    AppLanguage.portuguese => 'Dor na penetração?',
    AppLanguage.english => 'Pain during penetration?',
  };

  String get painDuringOrAfterIntercourseLabel => switch (language) {
    AppLanguage.portuguese => 'Dor durante ou depois da relação?',
    AppLanguage.english => 'Pain during or after intercourse?',
  };

  String get painIntensityLabel => switch (language) {
    AppLanguage.portuguese => 'Intensidade da dor',
    AppLanguage.english => 'Pain intensity',
  };

  String get sexualDesireSectionHeader => switch (language) {
    AppLanguage.portuguese => 'DESEJO SEXUAL',
    AppLanguage.english => 'SEXUAL DESIRE',
  };

  String get bowelFrequencySectionHeader => switch (language) {
    AppLanguage.portuguese => 'FREQUÊNCIA EVACUATÓRIA',
    AppLanguage.english => 'BOWEL MOVEMENT FREQUENCY',
  };

  String get timesPerWeekHint => switch (language) {
    AppLanguage.portuguese => 'Quantas vezes por semana?',
    AppLanguage.english => 'How many times per week?',
  };

  String get usesLaxativeLabel => switch (language) {
    AppLanguage.portuguese => 'Usa laxante?',
    AppLanguage.english => 'Uses laxatives?',
  };

  String get laxativeDescriptionHint => switch (language) {
    AppLanguage.portuguese => 'Qual laxante e frequência?',
    AppLanguage.english => 'Which laxative and how often?',
  };

  String get strainsToDefecateLabel => switch (language) {
    AppLanguage.portuguese => 'Faz força para evacuar?',
    AppLanguage.english => 'Strains to defecate?',
  };

  String get painToDefecateLabel => switch (language) {
    AppLanguage.portuguese => 'Sente dor para evacuar?',
    AppLanguage.english => 'Pain when defecating?',
  };

  String get incompleteEmptyingBowelLabel => switch (language) {
    AppLanguage.portuguese => 'Sensação de esvaziamento incompleto?',
    AppLanguage.english => 'Sensation of incomplete emptying?',
  };

  String get obstructionSensationLabel => switch (language) {
    AppLanguage.portuguese => 'Sensação de obstrução?',
    AppLanguage.english => 'Sensation of obstruction?',
  };

  String get fecalUrgencyLabel => switch (language) {
    AppLanguage.portuguese => 'Urgência fecal?',
    AppLanguage.english => 'Fecal urgency?',
  };

  String get hemorrhoidsLabel => switch (language) {
    AppLanguage.portuguese => 'Presença de hemorroidas?',
    AppLanguage.english => 'Hemorrhoids present?',
  };

  String get gasIncontinenceLabel => switch (language) {
    AppLanguage.portuguese => 'Perde gases?',
    AppLanguage.english => 'Gas incontinence?',
  };

  String get fecalIncontinenceLabel => switch (language) {
    AppLanguage.portuguese => 'Perde fezes?',
    AppLanguage.english => 'Fecal incontinence?',
  };

  String get bristolScaleSectionHeader => switch (language) {
    AppLanguage.portuguese => 'ESCALA DE BRISTOL',
    AppLanguage.english => 'BRISTOL STOOL SCALE',
  };

  String get bristolScaleInfoTooltip => switch (language) {
    AppLanguage.portuguese => 'Ver escala de Bristol',
    AppLanguage.english => 'View Bristol stool scale',
  };

  String get bristolScaleImageTitle => switch (language) {
    AppLanguage.portuguese => 'Escala de Bristol',
    AppLanguage.english => 'Bristol Stool Scale',
  };

  String get physiotherapyDiagnosisHint => switch (language) {
    AppLanguage.portuguese => 'Diagnóstico fisioterapêutico',
    AppLanguage.english => 'Physiotherapy diagnosis',
  };

  String get treatmentGoalHint => switch (language) {
    AppLanguage.portuguese => 'Objetivo do tratamento',
    AppLanguage.english => 'Treatment goal',
  };

  String get treatmentApproachHint => switch (language) {
    AppLanguage.portuguese => 'Conduta / plano de tratamento',
    AppLanguage.english => 'Approach / treatment plan',
  };

  String get suggestedFrequencyHint => switch (language) {
    AppLanguage.portuguese => 'Frequência sugerida (opcional)',
    AppLanguage.english => 'Suggested frequency (optional)',
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
  };

  String get noFileSelected => switch (language) {
    AppLanguage.portuguese => 'Nenhum arquivo selecionado.',
    AppLanguage.english => 'No file selected.',
  };

  String get selectFileButton => switch (language) {
    AppLanguage.portuguese => 'Selecionar arquivo',
    AppLanguage.english => 'Select file',
  };

  String get addAnotherFileButton => switch (language) {
    AppLanguage.portuguese => 'Adicionar outro arquivo',
    AppLanguage.english => 'Add another file',
  };

  String get physicalAssessmentFileLabel => switch (language) {
    AppLanguage.portuguese => 'Avaliação Física',
    AppLanguage.english => 'Physical Assessment',
  };

  String get consultationFeeDescription => switch (language) {
    AppLanguage.portuguese =>
      'Valor cobrado nesta primeira consulta. Campo apenas informativo — '
          'não entra no controle financeiro.',
    AppLanguage.english =>
      'Amount charged for this first consultation. Informational field '
          'only — it is not included in the financial records.',
  };

  String get consultationFeeHint => switch (language) {
    AppLanguage.portuguese => 'Valor da consulta',
    AppLanguage.english => 'Consultation fee',
  };

  String get nextButton => switch (language) {
    AppLanguage.portuguese => 'Próximo',
    AppLanguage.english => 'Next',
  };

  String get saveButton => switch (language) {
    AppLanguage.portuguese => 'Salvar',
    AppLanguage.english => 'Save',
  };

  String get saveChangesButton => switch (language) {
    AppLanguage.portuguese => 'Salvar alterações',
    AppLanguage.english => 'Save changes',
  };

  String get patientCreatedSuccessMessage => switch (language) {
    AppLanguage.portuguese => 'Paciente cadastrado com sucesso.',
    AppLanguage.english => 'Patient successfully registered.',
  };

  String get patientUpdatedSuccessMessage => switch (language) {
    AppLanguage.portuguese => 'Paciente atualizado com sucesso.',
    AppLanguage.english => 'Patient successfully updated.',
  };
}
