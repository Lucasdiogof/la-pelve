import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class PlanoTratamentoInfoSection extends StatelessWidget {
  const PlanoTratamentoInfoSection(this.plano, {super.key});

  final PlanoTratamento plano;

  @override
  Widget build(BuildContext context) {
    final p = plano;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Plano de tratamento'),
        InfoRow(
          'Diagnóstico fisioterapêutico',
          PatientDetailFormat.text(p.diagnosticoFisioterapeutico),
        ),
        InfoRow(
          'Objetivo do tratamento',
          PatientDetailFormat.text(p.objetivoTratamento),
        ),
        InfoRow(
          'Conduta / plano de tratamento',
          PatientDetailFormat.text(p.condutaTratamento),
        ),
        InfoRow(
          'Frequência sugerida',
          PatientDetailFormat.text(p.frequenciaSugerida),
        ),
      ],
    );
  }
}
