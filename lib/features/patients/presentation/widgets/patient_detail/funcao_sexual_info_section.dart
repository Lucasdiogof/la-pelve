import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class FuncaoSexualInfoSection extends StatelessWidget {
  const FuncaoSexualInfoSection(this.funcao, {super.key});

  final SexualFunction funcao;

  @override
  Widget build(BuildContext context) {
    final f = funcao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Função sexual'),
        InfoRow(
          'Vida sexual ativa',
          PatientDetailFormat.yesNo(f.sexuallyActive),
        ),
        if (f.sexuallyActive == true) ...[
          InfoRow(
            'Frequência de atividade sexual',
            PatientDetailFormat.text(f.sexualActivityFrequency),
          ),
          InfoRow(
            'Precisa usar lubrificante',
            PatientDetailFormat.yesNo(f.needsLubricant),
          ),
          InfoRow(
            'Sensação de ressecamento',
            PatientDetailFormat.yesNo(f.dryness),
          ),
          InfoRow(
            'Dificuldade para atingir o orgasmo',
            PatientDetailFormat.yesNo(f.orgasmDifficulty),
          ),
          if (f.orgasmDifficulty == true)
            InfoRow(
              'Detalhe',
              PatientDetailFormat.text(f.orgasmDifficultyDescription),
            ),
          InfoRow(
            'Dor na penetração',
            PatientDetailFormat.yesNo(f.painDuringPenetration),
          ),
          if (f.painDuringPenetration == true)
            InfoRow(
              'Tipo de dor',
              PatientDetailFormat.enumValue(
                f.penetrationPainType,
                (v) => v.label,
              ),
            ),
          InfoRow(
            'Dor durante ou depois da relação',
            PatientDetailFormat.yesNo(f.painDuringOrAfterIntercourse),
          ),
          if (f.painDuringPenetration == true ||
              f.painDuringOrAfterIntercourse == true)
            InfoRow(
              'Intensidade da dor (0-10)',
              PatientDetailFormat.intValue(f.painIntensity0to10),
            ),
          InfoRow(
            'Desejo sexual',
            PatientDetailFormat.enumValue(f.sexualDesire, (v) => v.label),
          ),
        ],
      ],
    );
  }
}
