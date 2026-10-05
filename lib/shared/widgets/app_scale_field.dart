import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

class AppScaleField extends StatelessWidget {
  const AppScaleField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 10,
  });

  final String label;
  final int? value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final current = value ?? min;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(label, style: textTheme.bodyLarge)),
            const SizedBox(width: 12),
            Text(
              '$current',
              textAlign: TextAlign.end,
              style: textTheme.metricSmall.copyWith(
                color: context.colors.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: current.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$current',
          onChanged: (newValue) => onChanged(newValue.round()),
        ),
      ],
    );
  }
}
