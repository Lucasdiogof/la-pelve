import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/encerramento_sheet_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/encerramento_sheet_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

Future<Discharge?> showEncerramentoSheet(BuildContext context) {
  return showModalBottomSheet<Discharge>(
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
  final _formCubit = EncerramentoSheetCubit();

  @override
  void dispose() {
    _observacaoController.dispose();
    _formCubit.close();
    super.dispose();
  }

  bool _canSave(EncerramentoSheetState state) =>
      state.date != null && state.reason != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<EncerramentoSheetCubit, EncerramentoSheetState>(
        builder: (context, formState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                      value: formState.date,
                      onChanged: _formCubit.setData,
                    ),
                    const SizedBox(height: 16),
                    AppChipSelect<DischargeReason>(
                      options: DischargeReason.values,
                      labelBuilder: (v) => v.label,
                      selected: formState.reason == null
                          ? {}
                          : {formState.reason!},
                      onChanged: (value) => _formCubit.setMotivo(
                        value.isEmpty ? null : value.first,
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
                      onPressed: _canSave(formState)
                          ? () => Navigator.of(context).pop(
                              Discharge(
                                date: formState.date!,
                                reason: formState.reason!,
                                finalNote:
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
        ),
      ),
    );
  }
}
