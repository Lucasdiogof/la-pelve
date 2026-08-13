import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class HistoricoCirurgicoInfoSection extends StatelessWidget {
  const HistoricoCirurgicoInfoSection(this.historico, {super.key});

  final SurgicalHistory historico;

  @override
  Widget build(BuildContext context) {
    final h = historico;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Histórico cirúrgico'),
        InfoRow(
          'Cirurgias',
          h.surgeries.isEmpty
              ? PatientDetailFormat.naoInformado
              : h.surgeries.map((c) => c.label).join(', '),
        ),
        if (h.surgeries.contains(GynecologicalSurgery.other))
          InfoRow(
            'Qual cirurgia',
            PatientDetailFormat.text(h.otherSurgeryDescription),
          ),
      ],
    );
  }
}
