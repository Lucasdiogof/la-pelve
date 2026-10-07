import 'dart:math' as math;

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
    this.minHeight = 56,
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

  /// Altura mínima da linha (área de toque). Padrão 56 (Agenda); a Home usa
  /// 48 para o grupo do dia ficar mais coeso. Não usar menos de 48.
  final double minHeight;

  static const double timeColumnWidth = 64;

  /// Largura mínima (em escala 1.0) para nome e status lado a lado; abaixo
  /// disso o status desce para baixo do nome.
  static const double minInlineWidth = 220;

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
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: padding,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scaler = MediaQuery.textScalerOf(context);
                  final titleStyle = textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                  );
                  final badgeStyle = textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  );
                  // Largura que sobraria para o nome com o status ao lado.
                  final badgeWidth = math.max(
                    _textWidth(statusLabel, badgeStyle, scaler) +
                        AppSpacing.s16,
                    onStatusTap == null ? 0.0 : 48.0,
                  );
                  final inlineNameWidth =
                      constraints.maxWidth -
                      timeWidth -
                      AppSpacing.s8 -
                      badgeWidth;
                  // Se a palavra mais longa do nome não cabe ao lado do
                  // status, o status desce para baixo do nome: nenhuma
                  // palavra é quebrada no meio.
                  final longestWord = title
                      .split(RegExp(r'\s+'))
                      .map((w) => _textWidth(w, titleStyle, scaler))
                      .fold<double>(0, math.max);
                  // Regra uniforme por largura/escala (todas as linhas da lista
                  // ficam iguais) + garantias: nenhuma palavra quebrada no
                  // meio e nome em no máximo 2 linhas.
                  final narrow =
                      constraints.maxWidth - timeWidth <
                      scaler.scale(minInlineWidth);
                  final namePainter = TextPainter(
                    text: TextSpan(text: title, style: titleStyle),
                    textDirection: TextDirection.ltr,
                    textScaler: scaler,
                    maxLines: 2,
                  )..layout(maxWidth: math.max(0, inlineNameWidth));
                  final overflowsInline = namePainter.didExceedMaxLines;
                  namePainter.dispose();
                  final stacked =
                      narrow ||
                      overflowsInline ||
                      longestWord > inlineNameWidth;
                  final status = onStatusTap == null
                      ? badge
                      : InkWell(
                          onTap: onStatusTap,
                          borderRadius: AppRadius.smAll,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 48,
                              minWidth: 48,
                            ),
                            child: Align(
                              widthFactor: 1,
                              heightFactor: 1,
                              alignment: stacked
                                  ? Alignment.centerLeft
                                  : Alignment.center,
                              child: badge,
                            ),
                          ),
                        );
                  return Row(
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
                              // Até 2 linhas: com fonte ampliada o nome não
                              // vira só reticências.
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
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
                              if (stacked) ...[
                                const SizedBox(height: AppSpacing.s4),
                                status,
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (!stacked) ...[
                        const SizedBox(width: AppSpacing.s8),
                        status,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          if (showDivider)
            Divider(
              indent: padding.left + timeWidth,
              endIndent: padding.right,
              height: 1,
            ),
        ],
      ),
    );
  }
}

double _textWidth(String text, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
