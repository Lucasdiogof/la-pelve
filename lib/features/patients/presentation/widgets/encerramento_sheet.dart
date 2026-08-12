import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

Future<Encerramento?> showEncerramentoSheet(BuildContext context) {
  return showModalBottomSheet<Encerramento>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EncerramentoSheet(),
  );
}

class _EncerramentoSheet extends StatefulWidget {
  const _EncerramentoSheet();

  @override
  State<_EncerramentoSheet> createState() => _EncerramentoSheetState();
}

class _EncerramentoSheetState extends State<_EncerramentoSheet> {
  final _observacaoController = TextEditingController();
  DateTime? _data = DateTime.now();
  MotivoEncerramento? _motivo;

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  bool get _canSave => _data != null && _motivo != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Encerrar tratamento',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                AppDateField(
                  hintText: 'Data',
                  value: _data,
                  onChanged: (value) => setState(() => _data = value),
                ),
                const SizedBox(height: 16),
                AppChipSelect<MotivoEncerramento>(
                  options: MotivoEncerramento.values,
                  labelBuilder: (v) => v.label,
                  selected: _motivo == null ? {} : {_motivo!},
                  onChanged: (value) => setState(
                    () => _motivo = value.isEmpty ? null : value.first,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _observacaoController,
                  icon: Icons.notes_outlined,
                  hintText: 'Observação final (opcional)',
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Confirmar encerramento',
                  onPressed: _canSave
                      ? () => Navigator.of(context).pop(
                          Encerramento(
                            data: _data!,
                            motivo: _motivo!,
                            observacaoFinal:
                                _observacaoController.text.trim().isEmpty
                                ? null
                                : _observacaoController.text.trim(),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
