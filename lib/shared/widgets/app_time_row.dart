import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';

/// Linha de horário (Home e Agenda): coluna de horário de largura fixa,
/// nome e status. Componente visual puro: recebe tudo já formatado.
///
/// A Poppins empacotada não tem dígitos tabulares, então o alinhamento da
/// coluna vem da largura fixa [timeColumnWidth], não da fonte.
class AppTimeRow extends StatelessWidget {
  const AppTimeRow({
    required this.time,
    required this.title,
    required this.statusLabel,
    required this.statusTone,
    super.key,
    this.timeCaption,
    this.subtitle,
    this.onTap,
    this.onStatusTap,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
  });

  /// Horário já formatado ("10:04").
  final String time;

  /// Texto pequeno acima do horário (ex.: "AMANHÃ"), opcional.
  final String? timeCaption;
  final String title;
  final String? subtitle;
  final String statusLabel;
  final AppStatusTone statusTone;
  final VoidCallback? onTap;

  /// Toque no status (ex.: abrir o seletor de status). Área >= 48.
  final VoidCallback? onStatusTap;
  final bool showDivider;
  final EdgeInsets padding;

  static const double timeColumnWidth = 64;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final badge = AppStatusBadge(label: statusLabel, tone: statusTone);
    // A coluna acompanha o tamanho de texto do sistema para o horário e a
    // legenda não quebrarem com fonte ampliada.
    final timeWidth = MediaQuery.textScalerOf(
      context,
    ).scale(timeColumnWidth).clamp(timeColumnWidth, timeColumnWidth * 1.6);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  SizedBox(
                    width: timeWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (timeCaption != null)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              timeCaption!.toUpperCase(),
                              maxLines: 1,
                              style: textTheme.overline.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                        Text(
                          time,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  if (onStatusTap == null)
                    badge
                  else
                    InkWell(
                      onTap: onStatusTap,
                      borderRadius: AppRadius.smAll,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          minWidth: 48,
                        ),
                        child: Center(widthFactor: 1, child: badge),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showDivider) Divider(indent: padding.left + timeWidth, height: 1),
        ],
      ),
    );
  }
}
