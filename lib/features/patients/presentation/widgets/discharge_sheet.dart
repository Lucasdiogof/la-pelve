import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/discharge_sheet_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/discharge_sheet_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

Future<Discharge?> showDischargeSheet(BuildContext context) {
  return showModalBottomSheet<Discharge>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DischargeSheet(),
  );
}

class _DischargeSheet extends StatefulWidget {
  const _DischargeSheet();

  @override
  State<_DischargeSheet> createState() => _DischargeSheetState();
}

class _DischargeSheetState extends State<_DischargeSheet> {
  final _noteController = TextEditingController();
  final _formCubit = DischargeSheetCubit();

  @override
  void dispose() {
    _noteController.dispose();
    _formCubit.close();
    super.dispose();
  }

  bool _canSave(DischargeSheetState state) =>
      state.date != null && state.reason != null;

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<DischargeSheetCubit, DischargeSheetState>(
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
                      t.closeTreatmentButton,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppDateField(
                      hintText: t.dateHint,
                      value: formState.date,
                      onChanged: _formCubit.setData,
                    ),
                    const SizedBox(height: 16),
                    AppChipSelect<DischargeReason>(
                      options: DischargeReason.values,
                      labelBuilder: (v) => v.label(t.language),
                      selected: formState.reason == null
                          ? {}
                          : {formState.reason!},
                      onChanged: (value) => _formCubit.setMotivo(
                        value.isEmpty ? null : value.first,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _noteController,
                      icon: Icons.notes_outlined,
                      hintText: t.finalNoteHint,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: t.confirmCloseTreatmentButton,
                      onPressed: _canSave(formState)
                          ? () => Navigator.of(context).pop(
                              Discharge(
                                date: formState.date!,
                                reason: formState.reason!,
                                finalNote: _noteController.text.trim().isEmpty
                                    ? null
                                    : _noteController.text.trim(),
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
