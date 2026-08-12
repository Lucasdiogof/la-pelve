import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/gestacao.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';

class PatientDetailFormat {
  const PatientDetailFormat._();

  static const naoInformado = 'Não informado';

  static String text(String? value) =>
      (value == null || value.trim().isEmpty) ? naoInformado : value.trim();

  static String yesNo(bool? value) => switch (value) {
    true => 'Sim',
    false => 'Não',
    null => naoInformado,
  };

  static String intValue(int? value) => value?.toString() ?? naoInformado;

  static String dateValue(DateTime? value) =>
      value == null ? naoInformado : AppDateField.format(value);

  static String money(double? value) =>
      value == null ? naoInformado : 'R\$ ${value.toStringAsFixed(2)}';

  static String enumValue<T>(T? value, String Function(T) label) =>
      value == null ? naoInformado : label(value);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: context.colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isMissing = value == PatientDetailFormat.naoInformado;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isMissing
                    ? context.colors.textHint
                    : context.colors.textPrimary,
                fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EncerramentoBanner extends StatelessWidget {
  const EncerramentoBanner({
    required this.encerramento,
    required this.onReabrir,
    super.key,
  });

  final Encerramento encerramento;
  final VoidCallback onReabrir;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.textHint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_outlined, color: context.colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tratamento encerrado em ${AppDateField.format(encerramento.data)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Motivo: ${encerramento.motivo.label}',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                if ((encerramento.observacaoFinal ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    encerramento.observacaoFinal!,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          TextButton(onPressed: onReabrir, child: const Text('Reabrir')),
        ],
      ),
    );
  }
}

class GestacaoCard extends StatelessWidget {
  const GestacaoCard({required this.index, required this.gestacao, super.key});

  final int index;
  final Gestacao gestacao;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestação ${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          InfoRow(
            'Perda gestacional',
            PatientDetailFormat.yesNo(gestacao.perdaGestacional),
          ),
          if (gestacao.perdaGestacional == true)
            InfoRow(
              'Detalhe da perda',
              PatientDetailFormat.text(gestacao.descricaoPerda),
            )
          else if (gestacao.perdaGestacional == false) ...[
            InfoRow(
              'Via de parto',
              PatientDetailFormat.enumValue(
                gestacao.viaDeParto,
                (v) => v.label,
              ),
            ),
            if (gestacao.viaDeParto == ViaDeParto.normal)
              InfoRow(
                'Complicação no parto',
                PatientDetailFormat.enumValue(
                  gestacao.complicacaoParto,
                  (v) => v.label,
                ),
              ),
            if (gestacao.viaDeParto == ViaDeParto.normal)
              InfoRow(
                'Uso de fórceps ou vácuo',
                PatientDetailFormat.yesNo(gestacao.usoForcepsOuVacuo),
              ),
            InfoRow(
              'Peso aproximado do bebê',
              PatientDetailFormat.text(gestacao.pesoAproximadoBebe),
            ),
            InfoRow(
              'Teve complicações',
              PatientDetailFormat.yesNo(gestacao.teveComplicacoes),
            ),
            if (gestacao.teveComplicacoes == true)
              InfoRow(
                'Detalhe das complicações',
                PatientDetailFormat.text(gestacao.descricaoComplicacao),
              ),
          ],
        ],
      ),
    );
  }
}
