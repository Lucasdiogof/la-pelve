import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class HistoricoObstetricoInfoSection extends StatelessWidget {
  const HistoricoObstetricoInfoSection(this.historico, {super.key});

  final HistoricoObstetrico historico;

  @override
  Widget build(BuildContext context) {
    final h = historico;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Histórico obstétrico'),
        InfoRow(
          'Está gestante atualmente',
          PatientDetailFormat.yesNo(h.estaGestanteAtualmente),
        ),
        if (h.estaGestanteAtualmente == true) ...[
          InfoRow(
            'Via de parto desejado',
            PatientDetailFormat.enumValue(h.viaDePartoDesejado, (v) => v.label),
          ),
          InfoRow(
            'Quantas semanas',
            PatientDetailFormat.intValue(h.semanasGestacao),
          ),
          InfoRow(
            'Data provável do parto',
            PatientDetailFormat.dateValue(h.dataProvavelParto),
          ),
          InfoRow(
            'Gestação de risco',
            PatientDetailFormat.yesNo(h.gestacaoDeRisco),
          ),
          if (h.gestacaoDeRisco == true)
            InfoRow(
              'Detalhe da gestação de risco',
              PatientDetailFormat.text(h.descricaoGestacaoRisco),
            ),
        ],
        InfoRow('Já engravidou', PatientDetailFormat.yesNo(h.jaEngravidou)),
        if (h.jaEngravidou == true) ...[
          InfoRow(
            'Quantas gestações',
            PatientDetailFormat.intValue(h.numeroGestacoes),
          ),
          for (var i = 0; i < h.gestacoes.length; i++)
            GestacaoCard(index: i, gestacao: h.gestacoes[i]),
        ],
      ],
    );
  }
}
