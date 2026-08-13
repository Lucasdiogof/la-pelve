import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/lancamentos_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/lancamentos_form_state.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/shared/utils/currency_input_formatter.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/patient_picker_sheet.dart';
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
  final _formCubit = LancamentosFormCubit();

  @override
  void dispose() {
    _patientNameController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    _formaPagamentoOutroController.dispose();
    _statusOutroController.dispose();
    _formCubit.close();
    super.dispose();
  }

  bool _canSave(LancamentosFormState state) =>
      _patientNameController.text.trim().isNotEmpty &&
      state.data != null &&
      CurrencyInputFormatter.parse(_valorController.text) > 0 &&
      (state.formaPagamento != FormaPagamento.outro ||
          _formaPagamentoOutroController.text.trim().isNotEmpty) &&
      (state.status != StatusPagamento.outro ||
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
      _formCubit.selectPatient(selected);
      _patientNameController.text = selected.dadosPessoais.nome;
    }
  }

  Future<void> _save() async {
    final state = _formCubit.state;
    _formCubit.setSaving(true);
    showAppLoading();
    final result = await context.read<FinancialCubit>().addEntry(
      FinancialEntry(
        id: generateId(),
        patientId: state.patient?.id,
        patientName: _patientNameController.text.trim(),
        data: state.data!,
        valor: CurrencyInputFormatter.parse(_valorController.text),
        observacoes: _observacoesController.text.trim(),
        formaPagamento: state.formaPagamento,
        formaPagamentoOutraDescricao:
            state.formaPagamento == FormaPagamento.outro
            ? _formaPagamentoOutroController.text.trim()
            : null,
        status: state.status,
        statusOutraDescricao: state.status == StatusPagamento.outro
            ? _statusOutroController.text.trim()
            : null,
      ),
    );
    hideAppLoading();
    if (!mounted) return;
    switch (result) {
      case Success():
        _formCubit.reset();
        _patientNameController.clear();
        _valorController.clear();
        _observacoesController.clear();
        _formaPagamentoOutroController.clear();
        _statusOutroController.clear();
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
      child: BlocBuilder<LancamentosFormCubit, LancamentosFormState>(
        builder: (context, formState) => ListView(
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
              onChanged: (_) => _formCubit.onNomeChanged(),
            ),
            const SizedBox(height: 12),
            AppDateField(
              hintText: 'Data do pagamento',
              value: formState.data,
              onChanged: _formCubit.setData,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _valorController,
              icon: Icons.attach_money,
              hintText: 'Valor pago',
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              onChanged: (_) => _formCubit.notifyFieldChanged(),
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
              selected: formState.formaPagamento == null
                  ? {}
                  : {formState.formaPagamento!},
              onChanged: (selected) => _formCubit.setFormaPagamento(
                selected.isEmpty ? null : selected.first,
              ),
            ),
            if (formState.formaPagamento == FormaPagamento.outro) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _formaPagamentoOutroController,
                icon: Icons.edit_outlined,
                hintText: 'Qual forma de pagamento',
                onChanged: (_) => _formCubit.notifyFieldChanged(),
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
              selected: {formState.status},
              onChanged: (selected) => _formCubit.setStatus(
                selected.isEmpty ? StatusPagamento.pago : selected.first,
              ),
            ),
            if (formState.status == StatusPagamento.outro) ...[
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
                onChanged: (_) => _formCubit.notifyFieldChanged(),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Registrar pagamento',
              isLoading: formState.saving,
              onPressed: _canSave(formState) ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
