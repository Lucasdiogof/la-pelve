import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/pregnancy.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class PersonalInfo extends Equatable {
  const PersonalInfo({
    this.name = '',
    this.age,
    this.phone = '',
    this.occupation = '',
    this.gender,
  });

  final String name;
  final int? age;
  final String phone;
  final String occupation;
  final Gender? gender;

  PersonalInfo copyWith({
    String? name,
    int? age,
    String? phone,
    String? occupation,
    Gender? gender,
  }) {
    return PersonalInfo(
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      occupation: occupation ?? this.occupation,
      gender: gender ?? this.gender,
    );
  }

  @override
  List<Object?> get props => [name, age, phone, occupation, gender];
}

class MedicalHistory extends Equatable {
  const MedicalHistory({
    this.chiefComplaint = '',
    this.hasMedicalDiagnosis,
    this.medicalDiagnosis,
    this.symptomsOnset = '',
    this.hadPreviousTreatment,
    this.treatmentDescription,
    this.hasChronicDiseases,
    this.chronicDiseasesDescription,
    this.takesContinuousMedication,
    this.medicationsDescription,
    this.smoking,
    this.consumesAlcohol,
    this.practicesPhysicalActivity,
    this.imagingExams,
  });

  final String chiefComplaint;
  final bool? hasMedicalDiagnosis;
  final String? medicalDiagnosis;
  final String symptomsOnset;
  final bool? hadPreviousTreatment;
  final String? treatmentDescription;
  final bool? hasChronicDiseases;
  final String? chronicDiseasesDescription;
  final bool? takesContinuousMedication;
  final String? medicationsDescription;
  final bool? smoking;
  final bool? consumesAlcohol;
  final bool? practicesPhysicalActivity;
  final String? imagingExams;

  MedicalHistory copyWith({
    String? chiefComplaint,
    Object? hasMedicalDiagnosis = kUnset,
    String? medicalDiagnosis,
    String? symptomsOnset,
    Object? hadPreviousTreatment = kUnset,
    String? treatmentDescription,
    Object? hasChronicDiseases = kUnset,
    String? chronicDiseasesDescription,
    Object? takesContinuousMedication = kUnset,
    String? medicationsDescription,
    Object? smoking = kUnset,
    Object? consumesAlcohol = kUnset,
    Object? practicesPhysicalActivity = kUnset,
    String? imagingExams,
  }) {
    return MedicalHistory(
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      hasMedicalDiagnosis: unsetOr(
        hasMedicalDiagnosis,
        this.hasMedicalDiagnosis,
      ),
      medicalDiagnosis: medicalDiagnosis ?? this.medicalDiagnosis,
      symptomsOnset: symptomsOnset ?? this.symptomsOnset,
      hadPreviousTreatment: unsetOr(
        hadPreviousTreatment,
        this.hadPreviousTreatment,
      ),
      treatmentDescription: treatmentDescription ?? this.treatmentDescription,
      hasChronicDiseases: unsetOr(hasChronicDiseases, this.hasChronicDiseases),
      chronicDiseasesDescription:
          chronicDiseasesDescription ?? this.chronicDiseasesDescription,
      takesContinuousMedication: unsetOr(
        takesContinuousMedication,
        this.takesContinuousMedication,
      ),
      medicationsDescription:
          medicationsDescription ?? this.medicationsDescription,
      smoking: unsetOr(smoking, this.smoking),
      consumesAlcohol: unsetOr(consumesAlcohol, this.consumesAlcohol),
      practicesPhysicalActivity: unsetOr(
        practicesPhysicalActivity,
        this.practicesPhysicalActivity,
      ),
      imagingExams: imagingExams ?? this.imagingExams,
    );
  }

  Map<String, dynamic> toJson() => {
    'chiefComplaint': chiefComplaint,
    'hasMedicalDiagnosis': hasMedicalDiagnosis,
    'medicalDiagnosis': medicalDiagnosis,
    'symptomsOnset': symptomsOnset,
    'hadPreviousTreatment': hadPreviousTreatment,
    'treatmentDescription': treatmentDescription,
    'hasChronicDiseases': hasChronicDiseases,
    'chronicDiseasesDescription': chronicDiseasesDescription,
    'takesContinuousMedication': takesContinuousMedication,
    'medicationsDescription': medicationsDescription,
    'smoking': smoking,
    'consumesAlcohol': consumesAlcohol,
    'practicesPhysicalActivity': practicesPhysicalActivity,
    'imagingExams': imagingExams,
  };

  factory MedicalHistory.fromJson(Map<String, dynamic> json) => MedicalHistory(
    chiefComplaint: json['chiefComplaint'] as String? ?? '',
    hasMedicalDiagnosis: json['hasMedicalDiagnosis'] as bool?,
    medicalDiagnosis: json['medicalDiagnosis'] as String?,
    symptomsOnset: json['symptomsOnset'] as String? ?? '',
    hadPreviousTreatment: json['hadPreviousTreatment'] as bool?,
    treatmentDescription: json['treatmentDescription'] as String?,
    hasChronicDiseases: json['hasChronicDiseases'] as bool?,
    chronicDiseasesDescription: json['chronicDiseasesDescription'] as String?,
    takesContinuousMedication: json['takesContinuousMedication'] as bool?,
    medicationsDescription: json['medicationsDescription'] as String?,
    smoking: json['smoking'] as bool?,
    consumesAlcohol: json['consumesAlcohol'] as bool?,
    practicesPhysicalActivity: json['practicesPhysicalActivity'] as bool?,
    imagingExams: json['imagingExams'] as String?,
  );

