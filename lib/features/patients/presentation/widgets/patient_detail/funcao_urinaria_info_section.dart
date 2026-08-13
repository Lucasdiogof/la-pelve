import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class FuncaoUrinariaInfoSection extends StatelessWidget {
  const FuncaoUrinariaInfoSection(this.funcao, {super.key});

  final UrinaryFunction funcao;

  @override
  Widget build(BuildContext context) {
    final f = funcao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Função urinária'),
        InfoRow('Urgência', PatientDetailFormat.yesNo(f.urgency)),
        if (f.urgency == true)
          InfoRow(
            'Detalhe da urgência',
            PatientDetailFormat.text(f.urgencyDescription),
          ),
        InfoRow(
          'Perda associada à urgência',
          PatientDetailFormat.yesNo(f.urgencyAssociatedLeakage),
        ),
        InfoRow(
          'Incontinência de esforço',
          PatientDetailFormat.yesNo(f.stressIncontinence),
        ),
        if (f.stressIncontinence == true) ...[
          InfoRow(
            'Gatilhos',
            f.incontinenceTriggers.isEmpty
                ? PatientDetailFormat.naoInformado
                : f.incontinenceTriggers.map((g) => g.label).join(', '),
          ),
          if (f.incontinenceTriggers.contains(IncontinenceTrigger.other))
            InfoRow(
              'Qual outro gatilho',
              PatientDetailFormat.text(f.otherTriggerDescription),
            ),
        ],
        if (f.urgencyAssociatedLeakage == true || f.stressIncontinence == true)
          InfoRow(
            'Quantidade aproximada da perda',
            PatientDetailFormat.enumValue(f.leakageAmount, (v) => v.label),
          ),
        InfoRow(
          'Utiliza absorvente ou protetor',
          PatientDetailFormat.yesNo(f.usesPads),
        ),
        if (f.usesPads == true)
          InfoRow(
            'Quantos por dia',
            PatientDetailFormat.intValue(f.padsPerDay),
          ),
        InfoRow(
          'Dor ou ardência ao urinar',
          PatientDetailFormat.yesNo(f.painOrBurningWhenUrinating),
        ),
        InfoRow(
          'Jato urinário fraco',
          PatientDetailFormat.yesNo(f.weakUrinaryStream),
        ),
        InfoRow(
          'Enurese noturna',
          PatientDetailFormat.yesNo(f.nocturnalEnuresis),
        ),
        if (f.nocturnalEnuresis == true)
          InfoRow(
            'Detalhe da enurese',
            PatientDetailFormat.text(f.enuresisDescription),
          ),
        InfoRow('Hesitação', PatientDetailFormat.yesNo(f.hesitancy)),
        if (f.hesitancy == true)
          InfoRow(
            'Detalhe da hesitação',
            PatientDetailFormat.text(f.hesitancyDescription),
          ),
        InfoRow(
          'Esforço miccional',
          PatientDetailFormat.yesNo(f.urinaryStraining),
        ),
        if (f.urinaryStraining == true)
          InfoRow(
            'Detalhe do esforço miccional',
            PatientDetailFormat.text(f.urinaryStrainingDescription),
          ),
        InfoRow(
          'Gotejamento pós miccional',
          PatientDetailFormat.yesNo(f.postVoidDribbling),
        ),
        if (f.postVoidDribbling == true)
          InfoRow(
            'Detalhe do gotejamento',
            PatientDetailFormat.text(f.dribblingDescription),
          ),
        InfoRow(
          'Sensação de esvaziamento incompleto',
          PatientDetailFormat.yesNo(f.incompleteEmptying),
        ),
        if (f.incompleteEmptying == true)
          InfoRow(
            'Detalhe do esvaziamento',
            PatientDetailFormat.text(f.incompleteEmptyingDescription),
          ),
      ],
    );
  }
}
