import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class HistoricoGinecologicoInfoSection extends StatelessWidget {
  const HistoricoGinecologicoInfoSection(this.historico, {super.key});

  final HistoricoGinecologico historico;

  @override
  Widget build(BuildContext context) {
    final h = historico;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Histórico ginecológico'),
        InfoRow(
          'Idade da primeira menstruação',
          PatientDetailFormat.intValue(h.idadePrimeiraMenstruacao),
        ),
        InfoRow(
          'Fluxo menstrual',
          PatientDetailFormat.enumValue(h.fluxoMenstrual, (v) => v.label),
        ),
        InfoRow(
          'Presença de cólica (0-10)',
          PatientDetailFormat.intValue(h.colica0a10),
        ),
        InfoRow(
          'Menstrua atualmente',
          PatientDetailFormat.yesNo(h.menstruaAtualmente),
        ),
        if (h.menstruaAtualmente == false) ...[
          InfoRow(
            'Está na menopausa',
            PatientDetailFormat.yesNo(h.estaNaMenopausa),
          ),
          InfoRow(
            'Data aproximada da última menstruação',
            PatientDetailFormat.dateValue(h.dataUltimaMenstruacaoAproximada),
          ),
        ],
        InfoRow('Ciclo regular', PatientDetailFormat.yesNo(h.cicloRegular)),
        InfoRow('Menopausa', PatientDetailFormat.yesNo(h.menopausa)),
        InfoRow(
          'Faz reposição hormonal',
          PatientDetailFormat.yesNo(h.reposicaoHormonal),
        ),
        if (h.reposicaoHormonal == true)
          InfoRow(
            'Detalhe da reposição hormonal',
            PatientDetailFormat.text(h.descricaoReposicaoHormonal),
          ),
        InfoRow(
          'Método contraceptivo',
          PatientDetailFormat.enumValue(h.metodoContraceptivo, (v) => v.label),
        ),
        InfoRow(
          'Dor pélvica fora do período menstrual',
          PatientDetailFormat.yesNo(h.dorPelvicaForaPeriodo),
        ),
        InfoRow(
          'Sangramento fora do período menstrual',
          PatientDetailFormat.yesNo(h.sangramentoForaPeriodo),
        ),
        InfoRow('Endometriose', PatientDetailFormat.yesNo(h.endometriose)),
        InfoRow(
          'Síndrome dos ovários policísticos',
          PatientDetailFormat.yesNo(h.sindromeOvariosPolicisticos),
        ),
        InfoRow(
          'Infecções urinárias recorrentes',
          PatientDetailFormat.yesNo(h.infeccoesUrinariasRecorrentes),
        ),
        InfoRow(
          'Infecções vaginais recorrentes',
          PatientDetailFormat.yesNo(h.infeccoesVaginaisRecorrentes),
        ),
      ],
    );
  }
}
