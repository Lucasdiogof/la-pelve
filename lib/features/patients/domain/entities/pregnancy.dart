import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class Pregnancy extends Equatable {
  const Pregnancy({
    this.pregnancyLoss,
    this.lossDescription,
    this.deliveryMethod,
    this.deliveryComplication,
    this.hadComplications,
    this.complicationDescription,
    this.approximateBabyWeight,
    this.forcepsOrVacuumUse,
  });

  final bool? pregnancyLoss;
  final String? lossDescription;
  final DeliveryMethod? deliveryMethod;
  final DeliveryComplication? deliveryComplication;
  final bool? hadComplications;
  final String? complicationDescription;
  final String? approximateBabyWeight;
  final bool? forcepsOrVacuumUse;

  Pregnancy copyWith({
    Object? pregnancyLoss = kUnset,
    String? lossDescription,
    DeliveryMethod? deliveryMethod,
    DeliveryComplication? deliveryComplication,
    Object? hadComplications = kUnset,
    String? complicationDescription,
    String? approximateBabyWeight,
    Object? forcepsOrVacuumUse = kUnset,
  }) {
    return Pregnancy(
      pregnancyLoss: unsetOr(pregnancyLoss, this.pregnancyLoss),
      lossDescription: lossDescription ?? this.lossDescription,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryComplication: deliveryComplication ?? this.deliveryComplication,
      hadComplications: unsetOr(hadComplications, this.hadComplications),
      complicationDescription:
          complicationDescription ?? this.complicationDescription,
      approximateBabyWeight:
          approximateBabyWeight ?? this.approximateBabyWeight,
      forcepsOrVacuumUse: unsetOr(forcepsOrVacuumUse, this.forcepsOrVacuumUse),
    );
  }

  Map<String, dynamic> toJson() => {
    'pregnancyLoss': pregnancyLoss,
    'lossDescription': lossDescription,
    'deliveryMethod': deliveryMethod?.name,
    'deliveryComplication': deliveryComplication?.name,
    'hadComplications': hadComplications,
    'complicationDescription': complicationDescription,
    'approximateBabyWeight': approximateBabyWeight,
    'forcepsOrVacuumUse': forcepsOrVacuumUse,
  };

  factory Pregnancy.fromJson(Map<String, dynamic> json) => Pregnancy(
    pregnancyLoss: json['pregnancyLoss'] as bool?,
    lossDescription: json['lossDescription'] as String?,
    deliveryMethod: enumFromName(DeliveryMethod.values, json['deliveryMethod']),
    deliveryComplication: enumFromName(
      DeliveryComplication.values,
      json['deliveryComplication'],
    ),
    hadComplications: json['hadComplications'] as bool?,
    complicationDescription: json['complicationDescription'] as String?,
    approximateBabyWeight: json['approximateBabyWeight'] as String?,
    forcepsOrVacuumUse: json['forcepsOrVacuumUse'] as bool?,
  );

  @override
  List<Object?> get props => [
    pregnancyLoss,
    lossDescription,
    deliveryMethod,
    deliveryComplication,
    hadComplications,
    complicationDescription,
    approximateBabyWeight,
    forcepsOrVacuumUse,
  ];
}
