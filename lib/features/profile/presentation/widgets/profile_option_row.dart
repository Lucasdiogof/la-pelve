import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';

/// Opção de escolha única (Tema, Idioma) dentro de um painel ([AppSection]).
/// A seleção é indicada só por um check em primary à direita; as demais
/// opções reservam o mesmo espaço para o texto não se mover.
class ProfileOptionRow extends StatelessWidget {
  const ProfileOptionRow({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
    this.showDivider = true,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  static const double _indicatorSize = 20;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AppListRow(
        title: title,
        subtitle: description,
        onTap: onTap,
        showDivider: showDivider,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        trailing: selected
            ? Icon(
                Icons.check,
                size: _indicatorSize,
                color: context.colors.primary,
              )
            : const SizedBox(width: _indicatorSize, height: _indicatorSize),
      ),
    );
  }
}
