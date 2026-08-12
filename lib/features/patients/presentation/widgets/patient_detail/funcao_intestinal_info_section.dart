import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class FuncaoIntestinalInfoSection extends StatelessWidget {
  const FuncaoIntestinalInfoSection(this.funcao, {super.key});

  final FuncaoIntestinal funcao;

  @override
  Widget build(BuildContext context) {
    final f = funcao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Função intestinal'),
        InfoRow(
          'Frequência evacuatória',
          PatientDetailFormat.enumValue(
            f.frequenciaEvacuatoria,
            (v) => v.label,
          ),
        ),
        if (f.frequenciaEvacuatoria == FrequenciaEvacuatoria.personalizado)
          InfoRow(
            'Quantas vezes por semana',
            PatientDetailFormat.intValue(f.frequenciaPersonalizadaValor),
          ),
        InfoRow('Usa laxante', PatientDetailFormat.yesNo(f.usaLaxante)),
        if (f.usaLaxante == true)
          InfoRow(
            'Qual laxante e frequência',
            PatientDetailFormat.text(f.descricaoLaxante),
          ),
        InfoRow(
          'Faz força para evacuar',
          PatientDetailFormat.yesNo(f.forcaParaEvacuar),
        ),
        InfoRow(
          'Sente dor para evacuar',
          PatientDetailFormat.yesNo(f.dorParaEvacuar),
        ),
        InfoRow(
          'Sensação de esvaziamento incompleto',
          PatientDetailFormat.yesNo(f.esvaziamentoIncompleto),
        ),
        InfoRow(
          'Sensação de obstrução',
          PatientDetailFormat.yesNo(f.sensacaoObstrucao),
        ),
        InfoRow('Urgência fecal', PatientDetailFormat.yesNo(f.urgenciaFecal)),
        InfoRow(
          'Presença de hemorroidas',
          PatientDetailFormat.yesNo(f.presencaHemorroidas),
        ),
        InfoRow('Perde gases', PatientDetailFormat.yesNo(f.perdeGases)),
        InfoRow('Perde fezes', PatientDetailFormat.yesNo(f.perdeFezes)),
        InfoRow(
          'Escala de Bristol',
          PatientDetailFormat.enumValue(f.escalaBristol, (v) => v.label),
        ),
      ],
    );
  }
}
