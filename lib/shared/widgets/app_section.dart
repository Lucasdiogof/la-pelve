import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Grupo de configurações/opções: overline + bloco contínuo (surface, borda,
/// raio [AppRadius.md], sem sombra). As linhas internas cuidam dos próprios
/// divisores (ex.: [AppListRow] com `showDivider` falso na última).
///
/// Não é para toda seção do app: listas principais e a ficha clínica ficam
/// direto sobre o fundo.
class AppSection extends StatelessWidget {
  const AppSection({required this.children, super.key, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s4,
              bottom: AppSpacing.s8,
            ),
            child: Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.overline.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        Material(
          color: context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(color: context.colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ],
    );
  }
}
