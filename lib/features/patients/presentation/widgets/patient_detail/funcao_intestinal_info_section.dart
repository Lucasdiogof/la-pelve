import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class FuncaoIntestinalInfoSection extends StatelessWidget {
  const FuncaoIntestinalInfoSection(this.funcao, {super.key});

  final BowelFunction funcao;

  @override
  Widget build(BuildContext context) {
    final f = funcao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Função intestinal'),
        InfoRow(
          'Frequência evacuatória',
          PatientDetailFormat.enumValue(f.bowelFrequency, (v) => v.label),
        ),
        if (f.bowelFrequency == BowelFrequency.custom)
          InfoRow(
            'Quantas vezes por semana',
            PatientDetailFormat.intValue(f.customFrequencyValue),
          ),
        InfoRow('Usa laxante', PatientDetailFormat.yesNo(f.usesLaxative)),
        if (f.usesLaxative == true)
          InfoRow(
            'Qual laxante e frequência',
            PatientDetailFormat.text(f.laxativeDescription),
          ),
        InfoRow(
          'Faz força para evacuar',
          PatientDetailFormat.yesNo(f.strainsToDefecate),
        ),
        InfoRow(
          'Sente dor para evacuar',
          PatientDetailFormat.yesNo(f.painToDefecate),
        ),
        InfoRow(
          'Sensação de esvaziamento incompleto',
          PatientDetailFormat.yesNo(f.incompleteEmptying),
        ),
        InfoRow(
          'Sensação de obstrução',
          PatientDetailFormat.yesNo(f.obstructionSensation),
        ),
        InfoRow('Urgência fecal', PatientDetailFormat.yesNo(f.fecalUrgency)),
        InfoRow(
          'Presença de hemorroidas',
          PatientDetailFormat.yesNo(f.hemorrhoids),
        ),
        InfoRow('Perde gases', PatientDetailFormat.yesNo(f.gasIncontinence)),
        InfoRow('Perde fezes', PatientDetailFormat.yesNo(f.fecalIncontinence)),
        InfoRow(
          'Escala de Bristol',
          PatientDetailFormat.enumValue(f.bristolScale, (v) => v.label),
        ),
      ],
    );
  }
}
