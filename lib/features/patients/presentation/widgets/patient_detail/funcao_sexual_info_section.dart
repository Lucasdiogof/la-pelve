import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class FuncaoSexualInfoSection extends StatelessWidget {
  const FuncaoSexualInfoSection(this.funcao, {super.key});

  final FuncaoSexual funcao;

  @override
  Widget build(BuildContext context) {
    final f = funcao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Função sexual'),
        InfoRow(
          'Vida sexual ativa',
          PatientDetailFormat.yesNo(f.vidaSexualAtiva),
        ),
        if (f.vidaSexualAtiva == true) ...[
          InfoRow(
            'Frequência de atividade sexual',
            PatientDetailFormat.text(f.frequenciaAtividadeSexual),
          ),
          InfoRow(
            'Precisa usar lubrificante',
            PatientDetailFormat.yesNo(f.precisaLubrificante),
          ),
          InfoRow(
            'Sensação de ressecamento',
            PatientDetailFormat.yesNo(f.ressecamento),
          ),
          InfoRow(
            'Dificuldade para atingir o orgasmo',
            PatientDetailFormat.yesNo(f.dificuldadeOrgasmo),
          ),
          if (f.dificuldadeOrgasmo == true)
            InfoRow(
              'Detalhe',
              PatientDetailFormat.text(f.descricaoDificuldadeOrgasmo),
            ),
          InfoRow(
            'Dor na penetração',
            PatientDetailFormat.yesNo(f.dorNaPenetracao),
          ),
          if (f.dorNaPenetracao == true)
            InfoRow(
              'Tipo de dor',
              PatientDetailFormat.enumValue(
                f.tipoDorPenetracao,
                (v) => v.label,
              ),
            ),
          InfoRow(
            'Dor durante ou depois da relação',
            PatientDetailFormat.yesNo(f.dorDuranteOuDepoisRelacao),
          ),
          if (f.dorNaPenetracao == true || f.dorDuranteOuDepoisRelacao == true)
            InfoRow(
              'Intensidade da dor (0-10)',
              PatientDetailFormat.intValue(f.intensidadeDor0a10),
            ),
          InfoRow(
            'Desejo sexual',
            PatientDetailFormat.enumValue(f.desejoSexual, (v) => v.label),
          ),
        ],
      ],
    );
  }
}
