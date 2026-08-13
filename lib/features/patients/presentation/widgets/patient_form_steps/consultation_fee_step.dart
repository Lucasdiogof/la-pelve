import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_b.dart';
import 'package:fisioterapia_pelvica/shared/utils/currency_input_formatter.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class ConsultationFeeStep extends StatefulWidget {
  const ConsultationFeeStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<ConsultationFeeStep> createState() => _ConsultationFeeStepState();
}

class _ConsultationFeeStepState extends State<ConsultationFeeStep> {
  late final _valorController = TextEditingController(
    text: widget.patient.consultationFee == null
        ? ''
        : CurrencyInputFormatter.format(widget.patient.consultationFee!),
  );

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsB(context.watch<LocaleCubit>().state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.consultationFeeDescription,
          style: TextStyle(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _valorController,
          icon: Icons.attach_money,
          hintText: t.consultationFeeHint,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: (value) => widget.onChanged(
            widget.patient.copyWith(
              consultationFee: CurrencyInputFormatter.parse(value),
            ),
          ),
        ),
      ],
    );
  }
}
