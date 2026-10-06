import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Campo de texto com label permanente acima.
///
/// - [label]: texto fixo acima do campo. **Campos novos devem sempre passar
///   [label] explícito.**
/// - [hintText]: exemplo/placeholder dentro do campo (opcional quando há
///   [label]).
/// - [icon]: opcional, neutro, sem círculo decorativo.
///
/// Fallback LEGADO: quando [label] é omitido, o [hintText] vira o label e o
/// campo fica sem placeholder. Existe só para os call sites anteriores ao
/// Design System V2 cujo hint já é um rótulo real (auditados na Fase 2);
/// não crie novos call sites dependendo dele.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.errorText,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.inputFormatters,
    this.iconColor,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.enableInteractiveSelection = true,
    this.textCapitalization = TextCapitalization.none,
  }) : assert(
         label != null || hintText != null,
         'Passe label (preferível) ou, no legado, hintText.',
       );

  final String? label;
  final IconData? icon;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? errorText;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final Color? iconColor;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enableInteractiveSelection;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Fallback legado (ver doc da classe).
    final effectiveLabel = label ?? hintText ?? '';
    final placeholder = label == null ? null : hintText;
    // O label visual e o campo viram um único nó de acessibilidade: o leitor
    // de tela anuncia "Nome, campo de texto".
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (effectiveLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                effectiveLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            readOnly: readOnly,
            enableInteractiveSelection: enableInteractiveSelection,
            onTap: onTap,
            maxLines: obscureText ? 1 : maxLines,
            minLines: obscureText ? null : minLines,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: placeholder,
              errorText: errorText,
              suffixIcon: suffixIcon,
              prefixIcon: icon == null
                  ? null
                  : Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? context.colors.textSecondary,
                    ),
              contentPadding: EdgeInsets.fromLTRB(
                icon == null ? AppSpacing.s16 : 0,
                14,
                AppSpacing.s16,
                14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
