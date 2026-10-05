import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Linha de lista sem card: leading opcional, título, subtítulo, trailing e
/// divisor inset alinhado ao texto. Altura mínima de 56.
///
/// Não conhece entidade nenhuma: recebe widgets/strings prontos.
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  /// Recuo horizontal da linha. Dentro de uma [AppSection], use
  /// `EdgeInsets.symmetric(horizontal: AppSpacing.s16)`.
  final EdgeInsets padding;

  /// Leading padrão de 36px + espaço de 12 até o texto.
  static const double _leadingSlot = 36 + AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dividerIndent = padding.left + (leading == null ? 0 : _leadingSlot);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: padding.copyWith(
                top: AppSpacing.s12,
                bottom: AppSpacing.s12,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    SizedBox(width: 36, child: Center(child: leading)),
                    const SizedBox(width: AppSpacing.s12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.s12),
                    IconTheme.merge(
                      data: IconThemeData(
                        color: context.colors.textSecondary,
                        size: 20,
                      ),
                      child: trailing!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showDivider) Divider(indent: dividerIndent, height: 1),
        ],
      ),
    );
  }
}

/// Avatar de iniciais padrão das listas (36px, primaryContainer).
class AppInitialAvatar extends StatelessWidget {
  const AppInitialAvatar({required this.name, super.key, this.size = 36});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: context.colors.primaryContainer,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: context.colors.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
