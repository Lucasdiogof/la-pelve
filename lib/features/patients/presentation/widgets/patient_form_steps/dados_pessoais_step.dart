import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_a.dart';
import 'package:fisioterapia_pelvica/shared/utils/phone_input_formatter.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class DadosPessoaisStep extends StatefulWidget {
  const DadosPessoaisStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<DadosPessoaisStep> createState() => _DadosPessoaisStepState();
}

class _DadosPessoaisStepState extends State<DadosPessoaisStep> {
  late final _nomeController = TextEditingController(
    text: widget.patient.personalInfo.name,
  );
  late final _idadeController = TextEditingController(
    text: widget.patient.personalInfo.age?.toString() ?? '',
  );
  late final _telefoneController = TextEditingController(
    text: widget.patient.personalInfo.phone,
  );
  late final _profissaoController = TextEditingController(
    text: widget.patient.personalInfo.occupation,
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _telefoneController.dispose();
    _profissaoController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.patient.copyWith(
        personalInfo: widget.patient.personalInfo.copyWith(
          name: _nomeController.text,
          age: int.tryParse(_idadeController.text),
          phone: _telefoneController.text,
          occupation: _profissaoController.text,
        ),
      ),
    );
  }

  String? _minLengthError(String value, PatientsWizardStringsA t) {
    if (value.isEmpty || value.length > 2) return null;
    return t.minLengthError;
  }

  String? get _idadeError => ageErrorText(_idadeController.text);

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsA(context.watch<LocaleCubit>().state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _nomeController,
          icon: Icons.person_outline,
          hintText: t.nameHint,
          errorText: _minLengthError(_nomeController.text.trim(), t),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _idadeController,
          icon: Icons.cake_outlined,
          hintText: t.ageHint,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          errorText: _idadeError,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _telefoneController,
          icon: Icons.phone_outlined,
          hintText: t.phoneHint,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          errorText: phoneErrorText(_telefoneController.text),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _profissaoController,
          icon: Icons.work_outline,
          hintText: t.occupationHint,
          errorText: _minLengthError(_profissaoController.text.trim(), t),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 20),
        Text(
          t.genderSectionHeader,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppChipSelect<Gender>(
          options: Gender.values,
          labelBuilder: (option) => option.label,
          selected: widget.patient.personalInfo.gender == null
              ? {}
              : {widget.patient.personalInfo.gender!},
          onChanged: (selected) => widget.onChanged(
            widget.patient.copyWith(
              personalInfo: widget.patient.personalInfo.copyWith(
                gender: selected.isEmpty ? null : selected.first,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
