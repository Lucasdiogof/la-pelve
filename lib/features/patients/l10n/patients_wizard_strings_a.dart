import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class PatientsWizardStringsA {
  const PatientsWizardStringsA(this.language);

  final AppLanguage language;

  String get nameHint => switch (language) {
    AppLanguage.portuguese => 'Nome',
    AppLanguage.english => 'Name',
  };

  String get minLengthError => switch (language) {
    AppLanguage.portuguese => 'Informe pelo menos 3 caracteres.',
    AppLanguage.english => 'Enter at least 3 characters.',
  };

  String get ageHint => switch (language) {
    AppLanguage.portuguese => 'Idade',
    AppLanguage.english => 'Age',
  };

  String get phoneHint => switch (language) {
    AppLanguage.portuguese => '(XX) X XXXX-XXXX',
    AppLanguage.english => '(XX) X XXXX-XXXX',
  };

  String get occupationHint => switch (language) {
    AppLanguage.portuguese => 'Profissão',
    AppLanguage.english => 'Profession',
  };

  String get genderSectionHeader => switch (language) {
    AppLanguage.portuguese => 'SEXO',
    AppLanguage.english => 'GENDER',
  };

  String get chiefComplaintHint => switch (language) {
    AppLanguage.portuguese => 'Queixa principal',
    AppLanguage.english => 'Chief complaint',
  };

  String get hasMedicalDiagnosisLabel => switch (language) {
    AppLanguage.portuguese => 'Tem diagnóstico médico?',
    AppLanguage.english => 'Has a medical diagnosis?',
  };

  String get medicalDiagnosisDetailHint => switch (language) {
    AppLanguage.portuguese => 'Qual diagnóstico?',
    AppLanguage.english => 'Which diagnosis?',
  };

  String get presentIllnessHistorySectionHeader => switch (language) {
    AppLanguage.portuguese => 'HMA — HISTÓRIA DA MOLÉSTIA ATUAL',
    AppLanguage.english => 'HPI — HISTORY OF PRESENT ILLNESS',
  };

  String get symptomsOnsetHint => switch (language) {
    AppLanguage.portuguese => 'Início dos sintomas',
    AppLanguage.english => 'Onset of symptoms',
  };

  String get hadPreviousTreatmentLabel => switch (language) {
    AppLanguage.portuguese => 'Já realizou algum tratamento?',
    AppLanguage.english => 'Has undergone any treatment?',
  };

  String get previousTreatmentDetailHint => switch (language) {
    AppLanguage.portuguese => 'Qual tratamento?',
    AppLanguage.english => 'Which treatment?',
  };

  String get hasChronicDiseasesLabel => switch (language) {
    AppLanguage.portuguese => 'Doenças crônicas?',
    AppLanguage.english => 'Chronic diseases?',
  };

  String get chronicDiseasesDetailHint => switch (language) {
    AppLanguage.portuguese => 'Quais doenças?',
    AppLanguage.english => 'Which diseases?',
  };

  String get takesContinuousMedicationLabel => switch (language) {
    AppLanguage.portuguese => 'Uso contínuo de medicamentos?',
    AppLanguage.english => 'Continuous use of medication?',
  };

  String get continuousMedicationDetailHint => switch (language) {
    AppLanguage.portuguese => 'Quais medicamentos?',
    AppLanguage.english => 'Which medications?',
  };

  String get habitsSectionHeader => switch (language) {
    AppLanguage.portuguese => 'HÁBITOS',
    AppLanguage.english => 'HABITS',
  };

  String get smokingLabel => switch (language) {
    AppLanguage.portuguese => 'Tabagismo?',
    AppLanguage.english => 'Smoking?',
  };

  String get consumesAlcoholLabel => switch (language) {
    AppLanguage.portuguese => 'Consome álcool?',
    AppLanguage.english => 'Consumes alcohol?',
  };

  String get practicesPhysicalActivityLabel => switch (language) {
    AppLanguage.portuguese => 'Pratica atividade física?',
    AppLanguage.english => 'Practices physical activity?',
  };

  String get imagingExamsHint => switch (language) {
    AppLanguage.portuguese => 'Exames de imagem — resultado',
    AppLanguage.english => 'Imaging exams — result',
  };

  String get ageAtMenarcheHint => switch (language) {
    AppLanguage.portuguese => 'Idade da primeira menstruação',
    AppLanguage.english => 'Age at first menstruation',
  };

  String get crampsLabel => switch (language) {
    AppLanguage.portuguese => 'Presença de cólica',
    AppLanguage.english => 'Presence of cramps',
  };

  String get currentlyMenstruatingLabel => switch (language) {
    AppLanguage.portuguese => 'Menstrua atualmente?',
    AppLanguage.english => 'Currently menstruating?',
  };

  String get isInMenopauseLabel => switch (language) {
    AppLanguage.portuguese => 'Está na menopausa?',
    AppLanguage.english => 'In menopause?',
  };

  String get approximateLastMenstruationDateHint => switch (language) {
    AppLanguage.portuguese => 'Data aproximada da última menstruação',
    AppLanguage.english => 'Approximate date of last menstruation',
  };

  String get regularCycleLabel => switch (language) {
    AppLanguage.portuguese => 'Ciclo regular?',
    AppLanguage.english => 'Regular cycle?',
  };

  String get menopauseLabel => switch (language) {
    AppLanguage.portuguese => 'Menopausa?',
    AppLanguage.english => 'Menopause?',
  };

  String get hormoneReplacementTherapyLabel => switch (language) {
    AppLanguage.portuguese => 'Faz reposição hormonal?',
    AppLanguage.english => 'Undergoing hormone replacement therapy?',
  };

  String get hormoneReplacementTherapyDetailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe a reposição hormonal',
    AppLanguage.english => 'Describe the hormone replacement therapy',
  };

  String get contraceptiveMethodSectionHeader => switch (language) {
    AppLanguage.portuguese => 'MÉTODO CONTRACEPTIVO',
    AppLanguage.english => 'CONTRACEPTIVE METHOD',
  };

  String get otherSymptomsSectionHeader => switch (language) {
    AppLanguage.portuguese => 'OUTROS SINTOMAS',
    AppLanguage.english => 'OTHER SYMPTOMS',
  };

  String get pelvicPainOutsidePeriodLabel => switch (language) {
    AppLanguage.portuguese => 'Dor pélvica fora do período menstrual?',
    AppLanguage.english => 'Pelvic pain outside the menstrual period?',
  };

  String get bleedingOutsidePeriodLabel => switch (language) {
    AppLanguage.portuguese => 'Sangramento fora do período menstrual?',
    AppLanguage.english => 'Bleeding outside the menstrual period?',
  };

  String get endometriosisLabel => switch (language) {
    AppLanguage.portuguese => 'Endometriose?',
    AppLanguage.english => 'Endometriosis?',
  };

  String get polycysticOvarySyndromeLabel => switch (language) {
    AppLanguage.portuguese => 'Síndrome dos ovários policísticos?',
    AppLanguage.english => 'Polycystic ovary syndrome?',
  };

  String get recurrentUrinaryInfectionsLabel => switch (language) {
    AppLanguage.portuguese => 'Infecções urinárias recorrentes?',
    AppLanguage.english => 'Recurrent urinary infections?',
  };

  String get recurrentVaginalInfectionsLabel => switch (language) {
    AppLanguage.portuguese => 'Infecções vaginais recorrentes?',
    AppLanguage.english => 'Recurrent vaginal infections?',
  };

  String get currentlyPregnantLabel => switch (language) {
    AppLanguage.portuguese => 'Está gestante atualmente?',
    AppLanguage.english => 'Currently pregnant?',
  };

  String get desiredDeliveryMethodSectionHeader => switch (language) {
    AppLanguage.portuguese => 'VIA DE PARTO DESEJADO',
    AppLanguage.english => 'DESIRED DELIVERY METHOD',
  };

  String get gestationWeeksHint => switch (language) {
    AppLanguage.portuguese => 'Quantas semanas',
    AppLanguage.english => 'How many weeks',
  };

  String get estimatedDeliveryDateHint => switch (language) {
    AppLanguage.portuguese => 'Data provável do parto',
    AppLanguage.english => 'Estimated due date',
  };

  String get highRiskPregnancyLabel => switch (language) {
    AppLanguage.portuguese => 'Gestação de risco?',
    AppLanguage.english => 'High-risk pregnancy?',
  };

  String get highRiskPregnancyDetailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe a gestação de risco',
    AppLanguage.english => 'Describe the high-risk pregnancy',
  };

  String get hasBeenPregnantLabel => switch (language) {
    AppLanguage.portuguese => 'Já engravidou?',
    AppLanguage.english => 'Has been pregnant before?',
  };

  String get pregnancyCountHint => switch (language) {
    AppLanguage.portuguese => 'Quantas gestações?',
    AppLanguage.english => 'How many pregnancies?',
  };

  String pregnancyCardTitle(int number) => switch (language) {
    AppLanguage.portuguese => 'Gestação $number',
    AppLanguage.english => 'Pregnancy $number',
  };

  String get pregnancyLossLabel => switch (language) {
    AppLanguage.portuguese => 'Perda gestacional?',
    AppLanguage.english => 'Pregnancy loss?',
  };

  String get pregnancyLossDetailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe a perda gestacional',
    AppLanguage.english => 'Describe the pregnancy loss',
  };

  String get forcepsOrVacuumUseLabel => switch (language) {
    AppLanguage.portuguese => 'Uso de fórceps ou vácuo?',
    AppLanguage.english => 'Use of forceps or vacuum extraction?',
  };

  String get approximateBabyWeightHint => switch (language) {
    AppLanguage.portuguese => 'Peso aproximado do bebê',
    AppLanguage.english => 'Approximate baby weight',
  };

  String get hadComplicationsLabel => switch (language) {
    AppLanguage.portuguese => 'Teve complicações?',
    AppLanguage.english => 'Had complications?',
  };

  String get complicationsDetailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe as complicações',
    AppLanguage.english => 'Describe the complications',
  };

  String get otherSurgeryDetailHint => switch (language) {
    AppLanguage.portuguese => 'Qual cirurgia?',
    AppLanguage.english => 'Which surgery?',
  };
}
