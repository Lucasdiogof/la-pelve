import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

enum Gender { female, male }

extension GenderLabel on Gender {
  String label(AppLanguage language) => switch ((this, language)) {
    (Gender.female, AppLanguage.portuguese) => 'Feminino',
    (Gender.female, AppLanguage.english) => 'Female',
    (Gender.male, AppLanguage.portuguese) => 'Masculino',
    (Gender.male, AppLanguage.english) => 'Male',
  };
}

enum ContraceptiveMethod { pill, injection, iud, implant, condom, none }

extension ContraceptiveMethodLabel on ContraceptiveMethod {
  String label(AppLanguage language) => switch ((this, language)) {
    (ContraceptiveMethod.pill, AppLanguage.portuguese) => 'Pílula',
    (ContraceptiveMethod.pill, AppLanguage.english) => 'Pill',
    (ContraceptiveMethod.injection, AppLanguage.portuguese) => 'Injeção',
    (ContraceptiveMethod.injection, AppLanguage.english) => 'Injection',
    (ContraceptiveMethod.iud, AppLanguage.portuguese) => 'DIU',
    (ContraceptiveMethod.iud, AppLanguage.english) => 'IUD',
    (ContraceptiveMethod.implant, AppLanguage.portuguese) => 'Implanon',
    (ContraceptiveMethod.implant, AppLanguage.english) => 'Implant',
    (ContraceptiveMethod.condom, AppLanguage.portuguese) => 'Camisinha',
    (ContraceptiveMethod.condom, AppLanguage.english) => 'Condom',
    (ContraceptiveMethod.none, AppLanguage.portuguese) => 'Nenhum',
    (ContraceptiveMethod.none, AppLanguage.english) => 'None',
  };
}

enum DeliveryMethod { vaginal, cesarean }

extension DeliveryMethodLabel on DeliveryMethod {
  String label(AppLanguage language) => switch ((this, language)) {
    (DeliveryMethod.vaginal, AppLanguage.portuguese) => 'Normal',
    (DeliveryMethod.vaginal, AppLanguage.english) => 'Vaginal',
    (DeliveryMethod.cesarean, AppLanguage.portuguese) => 'Cesárea',
    (DeliveryMethod.cesarean, AppLanguage.english) => 'C-section',
  };
}

enum DischargeReason { completed, dropOut, referred, other }

extension DischargeReasonLabel on DischargeReason {
  String label(AppLanguage language) => switch ((this, language)) {
    (DischargeReason.completed, AppLanguage.portuguese) => 'Alta',
    (DischargeReason.completed, AppLanguage.english) => 'Completed',
    (DischargeReason.dropOut, AppLanguage.portuguese) => 'Abandono',
    (DischargeReason.dropOut, AppLanguage.english) => 'Dropped out',
    (DischargeReason.referred, AppLanguage.portuguese) => 'Encaminhamento',
    (DischargeReason.referred, AppLanguage.english) => 'Referred',
    (DischargeReason.other, AppLanguage.portuguese) => 'Outro',
    (DischargeReason.other, AppLanguage.english) => 'Other',
  };
}

enum DeliveryComplication { none, laceration, episiotomy }

extension DeliveryComplicationLabel on DeliveryComplication {
  String label(AppLanguage language) => switch ((this, language)) {
    (DeliveryComplication.none, AppLanguage.portuguese) => 'Nenhuma',
    (DeliveryComplication.none, AppLanguage.english) => 'None',
    (DeliveryComplication.laceration, AppLanguage.portuguese) => 'Laceração',
    (DeliveryComplication.laceration, AppLanguage.english) => 'Laceration',
    (DeliveryComplication.episiotomy, AppLanguage.portuguese) => 'Episiotomia',
    (DeliveryComplication.episiotomy, AppLanguage.english) => 'Episiotomy',
  };
}

enum GynecologicalSurgery {
  hysterectomy,
  tubalLigation,
  perineoplasty,
  sling,
  other,
  none,
}

extension GynecologicalSurgeryLabel on GynecologicalSurgery {
  String label(AppLanguage language) => switch ((this, language)) {
    (GynecologicalSurgery.hysterectomy, AppLanguage.portuguese) =>
      'Histerectomia',
    (GynecologicalSurgery.hysterectomy, AppLanguage.english) => 'Hysterectomy',
    (GynecologicalSurgery.tubalLigation, AppLanguage.portuguese) =>
      'Laqueadura',
    (GynecologicalSurgery.tubalLigation, AppLanguage.english) =>
      'Tubal ligation',
    (GynecologicalSurgery.perineoplasty, AppLanguage.portuguese) =>
      'Perineoplastia',
    (GynecologicalSurgery.perineoplasty, AppLanguage.english) =>
      'Perineoplasty',
    (GynecologicalSurgery.sling, AppLanguage.portuguese) => 'Sling',
    (GynecologicalSurgery.sling, AppLanguage.english) => 'Sling',
    (GynecologicalSurgery.other, AppLanguage.portuguese) => 'Outro',
    (GynecologicalSurgery.other, AppLanguage.english) => 'Other',
    (GynecologicalSurgery.none, AppLanguage.portuguese) => 'Nenhum',
    (GynecologicalSurgery.none, AppLanguage.english) => 'None',
  };
}

enum IncontinenceTrigger {
  cough,
  sneeze,
  liftingWeight,
  squatting,
  walking,
  changingPosition,
  other,
}

