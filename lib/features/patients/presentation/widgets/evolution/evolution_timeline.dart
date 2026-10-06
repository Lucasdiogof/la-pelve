import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';

/// Histórico de evoluções como linha do tempo discreta dentro de UM painel
/// (surface + borda, sem sombra). Entradas consecutivas com a mesma data
/// dividem um único marcador/cabeçalho de data; a ordem é a que já chegou da
/// tela (nada é reordenado aqui). Só apresentação: nenhuma regra clínica.
class EvolutionTimeline extends StatelessWidget {
  const EvolutionTimeline({
    required this.entries,
    required this.t,
    required this.onEdit,
    required this.onMore,
    super.key,
  });

  final List<EvolutionEntry> entries;
  final PatientsStrings t;
  final ValueChanged<EvolutionEntry> onEdit;
  final ValueChanged<EvolutionEntry> onMore;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Agrupa VISUALMENTE entradas consecutivas com a mesma data.
  static List<List<EvolutionEntry>> groupByDay(List<EvolutionEntry> entries) {
    final groups = <List<EvolutionEntry>>[];
    for (final entry in entries) {
      if (groups.isNotEmpty && _sameDay(groups.last.first.date, entry.date)) {
        groups.last.add(entry);
      } else {
        groups.add([entry]);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupByDay(entries);
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        // Direita menor: o botão de excluir já tem folga interna de 12.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s4,
          AppSpacing.s16,
        ),
        child: Column(
          children: [
            for (var i = 0; i < groups.length; i++)
              EvolutionTimelineGroup(
                entries: groups[i],
                t: t,
                isFirst: i == 0,
                isLast: i == groups.length - 1,
                onEdit: onEdit,
                onMore: onMore,
              ),
          ],
        ),
      ),
    );
  }
}

/// Um marcador de data com as evoluções daquele dia.
class EvolutionTimelineGroup extends StatelessWidget {
  const EvolutionTimelineGroup({
    required this.entries,
    required this.t,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onMore,
    super.key,
  });

  final List<EvolutionEntry> entries;
  final PatientsStrings t;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<EvolutionEntry> onEdit;
  final ValueChanged<EvolutionEntry> onMore;

  static const double _railWidth = 16;
  static const double _markerSize = 8;
  static const double _contentGap = AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateStyle = textTheme.titleSmall!;
    // Altura da linha da data (já com a escala de texto): o marcador e o início
    // da linha vertical se alinham ao centro dela, sem medir nada.
    final dateLineHeight =
        MediaQuery.textScalerOf(context).scale(dateStyle.fontSize!) *
        (dateStyle.height ?? 1.4);
    final center = dateLineHeight / 2;
    final lineColor = context.colors.border;
    const contentLeft = _railWidth + _contentGap;

    final Widget? line;
    if (isFirst && isLast) {
      line = null;
    } else if (isFirst) {
      line = Positioned(
        top: center,
        bottom: 0,
        left: _lineLeft,
        child: _line(lineColor),
      );
    } else if (isLast) {
      line = Positioned(
        top: 0,
        height: center,
        left: _lineLeft,
        child: _line(lineColor),
      );
    } else {
      line = Positioned(
        top: 0,
        bottom: 0,
        left: _lineLeft,
        child: _line(lineColor),
      );
    }

    return Stack(
      children: [
        ?line,
        Padding(
          padding: EdgeInsets.only(
            left: contentLeft,
            bottom: isLast ? 0 : AppSpacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppDateField.format(entries.first.date),
                style: dateStyle.copyWith(color: context.colors.textPrimary),
              ),
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    endIndent: AppSpacing.s12,
                    color: context.colors.border,
                  ),
                EvolutionTimelineItem(
                  entry: entries[i],
                  t: t,
                  onEdit: () => onEdit(entries[i]),
                  onMore: () => onMore(entries[i]),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: (_railWidth - _markerSize) / 2,
          top: center - _markerSize / 2,
          child: Container(
            width: _markerSize,
            height: _markerSize,
            decoration: BoxDecoration(
              // Preenchido com a surface: esconde a linha atrás do anel oco.
              color: context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.textHint, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  static const double _lineLeft = (_railWidth - 1) / 2;

  static Widget _line(Color color) =>
      SizedBox(width: 1, child: ColoredBox(color: color));
}

/// Texto da evolução (inteiro, sem limite de linhas), legenda de edição e a
/// ação secundária "mais" como área independente da edição.
class EvolutionTimelineItem extends StatelessWidget {
  const EvolutionTimelineItem({
    required this.entry,
    required this.t,
    required this.onEdit,
    required this.onMore,
    super.key,
  });

  final EvolutionEntry entry;
  final PatientsStrings t;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // O texto ocupa toda a largura do item. O botão "mais" (toque 48x48) fica
    // no canto inferior direito, sobre a faixa da legenda de edição (28 de
    // altura) e o respiro inferior do item: o ícone cai dentro dessa faixa, sem
    // tocar o texto, e só o toque invade levemente a base da última linha.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          child: InkWell(
            onTap: onEdit,
            borderRadius: AppRadius.smAll,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(
                    height: 28,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: entry.updatedAt == null
                            ? null
                            : Text(
                                t.editedOn(
                                  AppDateField.format(entry.updatedAt!),
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: IconButton(
            icon: const Icon(Icons.more_horiz),
            color: context.colors.textSecondary,
            tooltip: t.moreOptionsTooltip,
            onPressed: onMore,
          ),
        ),
      ],
    );
  }
}
