enum Gender { female, male }

extension GenderLabel on Gender {
  String get label => switch (this) {
    Gender.female => 'Feminino',
    Gender.male => 'Masculino',
  };
}

enum ContraceptiveMethod { pill, injection, iud, implant, condom, none }

extension ContraceptiveMethodLabel on ContraceptiveMethod {
  String get label => switch (this) {
    ContraceptiveMethod.pill => 'Pílula',
    ContraceptiveMethod.injection => 'Injeção',
    ContraceptiveMethod.iud => 'DIU',
    ContraceptiveMethod.implant => 'Implanon',
    ContraceptiveMethod.condom => 'Camisinha',
    ContraceptiveMethod.none => 'Nenhum',
  };
}

enum DeliveryMethod { vaginal, cesarean }

extension DeliveryMethodLabel on DeliveryMethod {
  String get label => switch (this) {
    DeliveryMethod.vaginal => 'Normal',
    DeliveryMethod.cesarean => 'Cesárea',
  };
}

enum DischargeReason { completed, dropOut, referred, other }

extension DischargeReasonLabel on DischargeReason {
  String get label => switch (this) {
    DischargeReason.completed => 'Alta',
    DischargeReason.dropOut => 'Abandono',
    DischargeReason.referred => 'Encaminhamento',
    DischargeReason.other => 'Outro',
  };
}

enum DeliveryComplication { none, laceration, episiotomy }

extension DeliveryComplicationLabel on DeliveryComplication {
  String get label => switch (this) {
    DeliveryComplication.none => 'Nenhuma',
    DeliveryComplication.laceration => 'Laceração',
    DeliveryComplication.episiotomy => 'Episiotomia',
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
  String get label => switch (this) {
    GynecologicalSurgery.hysterectomy => 'Histerectomia',
    GynecologicalSurgery.tubalLigation => 'Laqueadura',
    GynecologicalSurgery.perineoplasty => 'Perineoplastia',
    GynecologicalSurgery.sling => 'Sling',
    GynecologicalSurgery.other => 'Outro',
    GynecologicalSurgery.none => 'Nenhum',
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
  String get label => switch (this) {
    IncontinenceTrigger.cough => 'Tosse',
    IncontinenceTrigger.sneeze => 'Espirro',
    IncontinenceTrigger.liftingWeight => 'Peso',
    IncontinenceTrigger.squatting => 'Agachar',
    IncontinenceTrigger.walking => 'Caminhando',
    IncontinenceTrigger.changingPosition => 'Mudando de posição',
    IncontinenceTrigger.other => 'Outros',
  };
}

enum BowelFrequency {
  onceDaily,
  afewTimesPerWeek,
  fewerThanThreeTimesPerWeek,
  custom,
}

extension BowelFrequencyLabel on BowelFrequency {
  String get label => switch (this) {
    BowelFrequency.onceDaily => 'Uma vez ao dia',
    BowelFrequency.afewTimesPerWeek => 'Algumas vezes por semana',
    BowelFrequency.fewerThanThreeTimesPerWeek =>
      'Menos de três vezes por semana',
    BowelFrequency.custom => 'Personalizado',
  };
}

enum MenstrualFlow { light, moderate, heavy }

extension MenstrualFlowLabel on MenstrualFlow {
  String get label => switch (this) {
    MenstrualFlow.light => 'Leve',
    MenstrualFlow.moderate => 'Moderado',
    MenstrualFlow.heavy => 'Intenso',
  };
}

enum LeakageAmount { drops, small, moderate, large }

extension LeakageAmountLabel on LeakageAmount {
  String get label => switch (this) {
    LeakageAmount.drops => 'Gotas',
    LeakageAmount.small => 'Pequena',
    LeakageAmount.moderate => 'Moderada',
    LeakageAmount.large => 'Grande',
  };
}

enum PenetrationPainType { superficial, deep }

extension PenetrationPainTypeLabel on PenetrationPainType {
  String get label => switch (this) {
    PenetrationPainType.superficial => 'Superficial',
    PenetrationPainType.deep => 'Profunda',
  };
}

enum SexualDesire { preserved, reduced, absent, increased }

extension SexualDesireLabel on SexualDesire {
  String get label => switch (this) {
    SexualDesire.preserved => 'Preservado',
    SexualDesire.reduced => 'Reduzido',
    SexualDesire.absent => 'Ausente',
    SexualDesire.increased => 'Aumentado',
  };
}

enum BristolScale { type1, type2, type3, type4, type5, type6, type7 }

extension BristolScaleLabel on BristolScale {
  String get label => switch (this) {
    BristolScale.type1 => 'Tipo 1',
    BristolScale.type2 => 'Tipo 2',
    BristolScale.type3 => 'Tipo 3',
    BristolScale.type4 => 'Tipo 4',
    BristolScale.type5 => 'Tipo 5',
    BristolScale.type6 => 'Tipo 6',
    BristolScale.type7 => 'Tipo 7',
  };
}