extension IncontinenceTriggerLabel on IncontinenceTrigger {
  String label(AppLanguage language) => switch ((this, language)) {
    (IncontinenceTrigger.cough, AppLanguage.portuguese) => 'Tosse',
    (IncontinenceTrigger.cough, AppLanguage.english) => 'Coughing',
    (IncontinenceTrigger.sneeze, AppLanguage.portuguese) => 'Espirro',
    (IncontinenceTrigger.sneeze, AppLanguage.english) => 'Sneezing',
    (IncontinenceTrigger.liftingWeight, AppLanguage.portuguese) => 'Peso',
    (IncontinenceTrigger.liftingWeight, AppLanguage.english) =>
      'Lifting weight',
    (IncontinenceTrigger.squatting, AppLanguage.portuguese) => 'Agachar',
    (IncontinenceTrigger.squatting, AppLanguage.english) => 'Squatting',
    (IncontinenceTrigger.walking, AppLanguage.portuguese) => 'Caminhando',
    (IncontinenceTrigger.walking, AppLanguage.english) => 'Walking',
    (IncontinenceTrigger.changingPosition, AppLanguage.portuguese) =>
      'Mudando de posição',
    (IncontinenceTrigger.changingPosition, AppLanguage.english) =>
      'Changing position',
    (IncontinenceTrigger.other, AppLanguage.portuguese) => 'Outros',
    (IncontinenceTrigger.other, AppLanguage.english) => 'Other',
  };
}

enum BowelFrequency {
  onceDaily,
  afewTimesPerWeek,
  fewerThanThreeTimesPerWeek,
  custom,
}

extension BowelFrequencyLabel on BowelFrequency {
  String label(AppLanguage language) => switch ((this, language)) {
    (BowelFrequency.onceDaily, AppLanguage.portuguese) => 'Uma vez ao dia',
    (BowelFrequency.onceDaily, AppLanguage.english) => 'Once a day',
    (BowelFrequency.afewTimesPerWeek, AppLanguage.portuguese) =>
      'Algumas vezes por semana',
    (BowelFrequency.afewTimesPerWeek, AppLanguage.english) =>
      'A few times a week',
    (BowelFrequency.fewerThanThreeTimesPerWeek, AppLanguage.portuguese) =>
      'Menos de três vezes por semana',
    (BowelFrequency.fewerThanThreeTimesPerWeek, AppLanguage.english) =>
      'Fewer than three times a week',
    (BowelFrequency.custom, AppLanguage.portuguese) => 'Personalizado',
    (BowelFrequency.custom, AppLanguage.english) => 'Custom',
  };
}

enum MenstrualFlow { light, moderate, heavy }

extension MenstrualFlowLabel on MenstrualFlow {
  String label(AppLanguage language) => switch ((this, language)) {
    (MenstrualFlow.light, AppLanguage.portuguese) => 'Leve',
    (MenstrualFlow.light, AppLanguage.english) => 'Light',
    (MenstrualFlow.moderate, AppLanguage.portuguese) => 'Moderado',
    (MenstrualFlow.moderate, AppLanguage.english) => 'Moderate',
    (MenstrualFlow.heavy, AppLanguage.portuguese) => 'Intenso',
    (MenstrualFlow.heavy, AppLanguage.english) => 'Heavy',
  };
}

enum LeakageAmount { drops, small, moderate, large }

extension LeakageAmountLabel on LeakageAmount {
  String label(AppLanguage language) => switch ((this, language)) {
    (LeakageAmount.drops, AppLanguage.portuguese) => 'Gotas',
    (LeakageAmount.drops, AppLanguage.english) => 'Drops',
    (LeakageAmount.small, AppLanguage.portuguese) => 'Pequena',
    (LeakageAmount.small, AppLanguage.english) => 'Small',
    (LeakageAmount.moderate, AppLanguage.portuguese) => 'Moderada',
    (LeakageAmount.moderate, AppLanguage.english) => 'Moderate',
    (LeakageAmount.large, AppLanguage.portuguese) => 'Grande',
    (LeakageAmount.large, AppLanguage.english) => 'Large',
  };
}

enum PenetrationPainType { superficial, deep }

extension PenetrationPainTypeLabel on PenetrationPainType {
  String label(AppLanguage language) => switch ((this, language)) {
    (PenetrationPainType.superficial, AppLanguage.portuguese) => 'Superficial',
    (PenetrationPainType.superficial, AppLanguage.english) => 'Superficial',
    (PenetrationPainType.deep, AppLanguage.portuguese) => 'Profunda',
    (PenetrationPainType.deep, AppLanguage.english) => 'Deep',
  };
}

enum SexualDesire { preserved, reduced, absent, increased }

extension SexualDesireLabel on SexualDesire {
  String label(AppLanguage language) => switch ((this, language)) {
    (SexualDesire.preserved, AppLanguage.portuguese) => 'Preservado',
    (SexualDesire.preserved, AppLanguage.english) => 'Preserved',
    (SexualDesire.reduced, AppLanguage.portuguese) => 'Reduzido',
    (SexualDesire.reduced, AppLanguage.english) => 'Reduced',
    (SexualDesire.absent, AppLanguage.portuguese) => 'Ausente',
    (SexualDesire.absent, AppLanguage.english) => 'Absent',
    (SexualDesire.increased, AppLanguage.portuguese) => 'Aumentado',
    (SexualDesire.increased, AppLanguage.english) => 'Increased',
  };
}

enum BristolScale { type1, type2, type3, type4, type5, type6, type7 }

extension BristolScaleLabel on BristolScale {
  String label(AppLanguage language) {
    final number = index + 1;
    return switch (language) {
      AppLanguage.portuguese => 'Tipo $number',
      AppLanguage.english => 'Type $number',
    };
  }
}
