import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/home/l10n/home_strings.dart';
import 'package:la_pelve/features/home/presentation/widgets/home_panel.dart';

/// Ações rápidas: um único painel com grade 2x2 e divisores internos. As
/// quatro ações e seus destinos são os mesmos de antes.
/// Ações rápidas: um único painel com grade 2x2 e divisores internos. As
/// quatro ações e seus destinos são os mesmos de antes.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({required this.onNavigateToTab, super.key});

  final ValueChanged<int> onNavigateToTab;

  static const double _cellPadding = AppSpacing.s16;
  static const double _iconBox = 36;

  @override
  Widget build(BuildContext context) {
    final t = HomeStrings(context.watch<LocaleCubit>().state);
    // Os rótulos têm quebra de linha embutida (feita para o layout antigo de
    // 4 colunas); aqui cada ação tem largura para quebrar sozinha.
    String label(String raw) => raw.replaceAll('\n', ' ');
    final labels = [
      label(t.newPatientAction),
      label(t.scheduleAppointmentAction),
      label(t.addProgressNoteAction),
      label(t.addPaymentAction),
    ];
    final border = context.colors.border;
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500);
    return HomePanel(
      title: t.quickActionsTitle,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Decide o layout uma vez para a grade inteira: se a palavra mais
            // longa de algum rótulo não cabe ao lado do ícone (fonte ampliada
            // ou tela estreita), o ícone sobe em todas as células. Assim
            // nenhuma palavra é quebrada no meio e as quatro ações ficam
            // iguais.
            final cellWidth = (constraints.maxWidth - 1) / 2 - 2 * _cellPadding;
            final longestWord = _longestWordWidth(
              labels,
              labelStyle,
              MediaQuery.textScalerOf(context),
            );
            final stacked = longestWord > cellWidth - _iconBox - AppSpacing.s12;
            Widget cell(int i, IconData icon, VoidCallback onTap) =>
                _QuickAction(
                  icon: icon,
                  label: labels[i],
                  style: labelStyle,
                  stacked: stacked,
                  onTap: onTap,
                );
            Widget row(Widget a, Widget b) => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: a),
                  VerticalDivider(width: 1, color: border),
                  Expanded(child: b),
                ],
              ),
            );
            return Column(
              children: [
                Divider(height: 1, color: border),
                row(
                  cell(
                    0,
                    Icons.person_add_alt_outlined,
                    () => context.push('/pacientes/novo'),
                  ),
                  cell(
                    1,
                    Icons.event_available_outlined,
                    () => context.push('/agenda/novo'),
                  ),
                ),
                Divider(height: 1, color: border),
                row(
                  cell(2, Icons.edit_note_outlined, () => onNavigateToTab(1)),
                  cell(3, Icons.payments_outlined, () => onNavigateToTab(3)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _longestWordWidth(
    List<String> labels,
    TextStyle style,
    TextScaler scaler,
  ) {
    var longest = 0.0;
    for (final word in labels.expand((l) => l.split(' '))) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      longest = math.max(longest, painter.width);
      painter.dispose();
    }
    return longest;
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.style,
    required this.stacked,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TextStyle style;
  final bool stacked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Mesmo tratamento para as quatro ações: a cor não diferencia ação, só
    // marca que o bloco é interativo.
    final iconBox = Container(
      width: QuickActionsSection._iconBox,
      height: QuickActionsSection._iconBox,
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(icon, size: 20, color: c.primary),
    );
    final text = Text(label, style: style);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(QuickActionsSection._cellPadding),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  iconBox,
                  const SizedBox(height: AppSpacing.s8),
                  text,
                ],
              )
            : Row(
                children: [
                  iconBox,
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(child: text),
                ],
              ),
      ),
    );
  }
}
