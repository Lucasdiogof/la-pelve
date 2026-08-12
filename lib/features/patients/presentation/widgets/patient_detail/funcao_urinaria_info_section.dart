import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class FuncaoUrinariaInfoSection extends StatelessWidget {
  const FuncaoUrinariaInfoSection(this.funcao, {super.key});

  final FuncaoUrinaria funcao;

  @override
  Widget build(BuildContext context) {
    final f = funcao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Função urinária'),
        InfoRow('Urgência', PatientDetailFormat.yesNo(f.urgencia)),
        if (f.urgencia == true)
          InfoRow(
            'Detalhe da urgência',
            PatientDetailFormat.text(f.descricaoUrgencia),
          ),
        InfoRow(
          'Perda associada à urgência',
          PatientDetailFormat.yesNo(f.perdaAssociadaUrgencia),
        ),
        InfoRow(
          'Incontinência de esforço',
          PatientDetailFormat.yesNo(f.incontinenciaEsforco),
        ),
        if (f.incontinenciaEsforco == true) ...[
          InfoRow(
            'Gatilhos',
            f.gatilhosIncontinencia.isEmpty
                ? PatientDetailFormat.naoInformado
                : f.gatilhosIncontinencia.map((g) => g.label).join(', '),
          ),
          if (f.gatilhosIncontinencia.contains(GatilhoIncontinencia.outros))
            InfoRow(
              'Qual outro gatilho',
              PatientDetailFormat.text(f.descricaoOutroGatilho),
            ),
        ],
        if (f.perdaAssociadaUrgencia == true || f.incontinenciaEsforco == true)
          InfoRow(
            'Quantidade aproximada da perda',
            PatientDetailFormat.enumValue(f.quantidadePerda, (v) => v.label),
          ),
        InfoRow(
          'Utiliza absorvente ou protetor',
          PatientDetailFormat.yesNo(f.utilizaAbsorvente),
        ),
        if (f.utilizaAbsorvente == true)
          InfoRow(
            'Quantos por dia',
            PatientDetailFormat.intValue(f.quantosAbsorventes),
          ),
        InfoRow(
          'Dor ou ardência ao urinar',
          PatientDetailFormat.yesNo(f.dorArdenciaAoUrinar),
        ),
        InfoRow(
          'Jato urinário fraco',
          PatientDetailFormat.yesNo(f.jatoUrinarioFraco),
        ),
        InfoRow('Enurese noturna', PatientDetailFormat.yesNo(f.enureseNoturna)),
        if (f.enureseNoturna == true)
          InfoRow(
            'Detalhe da enurese',
            PatientDetailFormat.text(f.descricaoEnurese),
          ),
        InfoRow('Hesitação', PatientDetailFormat.yesNo(f.hesitacao)),
        if (f.hesitacao == true)
          InfoRow(
            'Detalhe da hesitação',
            PatientDetailFormat.text(f.descricaoHesitacao),
          ),
        InfoRow(
          'Esforço miccional',
          PatientDetailFormat.yesNo(f.esforcoMiccional),
        ),
        if (f.esforcoMiccional == true)
          InfoRow(
            'Detalhe do esforço miccional',
            PatientDetailFormat.text(f.descricaoEsforcoMiccional),
          ),
        InfoRow(
          'Gotejamento pós miccional',
          PatientDetailFormat.yesNo(f.gotejamentoPosMiccional),
        ),
        if (f.gotejamentoPosMiccional == true)
          InfoRow(
            'Detalhe do gotejamento',
            PatientDetailFormat.text(f.descricaoGotejamento),
          ),
        InfoRow(
          'Sensação de esvaziamento incompleto',
          PatientDetailFormat.yesNo(f.esvaziamentoIncompleto),
        ),
        if (f.esvaziamentoIncompleto == true)
          InfoRow(
            'Detalhe do esvaziamento',
            PatientDetailFormat.text(f.descricaoEsvaziamentoIncompleto),
          ),
      ],
    );
  }
}
