import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class HistoricoGinecologicoInfoSection extends StatelessWidget {
  const HistoricoGinecologicoInfoSection(this.historico, {super.key});

  final GynecologicalHistory historico;

  @override
  Widget build(BuildContext context) {
    final h = historico;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Histórico ginecológico'),
        InfoRow(
          'Idade da primeira menstruação',
          PatientDetailFormat.intValue(h.ageAtMenarche),
        ),
        InfoRow(
          'Fluxo menstrual',
          PatientDetailFormat.enumValue(h.menstrualFlow, (v) => v.label),
        ),
        InfoRow(
          'Presença de cólica (0-10)',
          PatientDetailFormat.intValue(h.crampsScore0to10),
        ),
        InfoRow(
          'Menstrua atualmente',
          PatientDetailFormat.yesNo(h.currentlyMenstruating),
        ),
        if (h.currentlyMenstruating == false) ...[
          InfoRow(
            'Está na menopausa',
            PatientDetailFormat.yesNo(h.isInMenopause),
          ),
          InfoRow(
            'Data aproximada da última menstruação',
            PatientDetailFormat.dateValue(h.approximateLastMenstruationDate),
          ),
        ],
        InfoRow('Ciclo regular', PatientDetailFormat.yesNo(h.regularCycle)),
        InfoRow('Menopausa', PatientDetailFormat.yesNo(h.menopause)),
        InfoRow(
          'Faz reposição hormonal',
          PatientDetailFormat.yesNo(h.hormoneReplacementTherapy),
        ),
        if (h.hormoneReplacementTherapy == true)
          InfoRow(
            'Detalhe da reposição hormonal',
            PatientDetailFormat.text(h.hormoneReplacementTherapyDescription),
          ),
        InfoRow(
          'Método contraceptivo',
          PatientDetailFormat.enumValue(h.contraceptiveMethod, (v) => v.label),
        ),
        InfoRow(
          'Dor pélvica fora do período menstrual',
          PatientDetailFormat.yesNo(h.pelvicPainOutsidePeriod),
        ),
        InfoRow(
          'Sangramento fora do período menstrual',
          PatientDetailFormat.yesNo(h.bleedingOutsidePeriod),
        ),
        InfoRow('Endometriose', PatientDetailFormat.yesNo(h.endometriosis)),
        InfoRow(
          'Síndrome dos ovários policísticos',
          PatientDetailFormat.yesNo(h.polycysticOvarySyndrome),
        ),
        InfoRow(
          'Infecções urinárias recorrentes',
          PatientDetailFormat.yesNo(h.recurrentUrinaryInfections),
        ),
        InfoRow(
          'Infecções vaginais recorrentes',
          PatientDetailFormat.yesNo(h.recurrentVaginalInfections),
        ),
      ],
    );
  }
}
