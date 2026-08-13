import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_form_state.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_select_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/patient_picker_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class AgendaFormPage extends StatefulWidget {
  const AgendaFormPage({this.existingAppointment, super.key});

  final Appointment? existingAppointment;

  @override
  State<AgendaFormPage> createState() => _AgendaFormPageState();
}

class _AgendaFormPageState extends State<AgendaFormPage> {
  late final _nomeController = TextEditingController(
    text: widget.existingAppointment?.patientName ?? '',
  );
  late final _formCubit = AgendaFormCubit(existing: widget.existingAppointment);

  bool get _isEditing => widget.existingAppointment != null;

  @override
  void dispose() {
    _nomeController.dispose();
    _formCubit.close();
    super.dispose();
  }

  bool _canSave(AgendaFormState state) =>
      state.date != null &&
      state.time != null &&
      _nomeController.text.trim().isNotEmpty;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _formCubit.state.time ?? TimeOfDay.now(),
    );
    if (picked != null) _formCubit.setHora(picked);
  }

  Future<void> _selectPatient() async {
    final patients = context.read<PatientsCubit>().state;
    final selected = await showModalBottomSheet<Patient>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PatientPickerSheet(patients: patients),
    );
    if (selected != null) {
      _formCubit.selectPatient(selected.id);
      _nomeController.text = selected.personalInfo.name;
    }
  }

  Future<void> _delete() async {
    final existing = widget.existingAppointment;
    if (existing == null) return;
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Excluir agendamento',
      description:
          'Tem certeza que deseja excluir este agendamento? Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    showAppLoading();
    final result = await context.read<AgendaCubit>().deleteAppointment(
      existing.id,
    );
    hideAppLoading();
    if (!mounted) return;
    switch (result) {
      case Success():
        context.pop();
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  Future<void> _save() async {
    _formCubit.setSaving(true);
    showAppLoading();
    final state = _formCubit.state;
    final existing = widget.existingAppointment;
    final appointment = existing == null
        ? Appointment(
            id: generateId(),
            date: state.date!,
            time: state.time!,
            patientName: _nomeController.text.trim(),
            patientId: state.patientId,
          )
        : existing.copyWith(
            date: state.date,
            time: state.time,
            patientName: _nomeController.text.trim(),
            patientId: state.patientId,
          );
    final cubit = context.read<AgendaCubit>();
    final result = existing == null
        ? await cubit.addAppointment(appointment)
        : await cubit.updateAppointment(appointment);
    hideAppLoading();
    if (!mounted) return;
    switch (result) {
      case Success():
        context.pop();
        await AppInfoBottomSheet.showSuccess(
          context,
          description: existing == null
              ? 'Agendamento criado com sucesso.'
              : 'Agendamento atualizado com sucesso.',
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
    final hasPatients = context.watch<PatientsCubit>().state.isNotEmpty;
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<AgendaFormCubit, AgendaFormState>(
        builder: (context, formState) => Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            children: [
              ModernAppBar(
                title: _isEditing ? 'Editar agendamento' : 'Criar agendamento',
                subtitle: _isEditing
                    ? 'Atualize os dados do atendimento'
                    : 'Novo atendimento na agenda',
                showBackButton: true,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    AppDateField(
                      hintText: 'Data',
                      value: formState.date,
                      onChanged: _formCubit.setData,
                    ),
                    const SizedBox(height: 12),
                    AppSelectField(
                      icon: Icons.access_time_outlined,
                      hintText: 'Horário',
                      displayText: formState.time == null
                          ? ''
                          : formState.time!.format(context),
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _nomeController,
                      icon: Icons.person_outline,
                      hintText: 'Nome do paciente',
                      suffixIcon: hasPatients
                          ? IconButton(
                              icon: Icon(
                                Icons.list_alt_outlined,
                                color: context.colors.textSecondary,
                              ),
                              tooltip: 'Selecionar paciente cadastrado',
                              onPressed: _selectPatient,
                            )
                          : null,
                      onChanged: (_) => _formCubit.onNomeChanged(),
                    ),
                  ],
                ),
              ),
              AppBottomActionBar(
                child: Column(
                  children: [
                    if (_isEditing) ...[
                      OutlinedButton(
                        onPressed: _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.error,
                          side: BorderSide(color: context.colors.error),
                          minimumSize: const Size.fromHeight(56),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Excluir'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      label: 'Salvar',
                      isLoading: formState.saving,
                      onPressed: _canSave(formState) ? _save : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
