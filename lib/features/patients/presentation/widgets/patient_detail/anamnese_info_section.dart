import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class AnamneseInfoSection extends StatelessWidget {
  const AnamneseInfoSection(this.anamnese, {super.key});

  final Anamnese anamnese;

  @override
  Widget build(BuildContext context) {
    final a = anamnese;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Anamnese'),
        InfoRow(
          'Queixa principal',
          PatientDetailFormat.text(a.queixaPrincipal),
        ),
        InfoRow(
          'Início dos sintomas',
          PatientDetailFormat.text(a.inicioSintomas),
        ),
        InfoRow(
          'Tem diagnóstico médico',
          PatientDetailFormat.yesNo(a.temDiagnosticoMedico),
        ),
        if (a.temDiagnosticoMedico == true)
          InfoRow(
            'Qual diagnóstico',
            PatientDetailFormat.text(a.diagnosticoMedico),
          ),
        InfoRow(
          'Já realizou tratamento',
          PatientDetailFormat.yesNo(a.realizouTratamento),
        ),
        if (a.realizouTratamento == true)
          InfoRow(
            'Qual tratamento',
            PatientDetailFormat.text(a.descricaoTratamento),
          ),
        InfoRow(
          'Doenças crônicas',
          PatientDetailFormat.yesNo(a.doencasCronicas),
        ),
        if (a.doencasCronicas == true)
          InfoRow(
            'Quais doenças',
            PatientDetailFormat.text(a.descricaoDoencasCronicas),
          ),
        InfoRow(
          'Uso contínuo de medicamentos',
          PatientDetailFormat.yesNo(a.usoContinuoMedicamentos),
        ),
        if (a.usoContinuoMedicamentos == true)
          InfoRow(
            'Quais medicamentos',
            PatientDetailFormat.text(a.descricaoMedicamentos),
          ),
        InfoRow('Tabagismo', PatientDetailFormat.yesNo(a.tabagismo)),
        InfoRow('Consome álcool', PatientDetailFormat.yesNo(a.consomeAlcool)),
        InfoRow(
          'Pratica atividade física',
          PatientDetailFormat.yesNo(a.praticaAtividadeFisica),
        ),
        InfoRow('Exames de imagem', PatientDetailFormat.text(a.examesImagem)),
      ],
    );
  }
}
