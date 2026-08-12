import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/widgets/patient_picker_sheet.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class LancamentosTab extends StatefulWidget {
  const LancamentosTab({super.key});

  @override
  State<LancamentosTab> createState() => _LancamentosTabState();
}

class _LancamentosTabState extends State<LancamentosTab> {
  final _patientNameController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _formaPagamentoOutroController = TextEditingController();
  final _statusOutroController = TextEditingController();

  Patient? _patient;
  DateTime? _data;
  FormaPagamento? _formaPagamento;
  StatusPagamento _status = StatusPagamento.pago;
  bool _saving = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    _formaPagamentoOutroController.dispose();
    _statusOutroController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _patientNameController.text.trim().isNotEmpty &&
      _data != null &&
      double.tryParse(_valorController.text) != null &&
      (_formaPagamento != FormaPagamento.outro ||
          _formaPagamentoOutroController.text.trim().isNotEmpty) &&
      (_status != StatusPagamento.outro ||
          _statusOutroController.text.trim().length > 3);

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
        _patient = selected;
        _patientNameController.text = selected.dadosPessoais.nome;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    showAppLoading();
    final result = await context.read<FinancialCubit>().addEntry(
      FinancialEntry(
        id: generateId(),
        patientId: _patient?.id,
        patientName: _patientNameController.text.trim(),
        data: _data!,
        valor: double.parse(_valorController.text),
        observacoes: _observacoesController.text.trim(),
        formaPagamento: _formaPagamento,
        formaPagamentoOutraDescricao: _formaPagamento == FormaPagamento.outro
            ? _formaPagamentoOutroController.text.trim()
            : null,
        status: _status,
        statusOutraDescricao: _status == StatusPagamento.outro
            ? _statusOutroController.text.trim()
            : null,
      ),
    );
    hideAppLoading();
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        setState(() {
          _patient = null;
          _data = null;
          _formaPagamento = null;
          _status = StatusPagamento.pago;
          _patientNameController.clear();
          _valorController.clear();
          _observacoesController.clear();
          _formaPagamentoOutroController.clear();
          _statusOutroController.clear();
        });
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPatients = context.watch<PatientsCubit>().state.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AppTextField(
          controller: _patientNameController,
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
          onChanged: (_) => setState(() => _patient = null),
        ),
        const SizedBox(height: 12),
        AppDateField(
          hintText: 'Data do pagamento',
          value: _data,
          onChanged: (value) => setState(() => _data = value),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _valorController,
          icon: Icons.attach_money,
          hintText: 'Valor pago',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _observacoesController,
          icon: Icons.description_outlined,
          hintText: 'Observações',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'FORMA DE PAGAMENTO',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppChipSelect<FormaPagamento>(
          options: FormaPagamento.values,
          labelBuilder: (option) => option.label,
          selected: _formaPagamento == null ? {} : {_formaPagamento!},
          onChanged: (selected) => setState(
            () => _formaPagamento = selected.isEmpty ? null : selected.first,
          ),
        ),
        if (_formaPagamento == FormaPagamento.outro) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _formaPagamentoOutroController,
            icon: Icons.edit_outlined,
            hintText: 'Qual forma de pagamento',
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'STATUS',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppChipSelect<StatusPagamento>(
          options: StatusPagamento.values,
          labelBuilder: (option) => option.label,
          selected: {_status},
          onChanged: (selected) => setState(
            () => _status = selected.isEmpty
                ? StatusPagamento.pago
                : selected.first,
          ),
        ),
        if (_status == StatusPagamento.outro) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _statusOutroController,
            icon: Icons.edit_outlined,
            hintText: 'Qual status',
            errorText:
                _statusOutroController.text.isEmpty ||
                    _statusOutroController.text.trim().length > 3
                ? null
                : 'Informe pelo menos 4 caracteres.',
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Registrar pagamento',
          isLoading: _saving,
          onPressed: _canSave ? _save : null,
        ),
      ],
    );
  }
}
