import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';

class AppChipSelect<T> extends StatelessWidget {
  const AppChipSelect({
    required this.options,
    required this.labelBuilder,
    required this.selected,
    required this.onChanged,
    this.multiSelect = false,
    super.key,
  });

  final List<T> options;
  final String Function(T option) labelBuilder;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(labelBuilder(option)),
          selected: isSelected,
          onSelected: (value) {
            if (multiSelect) {
              final next = Set<T>.from(selected);
              if (value) {
                next.add(option);
              } else {
                next.remove(option);
              }
              onChanged(next);
            } else {
              onChanged(value ? {option} : <T>{});
            }
          },
          showCheckmark: false,
          selectedColor: context.colors.primary,
          backgroundColor: context.colors.surface,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : context.colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: isSelected ? context.colors.primary : context.colors.border,
          ),
          shape: const StadiumBorder(),
        );
      }).toList(),
    );
  }
}
