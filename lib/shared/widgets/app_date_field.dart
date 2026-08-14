import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.hintText,
    required this.value,
    required this.onChanged,
    super.key,
    this.firstDate,
    this.lastDate,
  });

  final String hintText;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  static String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: AppTextField(
        icon: Icons.calendar_today_outlined,
        hintText: hintText,
        readOnly: true,
        enableInteractiveSelection: false,
        controller: TextEditingController(
          text: value == null ? '' : format(value!),
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: firstDate ?? DateTime(2000),
            lastDate: lastDate ?? DateTime(2100),
          );
          if (picked != null) onChanged(picked);
        },
      ),
    );
  }
}
