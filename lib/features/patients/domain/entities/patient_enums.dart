import 'package:la_pelve/core/l10n/app_language.dart';

enum Gender { female, male, other }

extension GenderLabel on Gender {
  String label(AppLanguage language) => switch ((this, language)) {
    (Gender.female, AppLanguage.portuguese) => 'Feminino',
    (Gender.female, AppLanguage.english) => 'Female',
    (Gender.female, AppLanguage.spanish) => 'Femenino',
    (Gender.male, AppLanguage.portuguese) => 'Masculino',
    (Gender.male, AppLanguage.english) => 'Male',
    (Gender.male, AppLanguage.spanish) => 'Masculino',
    (Gender.other, AppLanguage.portuguese) => 'Outro',
    (Gender.other, AppLanguage.english) => 'Other',
    (Gender.other, AppLanguage.spanish) => 'Otro',
  };
}

enum ContraceptiveMethod { pill, injection, iud, implant, condom, none }

extension ContraceptiveMethodLabel on ContraceptiveMethod {
  String label(AppLanguage language) => switch ((this, language)) {
    (ContraceptiveMethod.pill, AppLanguage.portuguese) => 'Pílula',
    (ContraceptiveMethod.pill, AppLanguage.english) => 'Pill',
    (ContraceptiveMethod.pill, AppLanguage.spanish) => 'Píldora',
    (ContraceptiveMethod.injection, AppLanguage.portuguese) => 'Injeção',
    (ContraceptiveMethod.injection, AppLanguage.english) => 'Injection',
    (ContraceptiveMethod.injection, AppLanguage.spanish) => 'Inyección',
    (ContraceptiveMethod.iud, AppLanguage.portuguese) => 'DIU',
    (ContraceptiveMethod.iud, AppLanguage.english) => 'IUD',
    (ContraceptiveMethod.iud, AppLanguage.spanish) => 'DIU',
    (ContraceptiveMethod.implant, AppLanguage.portuguese) => 'Implanon',
    (ContraceptiveMethod.implant, AppLanguage.english) => 'Implant',
    (ContraceptiveMethod.implant, AppLanguage.spanish) => 'Implante',
    (ContraceptiveMethod.condom, AppLanguage.portuguese) => 'Camisinha',
    (ContraceptiveMethod.condom, AppLanguage.english) => 'Condom',
    (ContraceptiveMethod.condom, AppLanguage.spanish) => 'Condón',
    (ContraceptiveMethod.none, AppLanguage.portuguese) => 'Nenhum',
    (ContraceptiveMethod.none, AppLanguage.english) => 'None',
    (ContraceptiveMethod.none, AppLanguage.spanish) => 'Ninguno',
  };
}

enum DeliveryMethod { vaginal, cesarean }

extension DeliveryMethodLabel on DeliveryMethod {
  String label(AppLanguage language) => switch ((this, language)) {
    (DeliveryMethod.vaginal, AppLanguage.portuguese) => 'Normal',
    (DeliveryMethod.vaginal, AppLanguage.english) => 'Vaginal',
    (DeliveryMethod.vaginal, AppLanguage.spanish) => 'Vaginal',
    (DeliveryMethod.cesarean, AppLanguage.portuguese) => 'Cesárea',
    (DeliveryMethod.cesarean, AppLanguage.english) => 'C-section',
    (DeliveryMethod.cesarean, AppLanguage.spanish) => 'Cesárea',
  };
}

enum DischargeReason { completed, dropOut, referred, other }

extension DischargeReasonLabel on DischargeReason {
  String label(AppLanguage language) => switch ((this, language)) {
    (DischargeReason.completed, AppLanguage.portuguese) => 'Alta',
    (DischargeReason.completed, AppLanguage.english) => 'Completed',
    (DischargeReason.completed, AppLanguage.spanish) => 'Alta',
    (DischargeReason.dropOut, AppLanguage.portuguese) => 'Abandono',
    (DischargeReason.dropOut, AppLanguage.english) => 'Dropped out',
    (DischargeReason.dropOut, AppLanguage.spanish) => 'Abandono',
    (DischargeReason.referred, AppLanguage.portuguese) => 'Encaminhamento',
    (DischargeReason.referred, AppLanguage.english) => 'Referred',
    (DischargeReason.referred, AppLanguage.spanish) => 'Derivación',
    (DischargeReason.other, AppLanguage.portuguese) => 'Outro',
    (DischargeReason.other, AppLanguage.english) => 'Other',
    (DischargeReason.other, AppLanguage.spanish) => 'Otro',
  };
}

enum DeliveryComplication { none, laceration, episiotomy }

extension DeliveryComplicationLabel on DeliveryComplication {
  String label(AppLanguage language) => switch ((this, language)) {
    (DeliveryComplication.none, AppLanguage.portuguese) => 'Nenhuma',
    (DeliveryComplication.none, AppLanguage.english) => 'None',
    (DeliveryComplication.none, AppLanguage.spanish) => 'Ninguna',
    (DeliveryComplication.laceration, AppLanguage.portuguese) => 'Laceração',
    (DeliveryComplication.laceration, AppLanguage.english) => 'Laceration',
    (DeliveryComplication.laceration, AppLanguage.spanish) => 'Laceración',
    (DeliveryComplication.episiotomy, AppLanguage.portuguese) => 'Episiotomia',
    (DeliveryComplication.episiotomy, AppLanguage.english) => 'Episiotomy',
    (DeliveryComplication.episiotomy, AppLanguage.spanish) => 'Episiotomía',
  };
}

