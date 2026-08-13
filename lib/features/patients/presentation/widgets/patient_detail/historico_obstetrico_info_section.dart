import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class HistoricoObstetricoInfoSection extends StatelessWidget {
  const HistoricoObstetricoInfoSection(this.historico, {super.key});

  final ObstetricHistory historico;

  @override
  Widget build(BuildContext context) {
    final h = historico;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Histórico obstétrico'),
        InfoRow(
          'Está gestante atualmente',
          PatientDetailFormat.yesNo(h.currentlyPregnant),
        ),
        if (h.currentlyPregnant == true) ...[
          InfoRow(
            'Via de parto desejado',
            PatientDetailFormat.enumValue(
              h.desiredDeliveryMethod,
              (v) => v.label,
            ),
          ),
          InfoRow(
            'Quantas semanas',
            PatientDetailFormat.intValue(h.gestationWeeks),
          ),
          InfoRow(
            'Data provável do parto',
            PatientDetailFormat.dateValue(h.estimatedDeliveryDate),
          ),
          InfoRow(
            'Gestação de risco',
            PatientDetailFormat.yesNo(h.highRiskPregnancy),
          ),
          if (h.highRiskPregnancy == true)
            InfoRow(
              'Detalhe da gestação de risco',
              PatientDetailFormat.text(h.highRiskPregnancyDescription),
            ),
        ],
        InfoRow('Já engravidou', PatientDetailFormat.yesNo(h.hasBeenPregnant)),
        if (h.hasBeenPregnant == true) ...[
          InfoRow(
            'Quantas gestações',
            PatientDetailFormat.intValue(h.pregnancyCount),
          ),
          for (var i = 0; i < h.pregnancies.length; i++)
            GestacaoCard(index: i, pregnancy: h.pregnancies[i]),
        ],
      ],
    );
  }
}
