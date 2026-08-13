import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/evolution_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/evolution_form_state.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

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

  bool _canSave(EvolutionFormState state) =>
      state.date != null && _descricaoController.text.trim().isNotEmpty;

  Future<void> _save() async {
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
              ? 'Evolução atualizada com sucesso.'
              : 'Evolução registrada com sucesso.',
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
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<EvolutionFormCubit, EvolutionFormState>(
        builder: (context, formState) => Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            title: Text(_isEditing ? 'Editar evolução' : 'Nova evolução'),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    AppDateField(
                      hintText: 'Data',
                      value: formState.date,
                      lastDate: _today,
                      onChanged: _formCubit.setData,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _descricaoController,
                      icon: Icons.description_outlined,
                      hintText: 'O que foi feito no atendimento',
                      maxLines: 6,
                    ),
                  ],
                ),
              ),
              AppBottomActionBar(
                child: PrimaryButton(
                  label: _isEditing ? 'Salvar alterações' : 'Salvar',
                  isLoading: formState.saving,
                  onPressed: _canSave(formState) ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
