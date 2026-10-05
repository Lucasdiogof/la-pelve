import 'package:la_pelve/core/l10n/app_language.dart';

class PatientsWizardStringsA {
  const PatientsWizardStringsA(this.language);

  final AppLanguage language;

  String get nameHint => switch (language) {
    AppLanguage.portuguese => 'Nome',
    AppLanguage.english => 'Name',
    AppLanguage.spanish => 'Nombre',
  };

  String get socialNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome social (opcional)',
    AppLanguage.english => 'Social name (optional)',
    AppLanguage.spanish => 'Nombre social (opcional)',
  };

  String get minLengthError => switch (language) {
    AppLanguage.portuguese => 'Informe pelo menos 3 caracteres.',
    AppLanguage.english => 'Enter at least 3 characters.',
    AppLanguage.spanish => 'Ingresa al menos 3 caracteres.',
  };

  String get ageHint => switch (language) {
    AppLanguage.portuguese => 'Idade',
    AppLanguage.english => 'Age',
    AppLanguage.spanish => 'Edad',
  };

  String get phoneHint => switch (language) {
    AppLanguage.portuguese => '(XX) X XXXX-XXXX',
    AppLanguage.english => '(XX) X XXXX-XXXX',
    AppLanguage.spanish => '(XX) X XXXX-XXXX',
  };

  String get occupationHint => switch (language) {
    AppLanguage.portuguese => 'Profissão',
    AppLanguage.english => 'Occupation',
    AppLanguage.spanish => 'Profesión',
  };

  String get genderSectionHeader => switch (language) {
    AppLanguage.portuguese => 'SEXO',
    AppLanguage.english => 'GENDER',
    AppLanguage.spanish => 'SEXO',
  };

  String get whatsappConsentLabel => switch (language) {
    AppLanguage.portuguese =>
      'Receber lembretes de agendamento pelo WhatsApp',
    AppLanguage.english => 'Receive appointment reminders via WhatsApp',
    AppLanguage.spanish => 'Recibir recordatorios de citas por WhatsApp',
  };

  String get whatsappConsentInvalidPhoneHint => switch (language) {
    AppLanguage.portuguese =>
      'É necessário um número de celular brasileiro válido (com DDD e o 9) '
          'para ativar os lembretes pelo WhatsApp.',
    AppLanguage.english =>
      'A valid Brazilian mobile number (with area code and the leading 9) '
          'is required to enable WhatsApp reminders.',
    AppLanguage.spanish =>
      'Se necesita un número de celular brasileño válido (con código de '
          'área y el 9 inicial) para activar los recordatorios por WhatsApp.',
  };

  String get whatsappConsentPhoneChangedHint => switch (language) {
    AppLanguage.portuguese =>
      'O telefone foi alterado: o consentimento anterior não vale para o '
          'novo número. Ative novamente se o paciente autorizar.',
    AppLanguage.english =>
      'The phone number changed: the previous consent no longer applies '
          'to the new number. Turn it back on if the patient authorizes it.',
    AppLanguage.spanish =>
      'El teléfono cambió: el consentimiento anterior ya no aplica al '
          'nuevo número. Actívalo de nuevo si el paciente lo autoriza.',
  };

  String get chiefComplaintHint => switch (language) {
    AppLanguage.portuguese => 'Queixa principal',
    AppLanguage.english => 'Chief complaint',
    AppLanguage.spanish => 'Motivo principal',
  };

  String get hasMedicalDiagnosisLabel => switch (language) {
    AppLanguage.portuguese => 'Tem diagnóstico médico?',
    AppLanguage.english => 'Has a medical diagnosis?',
    AppLanguage.spanish => '¿Tiene diagnóstico médico?',
  };

  String get medicalDiagnosisDetailHint => switch (language) {
    AppLanguage.portuguese => 'Qual diagnóstico?',
    AppLanguage.english => 'Which diagnosis?',
    AppLanguage.spanish => '¿Cuál diagnóstico?',
  };

  String get presentIllnessHistorySectionHeader => switch (language) {
    AppLanguage.portuguese => 'HMA — HISTÓRIA DA MOLÉSTIA ATUAL',
    AppLanguage.english => 'HPI — HISTORY OF PRESENT ILLNESS',
    AppLanguage.spanish => 'HEA — HISTORIA DE LA ENFERMEDAD ACTUAL',
  };

  String get symptomsOnsetHint => switch (language) {
    AppLanguage.portuguese => 'Início dos sintomas',
    AppLanguage.english => 'Onset of symptoms',
    AppLanguage.spanish => 'Inicio de los síntomas',
  };

  String get hadPreviousTreatmentLabel => switch (language) {
    AppLanguage.portuguese => 'Já realizou algum tratamento?',
    AppLanguage.english => 'Has undergone any treatment?',
    AppLanguage.spanish => '¿Ya realizó algún tratamiento?',
  };

  String get previousTreatmentDetailHint => switch (language) {
    AppLanguage.portuguese => 'Qual tratamento?',
    AppLanguage.english => 'Which treatment?',
    AppLanguage.spanish => '¿Cuál tratamiento?',
  };

  String get hasChronicDiseasesLabel => switch (language) {
    AppLanguage.portuguese => 'Doenças crônicas?',
    AppLanguage.english => 'Chronic diseases?',
    AppLanguage.spanish => '¿Enfermedades crónicas?',
  };

  String get chronicDiseasesDetailHint => switch (language) {
    AppLanguage.portuguese => 'Quais doenças?',
    AppLanguage.english => 'Which diseases?',
    AppLanguage.spanish => '¿Cuáles enfermedades?',
  };

  String get takesContinuousMedicationLabel => switch (language) {
    AppLanguage.portuguese => 'Uso contínuo de medicamentos?',
    AppLanguage.english => 'Continuous use of medication?',
    AppLanguage.spanish => '¿Uso continuo de medicamentos?',
  };

  String get continuousMedicationDetailHint => switch (language) {
    AppLanguage.portuguese => 'Quais medicamentos?',
    AppLanguage.english => 'Which medications?',
    AppLanguage.spanish => '¿Cuáles medicamentos?',
  };

  String get habitsSectionHeader => switch (language) {
    AppLanguage.portuguese => 'HÁBITOS',
    AppLanguage.english => 'HABITS',
    AppLanguage.spanish => 'HÁBITOS',
  };

  String get smokingLabel => switch (language) {
    AppLanguage.portuguese => 'Tabagismo?',
    AppLanguage.english => 'Smoking?',
    AppLanguage.spanish => '¿Tabaquismo?',
  };

  String get consumesAlcoholLabel => switch (language) {
    AppLanguage.portuguese => 'Consome álcool?',
    AppLanguage.english => 'Consumes alcohol?',
    AppLanguage.spanish => '¿Consume alcohol?',
  };

  String get practicesPhysicalActivityLabel => switch (language) {
    AppLanguage.portuguese => 'Pratica atividade física?',
    AppLanguage.english => 'Practices physical activity?',
    AppLanguage.spanish => '¿Practica actividad física?',
  };

  String get imagingExamsHint => switch (language) {
    AppLanguage.portuguese => 'Exames de imagem — resultado',
    AppLanguage.english => 'Imaging exams — result',
    AppLanguage.spanish => 'Exámenes de imagen — resultado',
  };

  String get ageAtMenarcheHint => switch (language) {
    AppLanguage.portuguese => 'Idade da primeira menstruação',
    AppLanguage.english => 'Age at first menstruation',
    AppLanguage.spanish => 'Edad de la primera menstruación',
  };

  String get crampsLabel => switch (language) {
    AppLanguage.portuguese => 'Presença de cólica',
    AppLanguage.english => 'Presence of cramps',
    AppLanguage.spanish => 'Presencia de cólicos',
  };

  String get currentlyMenstruatingLabel => switch (language) {
    AppLanguage.portuguese => 'Menstrua atualmente?',
    AppLanguage.english => 'Currently menstruating?',
    AppLanguage.spanish => '¿Menstrúa actualmente?',
  };

  String get isInMenopauseLabel => switch (language) {
    AppLanguage.portuguese => 'Está na menopausa?',
    AppLanguage.english => 'In menopause?',
    AppLanguage.spanish => '¿Está en la menopausia?',
  };

  String get approximateLastMenstruationDateHint => switch (language) {
    AppLanguage.portuguese => 'Data aproximada da última menstruação',
    AppLanguage.english => 'Approximate date of last menstruation',
    AppLanguage.spanish => 'Fecha aproximada de la última menstruación',
  };

  String get regularCycleLabel => switch (language) {
    AppLanguage.portuguese => 'Ciclo regular?',
    AppLanguage.english => 'Regular cycle?',
    AppLanguage.spanish => '¿Ciclo regular?',
  };

  String get menopauseLabel => switch (language) {
    AppLanguage.portuguese => 'Menopausa?',
    AppLanguage.english => 'Menopause?',
    AppLanguage.spanish => '¿Menopausia?',
  };

  String get hormoneReplacementTherapyLabel => switch (language) {
    AppLanguage.portuguese => 'Faz reposição hormonal?',
    AppLanguage.english => 'Undergoing hormone replacement therapy?',
    AppLanguage.spanish => '¿Hace reemplazo hormonal?',
  };

  String get hormoneReplacementTherapyDetailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe a reposição hormonal',
    AppLanguage.english => 'Describe the hormone replacement therapy',
    AppLanguage.spanish => 'Detalla el reemplazo hormonal',
  };

  String get contraceptiveMethodSectionHeader => switch (language) {
    AppLanguage.portuguese => 'MÉTODO CONTRACEPTIVO',
    AppLanguage.english => 'CONTRACEPTIVE METHOD',
    AppLanguage.spanish => 'MÉTODO ANTICONCEPTIVO',
  };

  String get otherSymptomsSectionHeader => switch (language) {
    AppLanguage.portuguese => 'OUTROS SINTOMAS',
    AppLanguage.english => 'OTHER SYMPTOMS',
    AppLanguage.spanish => 'OTROS SÍNTOMAS',
  };

  String get pelvicPainOutsidePeriodLabel => switch (language) {
    AppLanguage.portuguese => 'Dor pélvica fora do período menstrual?',
    AppLanguage.english => 'Pelvic pain outside the menstrual period?',
    AppLanguage.spanish => '¿Dolor pélvico fuera del período menstrual?',
  };

  String get bleedingOutsidePeriodLabel => switch (language) {
    AppLanguage.portuguese => 'Sangramento fora do período menstrual?',
    AppLanguage.english => 'Bleeding outside the menstrual period?',
    AppLanguage.spanish => '¿Sangrado fuera del período menstrual?',
  };

  String get endometriosisLabel => switch (language) {
    AppLanguage.portuguese => 'Endometriose?',
    AppLanguage.english => 'Endometriosis?',
    AppLanguage.spanish => '¿Endometriosis?',
  };

  String get polycysticOvarySyndromeLabel => switch (language) {
    AppLanguage.portuguese => 'Síndrome dos ovários policísticos?',
    AppLanguage.english => 'Polycystic ovary syndrome?',
    AppLanguage.spanish => '¿Síndrome de ovario poliquístico?',
  };

  String get recurrentUrinaryInfectionsLabel => switch (language) {
    AppLanguage.portuguese => 'Infecções urinárias recorrentes?',
    AppLanguage.english => 'Recurrent urinary infections?',
    AppLanguage.spanish => '¿Infecciones urinarias recurrentes?',
  };

  String get recurrentVaginalInfectionsLabel => switch (language) {
    AppLanguage.portuguese => 'Infecções vaginais recorrentes?',
    AppLanguage.english => 'Recurrent vaginal infections?',
    AppLanguage.spanish => '¿Infecciones vaginales recurrentes?',
  };

  String get currentlyPregnantLabel => switch (language) {
    AppLanguage.portuguese => 'Está gestante atualmente?',
    AppLanguage.english => 'Currently pregnant?',
    AppLanguage.spanish => '¿Está embarazada actualmente?',
  };

  String get desiredDeliveryMethodSectionHeader => switch (language) {
    AppLanguage.portuguese => 'VIA DE PARTO DESEJADO',
    AppLanguage.english => 'DESIRED DELIVERY METHOD',
    AppLanguage.spanish => 'VÍA DE PARTO DESEADA',
  };

  String get gestationWeeksHint => switch (language) {
    AppLanguage.portuguese => 'Quantas semanas',
    AppLanguage.english => 'How many weeks',
    AppLanguage.spanish => 'Cuántas semanas',
  };

  String get estimatedDeliveryDateHint => switch (language) {
    AppLanguage.portuguese => 'Data provável do parto',
    AppLanguage.english => 'Estimated due date',
    AppLanguage.spanish => 'Fecha probable de parto',
  };

  String get highRiskPregnancyLabel => switch (language) {
    AppLanguage.portuguese => 'Gestação de risco?',
    AppLanguage.english => 'High-risk pregnancy?',
    AppLanguage.spanish => '¿Embarazo de riesgo?',
  };

  String get highRiskPregnancyDetailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe a gestação de risco',
    AppLanguage.english => 'Describe the high-risk pregnancy',
    AppLanguage.spanish => 'Detalla el embarazo de riesgo',
  };

  String get hasBeenPregnantLabel => switch (language) {
    AppLanguage.portuguese => 'Já engravidou?',
    AppLanguage.english => 'Has been pregnant before?',
    AppLanguage.spanish => '¿Ya estuvo embarazada?',
  };

  String get pregnancyCountHint => switch (language) {
    AppLanguage.portuguese => 'Quantas gestações?',
    AppLanguage.english => 'How many pregnancies?',
    AppLanguage.spanish => '¿Cuántos embarazos?',
  };

  String pregnancyCardTitle(int number) => switch (language) {
    AppLanguage.portuguese => 'Gestação $number',
    AppLanguage.english => 'Pregnancy $number',
    AppLanguage.spanish => 'Embarazo $number',
  };

  String get pregnancyLossLabel => switch (language) {
    AppLanguage.portuguese => 'Perda gestacional?',
    AppLanguage.english => 'Pregnancy loss?',
    AppLanguage.spanish => '¿Pérdida gestacional?',
  };

  String get pregnancyLossDetailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe a perda gestacional',
    AppLanguage.english => 'Describe the pregnancy loss',
    AppLanguage.spanish => 'Detalla la pérdida gestacional',
  };

  String get forcepsOrVacuumUseLabel => switch (language) {
    AppLanguage.portuguese => 'Uso de fórceps ou vácuo?',
    AppLanguage.english => 'Use of forceps or vacuum extraction?',
    AppLanguage.spanish => '¿Uso de fórceps o vacío?',
  };

  String get approximateBabyWeightHint => switch (language) {
    AppLanguage.portuguese => 'Peso aproximado do bebê',
    AppLanguage.english => 'Approximate baby weight',
    AppLanguage.spanish => 'Peso aproximado del bebé',
  };

  String get hadComplicationsLabel => switch (language) {
    AppLanguage.portuguese => 'Teve complicações?',
    AppLanguage.english => 'Had complications?',
    AppLanguage.spanish => '¿Tuvo complicaciones?',
  };

  String get complicationsDetailHint => switch (language) {
    AppLanguage.portuguese => 'Detalhe as complicações',
    AppLanguage.english => 'Describe the complications',
    AppLanguage.spanish => 'Detalla las complicaciones',
  };

  String get otherSurgeryDetailHint => switch (language) {
    AppLanguage.portuguese => 'Qual cirurgia?',
    AppLanguage.english => 'Which surgery?',
    AppLanguage.spanish => '¿Cuál cirugía?',
  };
}
