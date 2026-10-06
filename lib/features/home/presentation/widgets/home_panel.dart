import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Superfície de um agrupamento da Home (um painel por seção, nunca por
/// item): surface + borda de 1px + raio [AppRadius.lg], sem sombra. O
/// título e a ação opcional ficam dentro do painel.
///
/// Raio lg (16) por decisão de design da Home: são os blocos principais da
/// tela; listas e grupos comuns seguem com [AppRadius.md].
class HomePanel extends StatelessWidget {
  const HomePanel({
    required this.title,
    required this.child,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  /// Recuo horizontal do conteúdo dentro do painel.
  static const double inset = AppSpacing.s16;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasAction = actionLabel != null && onAction != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          // Borda externa um pouco mais suave que os divisores internos
          // (border puxado 30% na direção do surface): continua definindo o
          // painel, sem pesar. Vale para claro e escuro.
          side: BorderSide(
            color: Color.lerp(
              context.colors.border,
              context.colors.surface,
              0.3,
            )!,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  AppSpacing.s12,
                  // O TextButton tem padding próprio; o texto da ação fica
                  // alinhado ao recuo do painel.
                  hasAction ? AppSpacing.s4 : inset,
                  AppSpacing.s4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: textTheme.titleMedium),
                      ),
                    ),
                    if (hasAction)
                      TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          textStyle: textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(actionLabel!),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
