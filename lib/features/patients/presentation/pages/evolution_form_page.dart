import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';
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
    text: widget.existingEntry?.descricao ?? '',
  );
  late DateTime? _data = widget.existingEntry?.data;
  bool _saving = false;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _data != null && _descricaoController.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = _isEditing
        ? await sl<PatientRepository>().updateEvolution(
            widget.existingEntry!.copyWith(
              data: _data!,
              descricao: _descricaoController.text.trim(),
              updatedAt: DateTime.now(),
            ),
          )
        : await sl<PatientRepository>().addEvolution(
            EvolutionEntry(
              id: generateId(),
              patientId: widget.patientId,
              data: _data!,
              descricao: _descricaoController.text.trim(),
            ),
          );
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
    return Scaffold(
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
                  value: _data,
                  onChanged: (value) => setState(() => _data = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _descricaoController,
                  icon: Icons.description_outlined,
                  hintText: 'O que foi feito no atendimento',
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          AppBottomActionBar(
            child: PrimaryButton(
              label: _isEditing ? 'Salvar alterações' : 'Salvar',
              isLoading: _saving,
              onPressed: _canSave ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}