enum GynecologicalSurgery {
  hysterectomy,
  tubalLigation,
  perineoplasty,
  sling,
  prostatectomy,
  other,
  none,
}

extension GynecologicalSurgeryLabel on GynecologicalSurgery {
  String label(AppLanguage language) => switch ((this, language)) {
    (GynecologicalSurgery.hysterectomy, AppLanguage.portuguese) =>
      'Histerectomia',
    (GynecologicalSurgery.hysterectomy, AppLanguage.english) => 'Hysterectomy',
    (GynecologicalSurgery.hysterectomy, AppLanguage.spanish) =>
      'Histerectomía',
    (GynecologicalSurgery.tubalLigation, AppLanguage.portuguese) =>
      'Laqueadura',
    (GynecologicalSurgery.tubalLigation, AppLanguage.english) =>
      'Tubal ligation',
    (GynecologicalSurgery.tubalLigation, AppLanguage.spanish) =>
      'Ligadura de trompas',
    (GynecologicalSurgery.perineoplasty, AppLanguage.portuguese) =>
      'Perineoplastia',
    (GynecologicalSurgery.perineoplasty, AppLanguage.english) =>
      'Perineoplasty',
    (GynecologicalSurgery.perineoplasty, AppLanguage.spanish) =>
      'Perineoplastia',
    (GynecologicalSurgery.sling, AppLanguage.portuguese) => 'Sling',
    (GynecologicalSurgery.sling, AppLanguage.english) => 'Sling',
    (GynecologicalSurgery.sling, AppLanguage.spanish) => 'Sling',
    (GynecologicalSurgery.prostatectomy, AppLanguage.portuguese) =>
      'Prostatectomia',
    (GynecologicalSurgery.prostatectomy, AppLanguage.english) =>
      'Prostatectomy',
    (GynecologicalSurgery.prostatectomy, AppLanguage.spanish) =>
      'Prostatectomía',
    (GynecologicalSurgery.other, AppLanguage.portuguese) => 'Outro',
    (GynecologicalSurgery.other, AppLanguage.english) => 'Other',
    (GynecologicalSurgery.other, AppLanguage.spanish) => 'Otro',
    (GynecologicalSurgery.none, AppLanguage.portuguese) => 'Nenhum',
    (GynecologicalSurgery.none, AppLanguage.english) => 'None',
    (GynecologicalSurgery.none, AppLanguage.spanish) => 'Ninguno',
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
    (IncontinenceTrigger.cough, AppLanguage.spanish) => 'Tos',
    (IncontinenceTrigger.sneeze, AppLanguage.portuguese) => 'Espirro',
    (IncontinenceTrigger.sneeze, AppLanguage.english) => 'Sneezing',
    (IncontinenceTrigger.sneeze, AppLanguage.spanish) => 'Estornudo',
    (IncontinenceTrigger.liftingWeight, AppLanguage.portuguese) => 'Peso',
    (IncontinenceTrigger.liftingWeight, AppLanguage.english) =>
      'Lifting weight',
    (IncontinenceTrigger.liftingWeight, AppLanguage.spanish) =>
      'Levantar peso',
    (IncontinenceTrigger.squatting, AppLanguage.portuguese) => 'Agachar',
    (IncontinenceTrigger.squatting, AppLanguage.english) => 'Squatting',
    (IncontinenceTrigger.squatting, AppLanguage.spanish) => 'Agacharse',
    (IncontinenceTrigger.walking, AppLanguage.portuguese) => 'Caminhando',
    (IncontinenceTrigger.walking, AppLanguage.english) => 'Walking',
    (IncontinenceTrigger.walking, AppLanguage.spanish) => 'Caminar',
    (IncontinenceTrigger.changingPosition, AppLanguage.portuguese) =>
      'Mudando de posição',
    (IncontinenceTrigger.changingPosition, AppLanguage.english) =>
      'Changing position',
    (IncontinenceTrigger.changingPosition, AppLanguage.spanish) =>
      'Cambiar de posición',
    (IncontinenceTrigger.other, AppLanguage.portuguese) => 'Outros',
    (IncontinenceTrigger.other, AppLanguage.english) => 'Other',
    (IncontinenceTrigger.other, AppLanguage.spanish) => 'Otros',
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
    (BowelFrequency.onceDaily, AppLanguage.spanish) => 'Una vez al día',
    (BowelFrequency.afewTimesPerWeek, AppLanguage.portuguese) =>
      'Algumas vezes por semana',
    (BowelFrequency.afewTimesPerWeek, AppLanguage.english) =>
      'A few times a week',
    (BowelFrequency.afewTimesPerWeek, AppLanguage.spanish) =>
      'Algunas veces por semana',
    (BowelFrequency.fewerThanThreeTimesPerWeek, AppLanguage.portuguese) =>
      'Menos de três vezes por semana',
    (BowelFrequency.fewerThanThreeTimesPerWeek, AppLanguage.english) =>
      'Fewer than three times a week',
    (BowelFrequency.fewerThanThreeTimesPerWeek, AppLanguage.spanish) =>
      'Menos de tres veces por semana',
    (BowelFrequency.custom, AppLanguage.portuguese) => 'Personalizado',
    (BowelFrequency.custom, AppLanguage.english) => 'Custom',
    (BowelFrequency.custom, AppLanguage.spanish) => 'Personalizado',
  };
}