  @override
  List<Object?> get props => [
    chiefComplaint,
    hasMedicalDiagnosis,
    medicalDiagnosis,
    symptomsOnset,
    hadPreviousTreatment,
    treatmentDescription,
    hasChronicDiseases,
    chronicDiseasesDescription,
    takesContinuousMedication,
    medicationsDescription,
    smoking,
    consumesAlcohol,
    practicesPhysicalActivity,
    imagingExams,
  ];
}

class GynecologicalHistory extends Equatable {
  const GynecologicalHistory({
    this.ageAtMenarche,
    this.currentlyMenstruating,
    this.regularCycle,
    this.contraceptiveMethod,
    this.menopause,
    this.hormoneReplacementTherapy,
    this.hormoneReplacementTherapyDescription,
    this.menstrualFlow,
    this.crampsScore0to10,
    this.isInMenopause,
    this.approximateLastMenstruationDate,
    this.pelvicPainOutsidePeriod,
    this.bleedingOutsidePeriod,
    this.endometriosis,
    this.polycysticOvarySyndrome,
    this.recurrentUrinaryInfections,
    this.recurrentVaginalInfections,
  });

  final int? ageAtMenarche;
  final bool? currentlyMenstruating;
  final bool? regularCycle;
  final ContraceptiveMethod? contraceptiveMethod;
  final bool? menopause;
  final bool? hormoneReplacementTherapy;
  final String? hormoneReplacementTherapyDescription;
  final MenstrualFlow? menstrualFlow;
  final int? crampsScore0to10;
  final bool? isInMenopause;
  final DateTime? approximateLastMenstruationDate;
  final bool? pelvicPainOutsidePeriod;
  final bool? bleedingOutsidePeriod;
  final bool? endometriosis;
  final bool? polycysticOvarySyndrome;
  final bool? recurrentUrinaryInfections;
  final bool? recurrentVaginalInfections;

