import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_select_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
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
    text: widget.existingAppointment?.nomePaciente ?? '',
  );
  late DateTime? _data = widget.existingAppointment?.data;
  late TimeOfDay? _hora = widget.existingAppointment?.hora;
  late String? _patientId = widget.existingAppointment?.patientId;

  bool get _isEditing => widget.existingAppointment != null;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _data != null && _hora != null && _nomeController.text.trim().isNotEmpty;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _hora = picked);
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
      setState(() {
        _patientId = selected.id;
        _nomeController.text = selected.dadosPessoais.nome;
      });
    }
  }

  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    showAppLoading();
    final existing = widget.existingAppointment;
    final appointment = existing == null
        ? Appointment(
            id: generateId(),
            data: _data!,
            hora: _hora!,
            nomePaciente: _nomeController.text.trim(),
            patientId: _patientId,
          )
        : existing.copyWith(
            data: _data,
            hora: _hora,
            nomePaciente: _nomeController.text.trim(),
            patientId: _patientId,
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
      case Error(:final failure):
        setState(() => _saving = false);
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPatients = context.watch<PatientsCubit>().state.isNotEmpty;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar agendamento' : 'Criar agendamento'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                AppDateField(
                  hintText: 'Data',
                  value: _data,
                  onChanged: (value) => setState(() => _data = value),
                ),
                const SizedBox(height: 12),
                AppSelectField(
                  icon: Icons.access_time_outlined,
                  hintText: 'Horário',
                  displayText: _hora == null ? '' : _hora!.format(context),
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
                  onChanged: (_) => setState(() {
                    _patientId = null;
                  }),
                ),
              ],
            ),
          ),
          AppBottomActionBar(
            child: PrimaryButton(
              label: 'Salvar',
              isLoading: _saving,
              onPressed: _canSave ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}