enum MenstrualFlow { light, moderate, heavy }

extension MenstrualFlowLabel on MenstrualFlow {
  String label(AppLanguage language) => switch ((this, language)) {
    (MenstrualFlow.light, AppLanguage.portuguese) => 'Leve',
    (MenstrualFlow.light, AppLanguage.english) => 'Light',
    (MenstrualFlow.light, AppLanguage.spanish) => 'Leve',
    (MenstrualFlow.moderate, AppLanguage.portuguese) => 'Moderado',
    (MenstrualFlow.moderate, AppLanguage.english) => 'Moderate',
    (MenstrualFlow.moderate, AppLanguage.spanish) => 'Moderado',
    (MenstrualFlow.heavy, AppLanguage.portuguese) => 'Intenso',
    (MenstrualFlow.heavy, AppLanguage.english) => 'Heavy',
    (MenstrualFlow.heavy, AppLanguage.spanish) => 'Intenso',
  };
}

enum LeakageAmount { drops, small, moderate, large }

extension LeakageAmountLabel on LeakageAmount {
  String label(AppLanguage language) => switch ((this, language)) {
    (LeakageAmount.drops, AppLanguage.portuguese) => 'Gotas',
    (LeakageAmount.drops, AppLanguage.english) => 'Drops',
    (LeakageAmount.drops, AppLanguage.spanish) => 'Gotas',
    (LeakageAmount.small, AppLanguage.portuguese) => 'Pequena',
    (LeakageAmount.small, AppLanguage.english) => 'Small',
    (LeakageAmount.small, AppLanguage.spanish) => 'Pequeña',
    (LeakageAmount.moderate, AppLanguage.portuguese) => 'Moderada',
    (LeakageAmount.moderate, AppLanguage.english) => 'Moderate',
    (LeakageAmount.moderate, AppLanguage.spanish) => 'Moderada',
    (LeakageAmount.large, AppLanguage.portuguese) => 'Grande',
    (LeakageAmount.large, AppLanguage.english) => 'Large',
    (LeakageAmount.large, AppLanguage.spanish) => 'Grande',
  };
}

enum PenetrationPainType { superficial, deep }

extension PenetrationPainTypeLabel on PenetrationPainType {
  String label(AppLanguage language) => switch ((this, language)) {
    (PenetrationPainType.superficial, AppLanguage.portuguese) => 'Superficial',
    (PenetrationPainType.superficial, AppLanguage.english) => 'Superficial',
    (PenetrationPainType.superficial, AppLanguage.spanish) => 'Superficial',
    (PenetrationPainType.deep, AppLanguage.portuguese) => 'Profunda',
    (PenetrationPainType.deep, AppLanguage.english) => 'Deep',
    (PenetrationPainType.deep, AppLanguage.spanish) => 'Profundo',
  };
}

enum SexualDesire { preserved, reduced, absent, increased }

extension SexualDesireLabel on SexualDesire {
  String label(AppLanguage language) => switch ((this, language)) {
    (SexualDesire.preserved, AppLanguage.portuguese) => 'Preservado',
    (SexualDesire.preserved, AppLanguage.english) => 'Preserved',
    (SexualDesire.preserved, AppLanguage.spanish) => 'Preservado',
    (SexualDesire.reduced, AppLanguage.portuguese) => 'Reduzido',
    (SexualDesire.reduced, AppLanguage.english) => 'Reduced',
    (SexualDesire.reduced, AppLanguage.spanish) => 'Reducido',
    (SexualDesire.absent, AppLanguage.portuguese) => 'Ausente',
    (SexualDesire.absent, AppLanguage.english) => 'Absent',
    (SexualDesire.absent, AppLanguage.spanish) => 'Ausente',
    (SexualDesire.increased, AppLanguage.portuguese) => 'Aumentado',
    (SexualDesire.increased, AppLanguage.english) => 'Increased',
    (SexualDesire.increased, AppLanguage.spanish) => 'Aumentado',
  };
}

enum BristolScale { type1, type2, type3, type4, type5, type6, type7 }

extension BristolScaleLabel on BristolScale {
  String label(AppLanguage language) {
    final number = index + 1;
    return switch (language) {
      AppLanguage.portuguese => 'Tipo $number',
      AppLanguage.english => 'Type $number',
      AppLanguage.spanish => 'Tipo $number',
    };
  }
}
