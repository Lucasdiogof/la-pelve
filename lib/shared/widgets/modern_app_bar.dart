import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Cabeçalho das telas: título neutro (headlineSmall), subtítulo opcional e
/// ações neutras com área de toque >= 48. Sem sombra.
class ModernAppBar extends StatelessWidget {
  const ModernAppBar({
    required this.title,
    super.key,
    this.subtitle,
    this.actionIcon,
    this.onAction,
    this.actionTooltip,
    this.trailing,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? actionTooltip;
  final Widget? trailing;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasActions = actionIcon != null || trailing != null;
    return ColoredBox(
      color: context.colors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            showBackButton ? AppSpacing.s4 : AppSpacing.gutter,
            AppSpacing.s12,
            hasActions ? AppSpacing.s4 : AppSpacing.gutter,
            AppSpacing.s12,
          ),
          child: Row(
            children: [
              if (showBackButton) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: AppSpacing.s4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.headlineSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionIcon != null)
                IconButton(
                  icon: Icon(actionIcon),
                  tooltip: actionTooltip,
                  onPressed: onAction,
                ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
