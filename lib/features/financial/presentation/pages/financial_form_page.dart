import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/financial/l10n/financial_strings.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/payment_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/payment_form_state.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/shared/utils/currency_input_formatter.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/patient_picker_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class FinancialFormPage extends StatefulWidget {
  const FinancialFormPage({super.key});

  @override
  State<FinancialFormPage> createState() => _FinancialFormPageState();
}

class _FinancialFormPageState extends State<FinancialFormPage> {
  final _patientNameController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _formaPagamentoOutroController = TextEditingController();
  final _statusOutroController = TextEditingController();
  final _formCubit = PaymentFormCubit();

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

  bool _canSave(PaymentFormState state) =>
      _patientNameController.text.trim().isNotEmpty &&
      state.date != null &&
      CurrencyInputFormatter.parse(_valorController.text) > 0 &&
      (state.paymentMethod != PaymentMethod.other ||
          _formaPagamentoOutroController.text.trim().isNotEmpty) &&
      (state.status != PaymentStatus.other ||
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
      _patientNameController.text = selected.personalInfo.name;
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
        date: state.date!,
        amount: CurrencyInputFormatter.parse(_valorController.text),
        notes: _observacoesController.text.trim(),
        paymentMethod: state.paymentMethod,
        otherPaymentMethodDescription:
            state.paymentMethod == PaymentMethod.other
            ? _formaPagamentoOutroController.text.trim()
            : null,
        status: state.status,
        otherStatusDescription: state.status == PaymentStatus.other
            ? _statusOutroController.text.trim()
            : null,
      ),
    );
    hideAppLoading();
    if (!mounted) return;
    final t = FinancialStrings(context.read<LocaleCubit>().state);
    switch (result) {
      case Success():
        context.pop();
        await AppInfoBottomSheet.showSuccess(
          context,
          description: t.paymentRegisteredSuccess,
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
    final t = FinancialStrings(context.watch<LocaleCubit>().state);
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<PaymentFormCubit, PaymentFormState>(
        builder: (context, formState) => Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            children: [
              ModernAppBar(
                title: t.formPageTitle,
                subtitle: t.formPageSubtitle,
                showBackButton: true,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    AppTextField(
                      controller: _patientNameController,
                      icon: Icons.person_outline,
                      hintText: t.patientNameHint,
                      suffixIcon: hasPatients
                          ? IconButton(
                              icon: Icon(
                                Icons.list_alt_outlined,
                                color: context.colors.textSecondary,
                              ),
                              tooltip: t.selectRegisteredPatientTooltip,
                              onPressed: _selectPatient,
                            )
                          : null,
                      onChanged: (_) => _formCubit.onNomeChanged(),
                    ),
                    const SizedBox(height: 12),
                    AppDateField(
                      hintText: t.paymentDateHint,
                      value: formState.date,
                      onChanged: _formCubit.setData,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _valorController,
                      icon: Icons.attach_money,
                      hintText: t.amountPaidHint,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (_) => _formCubit.notifyFieldChanged(),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _observacoesController,
                      icon: Icons.description_outlined,
                      hintText: t.notesHint,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.paymentMethodSectionTitle,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppChipSelect<PaymentMethod>(
                      options: PaymentMethod.values,
                      labelBuilder: (option) => option.label(t.language),
                      selected: formState.paymentMethod == null
                          ? {}
                          : {formState.paymentMethod!},
                      onChanged: (selected) => _formCubit.setFormaPagamento(
                        selected.isEmpty ? null : selected.first,
                      ),
                    ),
                    if (formState.paymentMethod == PaymentMethod.other) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _formaPagamentoOutroController,
                        icon: Icons.edit_outlined,
                        hintText: t.whichPaymentMethodHint,
                        onChanged: (_) => _formCubit.notifyFieldChanged(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      t.statusSectionTitle,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppChipSelect<PaymentStatus>(
                      options: PaymentStatus.values,
                      labelBuilder: (option) => option.label(t.language),
                      selected: {formState.status},
                      onChanged: (selected) => _formCubit.setStatus(
                        selected.isEmpty ? PaymentStatus.paid : selected.first,
                      ),
                    ),
                    if (formState.status == PaymentStatus.other) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _statusOutroController,
                        icon: Icons.edit_outlined,
                        hintText: t.whichStatusHint,
                        errorText:
                            _statusOutroController.text.isEmpty ||
                                _statusOutroController.text.trim().length > 3
                            ? null
                            : t.statusMinCharsError,
                        onChanged: (_) => _formCubit.notifyFieldChanged(),
                      ),
                    ],
                  ],
                ),
              ),
              AppBottomActionBar(
                child: PrimaryButton(
                  label: t.registerPaymentButton,
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
