import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/cubit/evolution_form_cubit.dart';
import 'package:la_pelve/features/patients/presentation/cubit/evolution_form_state.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/shared/utils/id_generator.dart';
import 'package:la_pelve/shared/widgets/app_bottom_action_bar.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_text_field.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

class EvolutionFormPage extends StatefulWidget {
  const EvolutionFormPage({
    required this.patientId,
    this.existingEntry,
    super.key,
  });

  final String patientId;
  final EvolutionEntry? existingEntry;

  @override
  State<EvolutionFormPage> createState() => _EvolutionFormPageState();
}

class _EvolutionFormPageState extends State<EvolutionFormPage> {
  late final _descricaoController = TextEditingController(
    text: widget.existingEntry?.description ?? '',
  );
  late final _formCubit = EvolutionFormCubit(existing: widget.existingEntry);

  bool get _isEditing => widget.existingEntry != null;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _descricaoController.addListener(_formCubit.notifyFieldChanged);
  }

  @override
  void dispose() {
    _descricaoController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _formCubit.close();
    super.dispose();
  }

  /// Nome do paciente para o contexto da tela. Defensivo: se o PatientsCubit
  /// não estiver registrado ou não tiver o paciente carregado, não há subtítulo
  /// (o formulário não depende disso).
  String? get _patientName {
    if (!sl.isRegistered<PatientsCubit>()) return null;
    for (final patient in sl<PatientsCubit>().state.data ?? const <Patient>[]) {
      if (patient.id == widget.patientId) {
        final name = patient.personalInfo.name.trim();
        return name.isEmpty ? null : name;
      }
    }
    return null;
  }

  bool _canSave(EvolutionFormState state) =>
      state.date != null && _descricaoController.text.trim().isNotEmpty;

  Future<void> _save() async {
    final t = PatientsStrings(context.read<LocaleCubit>().state);
    _formCubit.setSaving(true);
    final date = _formCubit.state.date;
    final result = _isEditing
        ? await sl<PatientRepository>().updateEvolution(
            widget.existingEntry!.copyWith(
              date: date!,
              description: _descricaoController.text.trim(),
              updatedAt: DateTime.now(),
            ),
          )
        : await sl<PatientRepository>().addEvolution(
            EvolutionEntry(
              id: generateId(),
              patientId: widget.patientId,
              date: date!,
              description: _descricaoController.text.trim(),
            ),
          );
    if (!mounted) return;
    switch (result) {
      case Success():
        context.pop();
        await AppInfoBottomSheet.showSuccess(
          context,
          description: _isEditing
              ? t.evolutionUpdatedSuccess
              : t.evolutionCreatedSuccess,
        );
      case Error(:final failure):
        _formCubit.setSaving(false);
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<EvolutionFormCubit, EvolutionFormState>(
        builder: (context, formState) {
          // Lido aqui, acima do Scaffold: dentro do body o Scaffold já consome
          // o inset do teclado.
          final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
          return Scaffold(
            backgroundColor: context.colors.background,
            body: Column(
              children: [
                ModernAppBar(
                  title: _isEditing
                      ? t.editEvolutionTitle
                      : t.newEvolutionTitle,
                  subtitle: _patientName,
                  showBackButton: true,
                ),
                Expanded(
                  child: ListView(
                    // Com teclado aberto a viewport fica baixa: folga extra no fim
                    // para a textarea poder rolar para cima sem encostar na barra.
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.s16,
                      AppSpacing.gutter,
                      keyboardOpen ? AppSpacing.s32 : AppSpacing.s24,
                    ),
                    children: [
                      AppDateField(
                        label: t.dateHint,
                        // Vazio de propósito: o rótulo "Data" já está acima.
                        hintText: '',
                        value: formState.date,
                        lastDate: _today,
                        onChanged: _formCubit.setData,
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      AppTextField(
                        controller: _descricaoController,
                        label: t.evolutionFieldLabel,
                        hintText: t.evolutionDescriptionHint,
                        minLines: 6,
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
                // Só com teclado: separa de verdade o conteúdo rolável (cortado na
                // borda da viewport) da barra do botão.
                if (keyboardOpen)
                  Divider(height: 1, color: context.colors.border),
                AppBottomActionBar(
                  child: PrimaryButton(
                    label: _isEditing ? t.saveChangesLabel : t.saveLabel,
                    isLoading: formState.saving,
                    onPressed: _canSave(formState) ? _save : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
