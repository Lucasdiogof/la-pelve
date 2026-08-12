import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_scale_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class FuncaoSexualStep extends StatefulWidget {
  const FuncaoSexualStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<FuncaoSexualStep> createState() => _FuncaoSexualStepState();
}

class _FuncaoSexualStepState extends State<FuncaoSexualStep> {
  late final _dificuldadeController = TextEditingController(
    text: widget.patient.funcaoSexual.descricaoDificuldadeOrgasmo ?? '',
  );
  late final _frequenciaController = TextEditingController(
    text: widget.patient.funcaoSexual.frequenciaAtividadeSexual ?? '',
  );

  @override
  void dispose() {
    _dificuldadeController.dispose();
    _frequenciaController.dispose();
    super.dispose();
  }

  void _update(FuncaoSexual Function(FuncaoSexual) update) {
    widget.onChanged(
      widget.patient.copyWith(
        funcaoSexual: update(widget.patient.funcaoSexual),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final funcao = widget.patient.funcaoSexual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppYesNoToggle(
          label: 'Vida sexual ativa?',
          value: funcao.vidaSexualAtiva,
          onChanged: (value) =>
              _update((f) => f.copyWith(vidaSexualAtiva: value)),
        ),
        if (funcao.vidaSexualAtiva == true) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _frequenciaController,
            icon: Icons.calendar_today_outlined,
            hintText: 'Frequência de atividade sexual',
            onChanged: (value) =>
                _update((f) => f.copyWith(frequenciaAtividadeSexual: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: 'Precisa usar lubrificante?',
            value: funcao.precisaLubrificante,
            onChanged: (value) =>
                _update((f) => f.copyWith(precisaLubrificante: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: 'Sensação de ressecamento?',
            value: funcao.ressecamento,
            onChanged: (value) =>
                _update((f) => f.copyWith(ressecamento: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: 'Dificuldade para atingir o orgasmo?',
            value: funcao.dificuldadeOrgasmo,
            onChanged: (value) =>
                _update((f) => f.copyWith(dificuldadeOrgasmo: value)),
          ),
          if (funcao.dificuldadeOrgasmo == true) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _dificuldadeController,
              icon: Icons.description_outlined,
              hintText: 'Detalhe',
              onChanged: (value) => _update(
                (f) => f.copyWith(descricaoDificuldadeOrgasmo: value),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'DOR',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: 'Dor na penetração?',
            value: funcao.dorNaPenetracao,
            onChanged: (value) =>
                _update((f) => f.copyWith(dorNaPenetracao: value)),
          ),
          if (funcao.dorNaPenetracao == true) ...[
            const SizedBox(height: 8),
            AppChipSelect<TipoDorPenetracao>(
              options: TipoDorPenetracao.values,
              labelBuilder: (option) => option.label,
              selected: funcao.tipoDorPenetracao == null
                  ? {}
                  : {funcao.tipoDorPenetracao!},
              onChanged: (selected) => _update(
                (f) => f.copyWith(
                  tipoDorPenetracao: selected.isEmpty ? null : selected.first,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: 'Dor durante ou depois da relação?',
            value: funcao.dorDuranteOuDepoisRelacao,
            onChanged: (value) =>
                _update((f) => f.copyWith(dorDuranteOuDepoisRelacao: value)),
          ),
          if (funcao.dorNaPenetracao == true ||
              funcao.dorDuranteOuDepoisRelacao == true) ...[
            const SizedBox(height: 12),
            AppScaleField(
              label: 'Intensidade da dor',
              value: funcao.intensidadeDor0a10,
              onChanged: (value) =>
                  _update((f) => f.copyWith(intensidadeDor0a10: value)),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'DESEJO SEXUAL',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          AppChipSelect<DesejoSexual>(
            options: DesejoSexual.values,
            labelBuilder: (option) => option.label,
            selected: funcao.desejoSexual == null ? {} : {funcao.desejoSexual!},
            onChanged: (selected) => _update(
              (f) => f.copyWith(
                desejoSexual: selected.isEmpty ? null : selected.first,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
