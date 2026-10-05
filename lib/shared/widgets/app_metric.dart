import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Métrica editorial: rótulo pequeno + número em destaque. Sem card e sem
/// ícone; quem compõe decide divisores e espaçamento.
class AppMetric extends StatelessWidget {
  const AppMetric({
    required this.label,
    required this.value,
    super.key,
    this.caption,
    this.large = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;

  /// Linha auxiliar abaixo do número (ex.: período).
  final String? caption;

  /// `true` usa [AppTypography.metric] (28); `false`, [AppTypography.metricSmall] (20).
  final bool large;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final align = switch (crossAxisAlignment) {
      CrossAxisAlignment.center => TextAlign.center,
      CrossAxisAlignment.end => TextAlign.end,
      _ => TextAlign.start,
    };
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: align,
          style: textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        // Um número nunca quebra no meio: se não couber, reduz.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: switch (crossAxisAlignment) {
            CrossAxisAlignment.center => Alignment.center,
            CrossAxisAlignment.end => Alignment.centerRight,
            _ => Alignment.centerLeft,
          },
          child: Text(
            value,
            maxLines: 1,
            textAlign: align,
            style: large ? textTheme.metric : textTheme.metricSmall,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            textAlign: align,
            style: textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
