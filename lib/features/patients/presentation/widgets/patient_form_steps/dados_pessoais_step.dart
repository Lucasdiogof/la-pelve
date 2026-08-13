import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
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
    text: widget.patient.dadosPessoais.nome,
  );
  late final _idadeController = TextEditingController(
    text: widget.patient.dadosPessoais.idade?.toString() ?? '',
  );
  late final _telefoneController = TextEditingController(
    text: widget.patient.dadosPessoais.telefone,
  );
  late final _profissaoController = TextEditingController(
    text: widget.patient.dadosPessoais.profissao,
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
        dadosPessoais: widget.patient.dadosPessoais.copyWith(
          nome: _nomeController.text,
          idade: int.tryParse(_idadeController.text),
          telefone: _telefoneController.text,
          profissao: _profissaoController.text,
        ),
      ),
    );
  }

  String? get _nomeError {
    final value = _nomeController.text.trim();
    if (value.isEmpty || value.length > 2) return null;
    return 'Informe pelo menos 3 caracteres.';
  }

  String? get _idadeError => ageErrorText(_idadeController.text);

  String? get _profissaoError {
    final value = _profissaoController.text.trim();
    if (value.isEmpty || value.length > 2) return null;
    return 'Informe pelo menos 3 caracteres.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _nomeController,
          icon: Icons.person_outline,
          hintText: 'Nome',
          errorText: _nomeError,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _idadeController,
          icon: Icons.cake_outlined,
          hintText: 'Idade',
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
          hintText: '(XX) X XXXX-XXXX',
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          errorText: phoneErrorText(_telefoneController.text),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _profissaoController,
          icon: Icons.work_outline,
          hintText: 'Profissão',
          errorText: _profissaoError,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 20),
        Text(
          'SEXO',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppChipSelect<Sexo>(
          options: Sexo.values,
          labelBuilder: (option) => option.label,
          selected: widget.patient.dadosPessoais.sexo == null
              ? {}
              : {widget.patient.dadosPessoais.sexo!},
          onChanged: (selected) => widget.onChanged(
            widget.patient.copyWith(
              dadosPessoais: widget.patient.dadosPessoais.copyWith(
                sexo: selected.isEmpty ? null : selected.first,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
