import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class AnamneseStep extends StatefulWidget {
  const AnamneseStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<AnamneseStep> createState() => _AnamneseStepState();
}

class _AnamneseStepState extends State<AnamneseStep> {
  late final _queixaController = TextEditingController(
    text: widget.patient.anamnese.queixaPrincipal,
  );
  late final _diagnosticoController = TextEditingController(
    text: widget.patient.anamnese.diagnosticoMedico ?? '',
  );
  late final _inicioSintomasController = TextEditingController(
    text: widget.patient.anamnese.inicioSintomas,
  );
  late final _tratamentoController = TextEditingController(
    text: widget.patient.anamnese.descricaoTratamento ?? '',
  );
  late final _doencasController = TextEditingController(
    text: widget.patient.anamnese.descricaoDoencasCronicas ?? '',
  );
  late final _medicamentosController = TextEditingController(
    text: widget.patient.anamnese.descricaoMedicamentos ?? '',
  );
  late final _examesImagemController = TextEditingController(
    text: widget.patient.anamnese.examesImagem ?? '',
  );

  @override
  void dispose() {
    _queixaController.dispose();
    _diagnosticoController.dispose();
    _inicioSintomasController.dispose();
    _tratamentoController.dispose();
    _doencasController.dispose();
    _medicamentosController.dispose();
    _examesImagemController.dispose();
    super.dispose();
  }

  void _update(Anamnese Function(Anamnese) update) {
    widget.onChanged(
      widget.patient.copyWith(anamnese: update(widget.patient.anamnese)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anamnese = widget.patient.anamnese;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _queixaController,
          icon: Icons.chat_bubble_outline,
          hintText: 'Queixa principal',
          maxLines: 3,
          onChanged: (value) =>
              _update((a) => a.copyWith(queixaPrincipal: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Tem diagnóstico médico?',
          value: anamnese.temDiagnosticoMedico,
          onChanged: (value) =>
              _update((a) => a.copyWith(temDiagnosticoMedico: value)),
        ),
        if (anamnese.temDiagnosticoMedico == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _diagnosticoController,
            icon: Icons.description_outlined,
            hintText: 'Qual diagnóstico?',
            onChanged: (value) =>
                _update((a) => a.copyWith(diagnosticoMedico: value)),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'HMA — HISTÓRIA DA MOLÉSTIA ATUAL',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _inicioSintomasController,
          icon: Icons.event_outlined,
          hintText: 'Início dos sintomas',
          maxLines: 3,
          onChanged: (value) =>
              _update((a) => a.copyWith(inicioSintomas: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Já realizou algum tratamento?',
          value: anamnese.realizouTratamento,
          onChanged: (value) =>
              _update((a) => a.copyWith(realizouTratamento: value)),
        ),
        if (anamnese.realizouTratamento == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _tratamentoController,
            icon: Icons.healing_outlined,
            hintText: 'Qual tratamento?',
            onChanged: (value) =>
                _update((a) => a.copyWith(descricaoTratamento: value)),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Doenças crônicas?',
          value: anamnese.doencasCronicas,
          onChanged: (value) =>
              _update((a) => a.copyWith(doencasCronicas: value)),
        ),
        if (anamnese.doencasCronicas == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _doencasController,
            icon: Icons.local_hospital_outlined,
            hintText: 'Quais doenças?',
            onChanged: (value) =>
                _update((a) => a.copyWith(descricaoDoencasCronicas: value)),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Uso contínuo de medicamentos?',
          value: anamnese.usoContinuoMedicamentos,
          onChanged: (value) =>
              _update((a) => a.copyWith(usoContinuoMedicamentos: value)),
        ),
        if (anamnese.usoContinuoMedicamentos == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _medicamentosController,
            icon: Icons.medication_outlined,
            hintText: 'Quais medicamentos?',
            onChanged: (value) =>
                _update((a) => a.copyWith(descricaoMedicamentos: value)),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'HÁBITOS',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Tabagismo?',
          value: anamnese.tabagismo,
          onChanged: (value) => _update((a) => a.copyWith(tabagismo: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Consome álcool?',
          value: anamnese.consomeAlcool,
          onChanged: (value) =>
              _update((a) => a.copyWith(consomeAlcool: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Pratica atividade física?',
          value: anamnese.praticaAtividadeFisica,
          onChanged: (value) =>
              _update((a) => a.copyWith(praticaAtividadeFisica: value)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _examesImagemController,
          icon: Icons.image_outlined,
          hintText: 'Exames de imagem — resultado',
          maxLines: 3,
          onChanged: (value) => _update((a) => a.copyWith(examesImagem: value)),
        ),
      ],
    );
  }
}