  GynecologicalHistory copyWith({
    int? ageAtMenarche,
    Object? currentlyMenstruating = kUnset,
    Object? regularCycle = kUnset,
    ContraceptiveMethod? contraceptiveMethod,
    Object? menopause = kUnset,
    Object? hormoneReplacementTherapy = kUnset,
    String? hormoneReplacementTherapyDescription,
    MenstrualFlow? menstrualFlow,
    int? crampsScore0to10,
    Object? isInMenopause = kUnset,
    DateTime? approximateLastMenstruationDate,
    Object? pelvicPainOutsidePeriod = kUnset,
    Object? bleedingOutsidePeriod = kUnset,
    Object? endometriosis = kUnset,
    Object? polycysticOvarySyndrome = kUnset,
    Object? recurrentUrinaryInfections = kUnset,
    Object? recurrentVaginalInfections = kUnset,
  }) {
    return GynecologicalHistory(
      ageAtMenarche: ageAtMenarche ?? this.ageAtMenarche,
      currentlyMenstruating: unsetOr(
        currentlyMenstruating,
        this.currentlyMenstruating,
      ),
      regularCycle: unsetOr(regularCycle, this.regularCycle),
      contraceptiveMethod: contraceptiveMethod ?? this.contraceptiveMethod,
      menopause: unsetOr(menopause, this.menopause),
      hormoneReplacementTherapy: unsetOr(
        hormoneReplacementTherapy,
        this.hormoneReplacementTherapy,
      ),
      hormoneReplacementTherapyDescription:
          hormoneReplacementTherapyDescription ??
          this.hormoneReplacementTherapyDescription,
      menstrualFlow: menstrualFlow ?? this.menstrualFlow,
      crampsScore0to10: crampsScore0to10 ?? this.crampsScore0to10,
      isInMenopause: unsetOr(isInMenopause, this.isInMenopause),
      approximateLastMenstruationDate:
          approximateLastMenstruationDate ??
          this.approximateLastMenstruationDate,
      pelvicPainOutsidePeriod: unsetOr(
        pelvicPainOutsidePeriod,
        this.pelvicPainOutsidePeriod,
      ),
      bleedingOutsidePeriod: unsetOr(
        bleedingOutsidePeriod,
        this.bleedingOutsidePeriod,
      ),
      endometriosis: unsetOr(endometriosis, this.endometriosis),
      polycysticOvarySyndrome: unsetOr(
        polycysticOvarySyndrome,
        this.polycysticOvarySyndrome,
      ),
      recurrentUrinaryInfections: unsetOr(
        recurrentUrinaryInfections,
        this.recurrentUrinaryInfections,
      ),
      recurrentVaginalInfections: unsetOr(
        recurrentVaginalInfections,
        this.recurrentVaginalInfections,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'ageAtMenarche': ageAtMenarche,
    'currentlyMenstruating': currentlyMenstruating,
    'regularCycle': regularCycle,
    'contraceptiveMethod': contraceptiveMethod?.name,
    'menopause': menopause,
    'hormoneReplacementTherapy': hormoneReplacementTherapy,
    'hormoneReplacementTherapyDescription':
        hormoneReplacementTherapyDescription,
    'menstrualFlow': menstrualFlow?.name,
    'crampsScore0to10': crampsScore0to10,
    'isInMenopause': isInMenopause,
    'approximateLastMenstruationDate': approximateLastMenstruationDate
        ?.toIso8601String(),
    'pelvicPainOutsidePeriod': pelvicPainOutsidePeriod,
    'bleedingOutsidePeriod': bleedingOutsidePeriod,
    'endometriosis': endometriosis,
    'polycysticOvarySyndrome': polycysticOvarySyndrome,
    'recurrentUrinaryInfections': recurrentUrinaryInfections,
    'recurrentVaginalInfections': recurrentVaginalInfections,
  };

  factory GynecologicalHistory.fromJson(Map<String, dynamic> json) =>
      GynecologicalHistory(
        ageAtMenarche: json['ageAtMenarche'] as int?,
        currentlyMenstruating: json['currentlyMenstruating'] as bool?,
        regularCycle: json['regularCycle'] as bool?,
        contraceptiveMethod: enumFromName(
          ContraceptiveMethod.values,
          json['contraceptiveMethod'],
        ),
        menopause: json['menopause'] as bool?,
        hormoneReplacementTherapy: json['hormoneReplacementTherapy'] as bool?,
        hormoneReplacementTherapyDescription:
            json['hormoneReplacementTherapyDescription'] as String?,
        menstrualFlow: enumFromName(
          MenstrualFlow.values,
          json['menstrualFlow'],
        ),
        crampsScore0to10: json['crampsScore0to10'] as int?,
        isInMenopause: json['isInMenopause'] as bool?,
        approximateLastMenstruationDate:
            json['approximateLastMenstruationDate'] == null
            ? null
            : DateTime.parse(json['approximateLastMenstruationDate'] as String),
        pelvicPainOutsidePeriod: json['pelvicPainOutsidePeriod'] as bool?,
        bleedingOutsidePeriod: json['bleedingOutsidePeriod'] as bool?,
        endometriosis: json['endometriosis'] as bool?,
        polycysticOvarySyndrome: json['polycysticOvarySyndrome'] as bool?,
        recurrentUrinaryInfections: json['recurrentUrinaryInfections'] as bool?,
        recurrentVaginalInfections: json['recurrentVaginalInfections'] as bool?,
      );

  @override
  List<Object?> get props => [
    ageAtMenarche,
    currentlyMenstruating,
    regularCycle,
    contraceptiveMethod,
    menopause,
    hormoneReplacementTherapy,
    hormoneReplacementTherapyDescription,
    menstrualFlow,
    crampsScore0to10,
    isInMenopause,
    approximateLastMenstruationDate,
    pelvicPainOutsidePeriod,
    bleedingOutsidePeriod,
    endometriosis,
    polycysticOvarySyndrome,
    recurrentUrinaryInfections,
    recurrentVaginalInfections,
  ];
}

class ObstetricHistory extends Equatable {
  const ObstetricHistory({
    this.hasBeenPregnant,
    this.pregnancyCount,
    this.pregnancies = const [],
    this.currentlyPregnant,
    this.desiredDeliveryMethod,
    this.gestationWeeks,
    this.estimatedDeliveryDate,
    this.highRiskPregnancy,
    this.highRiskPregnancyDescription,
  });

  final bool? hasBeenPregnant;
  final int? pregnancyCount;
  final List<Pregnancy> pregnancies;
  final bool? currentlyPregnant;
  final DeliveryMethod? desiredDeliveryMethod;
  final int? gestationWeeks;
  final DateTime? estimatedDeliveryDate;
  final bool? highRiskPregnancy;
  final String? highRiskPregnancyDescription;

  ObstetricHistory copyWith({
    Object? hasBeenPregnant = kUnset,
    int? pregnancyCount,
    List<Pregnancy>? pregnancies,
    Object? currentlyPregnant = kUnset,
    DeliveryMethod? desiredDeliveryMethod,
    int? gestationWeeks,
    DateTime? estimatedDeliveryDate,
    Object? highRiskPregnancy = kUnset,
    String? highRiskPregnancyDescription,
  }) {
    return ObstetricHistory(
      hasBeenPregnant: unsetOr(hasBeenPregnant, this.hasBeenPregnant),
      pregnancyCount: pregnancyCount ?? this.pregnancyCount,
      pregnancies: pregnancies ?? this.pregnancies,
      currentlyPregnant: unsetOr(currentlyPregnant, this.currentlyPregnant),
      desiredDeliveryMethod:
          desiredDeliveryMethod ?? this.desiredDeliveryMethod,
      gestationWeeks: gestationWeeks ?? this.gestationWeeks,
      estimatedDeliveryDate:
          estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      highRiskPregnancy: unsetOr(highRiskPregnancy, this.highRiskPregnancy),
      highRiskPregnancyDescription:
          highRiskPregnancyDescription ?? this.highRiskPregnancyDescription,
    );
  }

  Map<String, dynamic> toJson() => {
    'hasBeenPregnant': hasBeenPregnant,
    'pregnancyCount': pregnancyCount,
    'pregnancies': pregnancies.map((p) => p.toJson()).toList(),
    'currentlyPregnant': currentlyPregnant,
    'desiredDeliveryMethod': desiredDeliveryMethod?.name,
    'gestationWeeks': gestationWeeks,
    'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
    'highRiskPregnancy': highRiskPregnancy,
    'highRiskPregnancyDescription': highRiskPregnancyDescription,
  };

  factory ObstetricHistory.fromJson(Map<String, dynamic> json) =>
      ObstetricHistory(
        hasBeenPregnant: json['hasBeenPregnant'] as bool?,
        pregnancyCount: json['pregnancyCount'] as int?,
        pregnancies: (json['pregnancies'] as List<dynamic>? ?? [])
            .map((p) => Pregnancy.fromJson(p as Map<String, dynamic>))
            .toList(),
        currentlyPregnant: json['currentlyPregnant'] as bool?,
        desiredDeliveryMethod: enumFromName(
          DeliveryMethod.values,
          json['desiredDeliveryMethod'],
        ),
        gestationWeeks: json['gestationWeeks'] as int?,
        estimatedDeliveryDate: json['estimatedDeliveryDate'] == null
            ? null
            : DateTime.parse(json['estimatedDeliveryDate'] as String),
        highRiskPregnancy: json['highRiskPregnancy'] as bool?,
        highRiskPregnancyDescription:
            json['highRiskPregnancyDescription'] as String?,
      );

  @override
  List<Object?> get props => [
    hasBeenPregnant,
    pregnancyCount,
    pregnancies,
    currentlyPregnant,
    desiredDeliveryMethod,
    gestationWeeks,
    estimatedDeliveryDate,
    highRiskPregnancy,
    highRiskPregnancyDescription,
  ];
}

class SurgicalHistory extends Equatable {
  const SurgicalHistory({
    this.surgeries = const {},
    this.otherSurgeryDescription,
  });

  final Set<GynecologicalSurgery> surgeries;
  final String? otherSurgeryDescription;

  SurgicalHistory copyWith({
    Set<GynecologicalSurgery>? surgeries,
    String? otherSurgeryDescription,
  }) {
    return SurgicalHistory(
      surgeries: surgeries ?? this.surgeries,
      otherSurgeryDescription:
          otherSurgeryDescription ?? this.otherSurgeryDescription,
    );
  }

  Map<String, dynamic> toJson() => {
    'surgeries': surgeries.map((c) => c.name).toList(),
    'otherSurgeryDescription': otherSurgeryDescription,
  };

  factory SurgicalHistory.fromJson(Map<String, dynamic> json) =>
      SurgicalHistory(
        surgeries: (json['surgeries'] as List<dynamic>? ?? [])
            .map((name) => enumFromName(GynecologicalSurgery.values, name))
            .whereType<GynecologicalSurgery>()
            .toSet(),
        otherSurgeryDescription: json['otherSurgeryDescription'] as String?,
      );

  @override
  List<Object?> get props => [surgeries, otherSurgeryDescription];
}

class UrinaryFunction extends Equatable {
  const UrinaryFunction({
    this.urgency,
    this.urgencyDescription,
    this.stressIncontinence,
    this.incontinenceTriggers = const {},
    this.otherTriggerDescription,
    this.nocturnalEnuresis,
    this.enuresisDescription,
    this.hesitancy,
    this.hesitancyDescription,
    this.urinaryStraining,
    this.urinaryStrainingDescription,
    this.postVoidDribbling,
    this.dribblingDescription,
    this.incompleteEmptying,
    this.incompleteEmptyingDescription,
    this.urgencyAssociatedLeakage,
    this.leakageAmount,
    this.usesPads,
    this.padsPerDay,
    this.painOrBurningWhenUrinating,
    this.weakUrinaryStream,
  });

  final bool? urgency;
  final String? urgencyDescription;
  final bool? stressIncontinence;
  final Set<IncontinenceTrigger> incontinenceTriggers;
  final String? otherTriggerDescription;
  final bool? nocturnalEnuresis;
  final String? enuresisDescription;
  final bool? hesitancy;
  final String? hesitancyDescription;
  final bool? urinaryStraining;
  final String? urinaryStrainingDescription;
  final bool? postVoidDribbling;
  final String? dribblingDescription;
  final bool? incompleteEmptying;
  final String? incompleteEmptyingDescription;
  final bool? urgencyAssociatedLeakage;
  final LeakageAmount? leakageAmount;
  final bool? usesPads;
  final int? padsPerDay;
  final bool? painOrBurningWhenUrinating;
  final bool? weakUrinaryStream;

  UrinaryFunction copyWith({
    Object? urgency = kUnset,
    String? urgencyDescription,
    Object? stressIncontinence = kUnset,
    Set<IncontinenceTrigger>? incontinenceTriggers,
    String? otherTriggerDescription,
    Object? nocturnalEnuresis = kUnset,
    String? enuresisDescription,
    Object? hesitancy = kUnset,
    String? hesitancyDescription,
    Object? urinaryStraining = kUnset,
    String? urinaryStrainingDescription,
    Object? postVoidDribbling = kUnset,
    String? dribblingDescription,
    Object? incompleteEmptying = kUnset,
    String? incompleteEmptyingDescription,
    Object? urgencyAssociatedLeakage = kUnset,
    LeakageAmount? leakageAmount,
    Object? usesPads = kUnset,
    int? padsPerDay,
    Object? painOrBurningWhenUrinating = kUnset,
    Object? weakUrinaryStream = kUnset,
  }) {
    return UrinaryFunction(
      urgency: unsetOr(urgency, this.urgency),
      urgencyDescription: urgencyDescription ?? this.urgencyDescription,
      stressIncontinence: unsetOr(stressIncontinence, this.stressIncontinence),
      incontinenceTriggers: incontinenceTriggers ?? this.incontinenceTriggers,
      otherTriggerDescription:
          otherTriggerDescription ?? this.otherTriggerDescription,
      nocturnalEnuresis: unsetOr(nocturnalEnuresis, this.nocturnalEnuresis),
      enuresisDescription: enuresisDescription ?? this.enuresisDescription,
      hesitancy: unsetOr(hesitancy, this.hesitancy),
      hesitancyDescription: hesitancyDescription ?? this.hesitancyDescription,
      urinaryStraining: unsetOr(urinaryStraining, this.urinaryStraining),
      urinaryStrainingDescription:
          urinaryStrainingDescription ?? this.urinaryStrainingDescription,
      postVoidDribbling: unsetOr(postVoidDribbling, this.postVoidDribbling),
      dribblingDescription: dribblingDescription ?? this.dribblingDescription,
      incompleteEmptying: unsetOr(incompleteEmptying, this.incompleteEmptying),
      incompleteEmptyingDescription:
          incompleteEmptyingDescription ?? this.incompleteEmptyingDescription,
      urgencyAssociatedLeakage: unsetOr(
        urgencyAssociatedLeakage,
        this.urgencyAssociatedLeakage,
      ),
      leakageAmount: leakageAmount ?? this.leakageAmount,
      usesPads: unsetOr(usesPads, this.usesPads),
      padsPerDay: padsPerDay ?? this.padsPerDay,
      painOrBurningWhenUrinating: unsetOr(
        painOrBurningWhenUrinating,
        this.painOrBurningWhenUrinating,
      ),
      weakUrinaryStream: unsetOr(weakUrinaryStream, this.weakUrinaryStream),
    );
  }

  Map<String, dynamic> toJson() => {
    'urgency': urgency,
    'urgencyDescription': urgencyDescription,
    'stressIncontinence': stressIncontinence,
    'incontinenceTriggers': incontinenceTriggers.map((g) => g.name).toList(),
    'otherTriggerDescription': otherTriggerDescription,
    'nocturnalEnuresis': nocturnalEnuresis,
    'enuresisDescription': enuresisDescription,
    'hesitancy': hesitancy,
    'hesitancyDescription': hesitancyDescription,
    'urinaryStraining': urinaryStraining,
    'urinaryStrainingDescription': urinaryStrainingDescription,
    'postVoidDribbling': postVoidDribbling,
    'dribblingDescription': dribblingDescription,
    'incompleteEmptying': incompleteEmptying,
    'incompleteEmptyingDescription': incompleteEmptyingDescription,
    'urgencyAssociatedLeakage': urgencyAssociatedLeakage,
    'leakageAmount': leakageAmount?.name,
    'usesPads': usesPads,
    'padsPerDay': padsPerDay,
    'painOrBurningWhenUrinating': painOrBurningWhenUrinating,
    'weakUrinaryStream': weakUrinaryStream,
  };

  factory UrinaryFunction.fromJson(
    Map<String, dynamic> json,
  ) => UrinaryFunction(
    urgency: json['urgency'] as bool?,
    urgencyDescription: json['urgencyDescription'] as String?,
    stressIncontinence: json['stressIncontinence'] as bool?,
    incontinenceTriggers: (json['incontinenceTriggers'] as List<dynamic>? ?? [])
        .map((name) => enumFromName(IncontinenceTrigger.values, name))
        .whereType<IncontinenceTrigger>()
        .toSet(),
    otherTriggerDescription: json['otherTriggerDescription'] as String?,
    nocturnalEnuresis: json['nocturnalEnuresis'] as bool?,
    enuresisDescription: json['enuresisDescription'] as String?,
    hesitancy: json['hesitancy'] as bool?,
    hesitancyDescription: json['hesitancyDescription'] as String?,
    urinaryStraining: json['urinaryStraining'] as bool?,
    urinaryStrainingDescription: json['urinaryStrainingDescription'] as String?,
    postVoidDribbling: json['postVoidDribbling'] as bool?,
    dribblingDescription: json['dribblingDescription'] as String?,
    incompleteEmptying: json['incompleteEmptying'] as bool?,
    incompleteEmptyingDescription:
        json['incompleteEmptyingDescription'] as String?,
    urgencyAssociatedLeakage: json['urgencyAssociatedLeakage'] as bool?,
    leakageAmount: enumFromName(LeakageAmount.values, json['leakageAmount']),
    usesPads: json['usesPads'] as bool?,
    padsPerDay: json['padsPerDay'] as int?,
    painOrBurningWhenUrinating: json['painOrBurningWhenUrinating'] as bool?,
    weakUrinaryStream: json['weakUrinaryStream'] as bool?,
  );

  @override
  List<Object?> get props => [
    urgency,
    urgencyDescription,
    stressIncontinence,
    incontinenceTriggers,
    otherTriggerDescription,
    nocturnalEnuresis,
    enuresisDescription,
    hesitancy,
    hesitancyDescription,
    urinaryStraining,
    urinaryStrainingDescription,
    postVoidDribbling,
    dribblingDescription,
    incompleteEmptying,
    incompleteEmptyingDescription,
    urgencyAssociatedLeakage,
    leakageAmount,
    usesPads,
    padsPerDay,
    painOrBurningWhenUrinating,
    weakUrinaryStream,
  ];
}

class SexualFunction extends Equatable {
  const SexualFunction({
    this.sexuallyActive,
    this.needsLubricant,
    this.orgasmDifficulty,
    this.orgasmDifficultyDescription,
    this.sexualDesire,
    this.sexualActivityFrequency,
    this.painDuringPenetration,
    this.penetrationPainType,
    this.painDuringOrAfterIntercourse,
    this.painIntensity0to10,
    this.dryness,
  });

  final bool? sexuallyActive;
  final bool? needsLubricant;
  final bool? orgasmDifficulty;
  final String? orgasmDifficultyDescription;
  final SexualDesire? sexualDesire;
  final String? sexualActivityFrequency;
  final bool? painDuringPenetration;
  final PenetrationPainType? penetrationPainType;
  final bool? painDuringOrAfterIntercourse;
  final int? painIntensity0to10;
  final bool? dryness;

  SexualFunction copyWith({
    Object? sexuallyActive = kUnset,
    Object? needsLubricant = kUnset,
    Object? orgasmDifficulty = kUnset,
    String? orgasmDifficultyDescription,
    SexualDesire? sexualDesire,
    String? sexualActivityFrequency,
    Object? painDuringPenetration = kUnset,
    PenetrationPainType? penetrationPainType,
    Object? painDuringOrAfterIntercourse = kUnset,
    int? painIntensity0to10,
    Object? dryness = kUnset,
  }) {
    return SexualFunction(
      sexuallyActive: unsetOr(sexuallyActive, this.sexuallyActive),
      needsLubricant: unsetOr(needsLubricant, this.needsLubricant),
      orgasmDifficulty: unsetOr(orgasmDifficulty, this.orgasmDifficulty),
      orgasmDifficultyDescription:
          orgasmDifficultyDescription ?? this.orgasmDifficultyDescription,
      sexualDesire: sexualDesire ?? this.sexualDesire,
      sexualActivityFrequency:
          sexualActivityFrequency ?? this.sexualActivityFrequency,
      painDuringPenetration: unsetOr(
        painDuringPenetration,
        this.painDuringPenetration,
      ),
      penetrationPainType: penetrationPainType ?? this.penetrationPainType,
      painDuringOrAfterIntercourse: unsetOr(
        painDuringOrAfterIntercourse,
        this.painDuringOrAfterIntercourse,
      ),
      painIntensity0to10: painIntensity0to10 ?? this.painIntensity0to10,
      dryness: unsetOr(dryness, this.dryness),
    );
  }

  Map<String, dynamic> toJson() => {
    'sexuallyActive': sexuallyActive,
    'needsLubricant': needsLubricant,
    'orgasmDifficulty': orgasmDifficulty,
    'orgasmDifficultyDescription': orgasmDifficultyDescription,
    'sexualDesire': sexualDesire?.name,
    'sexualActivityFrequency': sexualActivityFrequency,
    'painDuringPenetration': painDuringPenetration,
    'penetrationPainType': penetrationPainType?.name,
    'painDuringOrAfterIntercourse': painDuringOrAfterIntercourse,
    'painIntensity0to10': painIntensity0to10,
    'dryness': dryness,
  };

  factory SexualFunction.fromJson(Map<String, dynamic> json) => SexualFunction(
    sexuallyActive: json['sexuallyActive'] as bool?,
    needsLubricant: json['needsLubricant'] as bool?,
    orgasmDifficulty: json['orgasmDifficulty'] as bool?,
    orgasmDifficultyDescription: json['orgasmDifficultyDescription'] as String?,
    sexualDesire: enumFromName(SexualDesire.values, json['sexualDesire']),
    sexualActivityFrequency: json['sexualActivityFrequency'] as String?,
    painDuringPenetration: json['painDuringPenetration'] as bool?,
    penetrationPainType: enumFromName(
      PenetrationPainType.values,
      json['penetrationPainType'],
    ),
    painDuringOrAfterIntercourse: json['painDuringOrAfterIntercourse'] as bool?,
    painIntensity0to10: json['painIntensity0to10'] as int?,
    dryness: json['dryness'] as bool?,
  );

  @override
  List<Object?> get props => [
    sexuallyActive,
    needsLubricant,
    orgasmDifficulty,
    orgasmDifficultyDescription,
    sexualDesire,
    sexualActivityFrequency,
    painDuringPenetration,
    penetrationPainType,
    painDuringOrAfterIntercourse,
    painIntensity0to10,
    dryness,
  ];
}

class BowelFunction extends Equatable {
  const BowelFunction({
    this.bowelFrequency,
    this.customFrequencyValue,
    this.usesLaxative,
    this.laxativeDescription,
    this.strainsToDefecate,
    this.painToDefecate,
    this.incompleteEmptying,
    this.gasIncontinence,
    this.fecalIncontinence,
    this.bristolScale,
    this.obstructionSensation,
    this.fecalUrgency,
    this.hemorrhoids,
  });

  final BowelFrequency? bowelFrequency;
  final int? customFrequencyValue;
  final bool? usesLaxative;
  final String? laxativeDescription;
  final bool? strainsToDefecate;
  final bool? painToDefecate;
  final bool? incompleteEmptying;
  final bool? gasIncontinence;
  final bool? fecalIncontinence;
  final BristolScale? bristolScale;
  final bool? obstructionSensation;
  final bool? fecalUrgency;
  final bool? hemorrhoids;

  BowelFunction copyWith({
    BowelFrequency? bowelFrequency,
    int? customFrequencyValue,
    Object? usesLaxative = kUnset,
    String? laxativeDescription,
    Object? strainsToDefecate = kUnset,
    Object? painToDefecate = kUnset,
    Object? incompleteEmptying = kUnset,
    Object? gasIncontinence = kUnset,
    Object? fecalIncontinence = kUnset,
    BristolScale? bristolScale,
    Object? obstructionSensation = kUnset,
    Object? fecalUrgency = kUnset,
    Object? hemorrhoids = kUnset,
  }) {
    return BowelFunction(
      bowelFrequency: bowelFrequency ?? this.bowelFrequency,
      customFrequencyValue: customFrequencyValue ?? this.customFrequencyValue,
      usesLaxative: unsetOr(usesLaxative, this.usesLaxative),
      laxativeDescription: laxativeDescription ?? this.laxativeDescription,
      strainsToDefecate: unsetOr(strainsToDefecate, this.strainsToDefecate),
      painToDefecate: unsetOr(painToDefecate, this.painToDefecate),
      incompleteEmptying: unsetOr(incompleteEmptying, this.incompleteEmptying),
      gasIncontinence: unsetOr(gasIncontinence, this.gasIncontinence),
      fecalIncontinence: unsetOr(fecalIncontinence, this.fecalIncontinence),
      bristolScale: bristolScale ?? this.bristolScale,
      obstructionSensation: unsetOr(
        obstructionSensation,
        this.obstructionSensation,
      ),
      fecalUrgency: unsetOr(fecalUrgency, this.fecalUrgency),
      hemorrhoids: unsetOr(hemorrhoids, this.hemorrhoids),
    );
  }

  Map<String, dynamic> toJson() => {
    'bowelFrequency': bowelFrequency?.name,
    'customFrequencyValue': customFrequencyValue,
    'usesLaxative': usesLaxative,
    'laxativeDescription': laxativeDescription,
    'strainsToDefecate': strainsToDefecate,
    'painToDefecate': painToDefecate,
    'incompleteEmptying': incompleteEmptying,
    'gasIncontinence': gasIncontinence,
    'fecalIncontinence': fecalIncontinence,
    'bristolScale': bristolScale?.name,
    'obstructionSensation': obstructionSensation,
    'fecalUrgency': fecalUrgency,
    'hemorrhoids': hemorrhoids,
  };

  factory BowelFunction.fromJson(Map<String, dynamic> json) => BowelFunction(
    bowelFrequency: enumFromName(BowelFrequency.values, json['bowelFrequency']),
    customFrequencyValue: json['customFrequencyValue'] as int?,
    usesLaxative: json['usesLaxative'] as bool?,
    laxativeDescription: json['laxativeDescription'] as String?,
    strainsToDefecate: json['strainsToDefecate'] as bool?,
    painToDefecate: json['painToDefecate'] as bool?,
    incompleteEmptying: json['incompleteEmptying'] as bool?,
    gasIncontinence: json['gasIncontinence'] as bool?,
    fecalIncontinence: json['fecalIncontinence'] as bool?,
    bristolScale: enumFromName(BristolScale.values, json['bristolScale']),
    obstructionSensation: json['obstructionSensation'] as bool?,
    fecalUrgency: json['fecalUrgency'] as bool?,
    hemorrhoids: json['hemorrhoids'] as bool?,
  );

  @override
  List<Object?> get props => [
    bowelFrequency,
    customFrequencyValue,
    usesLaxative,
    laxativeDescription,
    strainsToDefecate,
    painToDefecate,
    incompleteEmptying,
    gasIncontinence,
    fecalIncontinence,
    bristolScale,
    obstructionSensation,
    fecalUrgency,
    hemorrhoids,
  ];
}

class TreatmentPlan extends Equatable {
  const TreatmentPlan({
    this.physiotherapyDiagnosis,
    this.treatmentGoal,
    this.treatmentApproach,
    this.suggestedFrequency,
  });

  final String? physiotherapyDiagnosis;
  final String? treatmentGoal;
  final String? treatmentApproach;
  final String? suggestedFrequency;

  TreatmentPlan copyWith({
    String? physiotherapyDiagnosis,
    String? treatmentGoal,
    String? treatmentApproach,
    String? suggestedFrequency,
  }) {
    return TreatmentPlan(
      physiotherapyDiagnosis:
          physiotherapyDiagnosis ?? this.physiotherapyDiagnosis,
      treatmentGoal: treatmentGoal ?? this.treatmentGoal,
      treatmentApproach: treatmentApproach ?? this.treatmentApproach,
      suggestedFrequency: suggestedFrequency ?? this.suggestedFrequency,
    );
  }

  Map<String, dynamic> toJson() => {
    'physiotherapyDiagnosis': physiotherapyDiagnosis,
    'treatmentGoal': treatmentGoal,
    'treatmentApproach': treatmentApproach,
    'suggestedFrequency': suggestedFrequency,
  };

  factory TreatmentPlan.fromJson(Map<String, dynamic> json) => TreatmentPlan(
    physiotherapyDiagnosis: json['physiotherapyDiagnosis'] as String?,
    treatmentGoal: json['treatmentGoal'] as String?,
    treatmentApproach: json['treatmentApproach'] as String?,
    suggestedFrequency: json['suggestedFrequency'] as String?,
  );

  @override
  List<Object?> get props => [
    physiotherapyDiagnosis,
    treatmentGoal,
    treatmentApproach,
    suggestedFrequency,
  ];
}

class Discharge extends Equatable {
  const Discharge({required this.date, required this.reason, this.finalNote});

  final DateTime date;
  final DischargeReason reason;
  final String? finalNote;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'reason': reason.name,
    'finalNote': finalNote,
  };

  factory Discharge.fromJson(Map<String, dynamic> json) => Discharge(
    date: DateTime.parse(json['date'] as String),
    reason:
        enumFromName(DischargeReason.values, json['reason']) ??
        DischargeReason.other,
    finalNote: json['finalNote'] as String?,
  );

  @override
  List<Object?> get props => [date, reason, finalNote];
}

class Patient extends Equatable {
  const Patient({
    required this.id,
    required this.createdAt,
    this.personalInfo = const PersonalInfo(),
    this.medicalHistory = const MedicalHistory(),
    this.gynecologicalHistory = const GynecologicalHistory(),
    this.obstetricHistory = const ObstetricHistory(),
    this.surgicalHistory = const SurgicalHistory(),
    this.urinaryFunction = const UrinaryFunction(),
    this.sexualFunction = const SexualFunction(),
    this.bowelFunction = const BowelFunction(),
    this.treatmentPlan = const TreatmentPlan(),
    this.discharge,
    this.consultationFee,
  });

