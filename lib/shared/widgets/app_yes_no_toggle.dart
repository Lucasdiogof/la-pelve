import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';

/// Pergunta sim/não com segmented control compacto. Tocar de novo na opção
/// selecionada desmarca (volta a `null`).
class AppYesNoToggle extends StatelessWidget {
  const AppYesNoToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.strings.shared;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(width: AppSpacing.s12),
        // Visual de 36px; a área de toque de cada opção ocupa 48px de altura.
        SizedBox(
          height: 48,
          child: Stack(
            children: [
              Positioned.fill(
                top: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.controlAll,
                    border: Border.all(color: context.colors.borderStrong),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Segment(
                    label: t.yes,
                    selected: value == true,
                    onTap: () => onChanged(value == true ? null : true),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      width: 1,
                      color: context.colors.borderStrong,
                    ),
                  ),
                  _Segment(
                    label: t.no,
                    selected: value == false,
                    onTap: () => onChanged(value == false ? null : false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.primary : Colors.transparent,
              borderRadius: AppRadius.controlAll,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? c.onPrimary : c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