  final String id;
  final DateTime createdAt;
  final PersonalInfo personalInfo;
  final MedicalHistory medicalHistory;
  final GynecologicalHistory gynecologicalHistory;
  final ObstetricHistory obstetricHistory;
  final SurgicalHistory surgicalHistory;
  final UrinaryFunction urinaryFunction;
  final SexualFunction sexualFunction;
  final BowelFunction bowelFunction;
  final TreatmentPlan treatmentPlan;
  final Discharge? discharge;
  final double? consultationFee;

  Patient copyWith({
    PersonalInfo? personalInfo,
    MedicalHistory? medicalHistory,
    GynecologicalHistory? gynecologicalHistory,
    ObstetricHistory? obstetricHistory,
    SurgicalHistory? surgicalHistory,
    UrinaryFunction? urinaryFunction,
    SexualFunction? sexualFunction,
    BowelFunction? bowelFunction,
    TreatmentPlan? treatmentPlan,
    Object? discharge = kUnset,
    double? consultationFee,
  }) {
    return Patient(
      id: id,
      createdAt: createdAt,
      personalInfo: personalInfo ?? this.personalInfo,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      gynecologicalHistory: gynecologicalHistory ?? this.gynecologicalHistory,
      obstetricHistory: obstetricHistory ?? this.obstetricHistory,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      urinaryFunction: urinaryFunction ?? this.urinaryFunction,
      sexualFunction: sexualFunction ?? this.sexualFunction,
      bowelFunction: bowelFunction ?? this.bowelFunction,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      discharge: unsetOr(discharge, this.discharge),
      consultationFee: consultationFee ?? this.consultationFee,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'name': personalInfo.name,
    'age': personalInfo.age,
    'phone': personalInfo.phone,
    'occupation': personalInfo.occupation,
    'gender': personalInfo.gender?.name,
    'medical_history': medicalHistory.toJson(),
    'gynecological_history': gynecologicalHistory.toJson(),
    'obstetric_history': obstetricHistory.toJson(),
    'surgical_history': surgicalHistory.toJson(),
    'urinary_function': urinaryFunction.toJson(),
    'sexual_function': sexualFunction.toJson(),
    'bowel_function': bowelFunction.toJson(),
    'treatment_plan': treatmentPlan.toJson(),
    'discharge': discharge?.toJson(),
    'consultation_fee': consultationFee,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    personalInfo: PersonalInfo(
      name: json['name'] as String? ?? '',
      age: json['age'] as int?,
      phone: json['phone'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      gender: enumFromName(Gender.values, json['gender']),
    ),
    medicalHistory: MedicalHistory.fromJson(
      (json['medical_history'] as Map<String, dynamic>?) ?? {},
    ),
    gynecologicalHistory: GynecologicalHistory.fromJson(
      (json['gynecological_history'] as Map<String, dynamic>?) ?? {},
    ),
    obstetricHistory: ObstetricHistory.fromJson(
      (json['obstetric_history'] as Map<String, dynamic>?) ?? {},
    ),
    surgicalHistory: SurgicalHistory.fromJson(
      (json['surgical_history'] as Map<String, dynamic>?) ?? {},
    ),
    urinaryFunction: UrinaryFunction.fromJson(
      (json['urinary_function'] as Map<String, dynamic>?) ?? {},
    ),
    sexualFunction: SexualFunction.fromJson(
      (json['sexual_function'] as Map<String, dynamic>?) ?? {},
    ),
    bowelFunction: BowelFunction.fromJson(
      (json['bowel_function'] as Map<String, dynamic>?) ?? {},
    ),
    treatmentPlan: TreatmentPlan.fromJson(
      (json['treatment_plan'] as Map<String, dynamic>?) ?? {},
    ),
    discharge: json['discharge'] == null
        ? null
        : Discharge.fromJson(json['discharge'] as Map<String, dynamic>),
    consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
  );

  @override
  List<Object?> get props => [
    id,
    createdAt,
    personalInfo,
    medicalHistory,
    gynecologicalHistory,
    obstetricHistory,
    surgicalHistory,
    urinaryFunction,
    sexualFunction,
    bowelFunction,
    treatmentPlan,
    discharge,
    consultationFee,
  ];
}
