import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/l10n/agenda_strings.dart';
import 'package:la_pelve/features/agenda/presentation/widgets/appointment_status_style.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';

/// Seletor de status: lista simples (radio + badge do status, que já traz o
/// nome), sem card por opção. Devolve o status escolhido via `Navigator.pop`.
class StatusPickerSheet extends StatelessWidget {
  const StatusPickerSheet({required this.current, super.key});

  final AppointmentStatus current;

  @override
  Widget build(BuildContext context) {
    final t = AgendaStrings(context.watch<LocaleCubit>().state);
    final textTheme = Theme.of(context).textTheme;
    return AppSheet(
      children: [
        Text(
          t.statusPickerTitle,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        // As 6 opções rolam dentro do sheet quando a altura não basta
        // (o bottom sheet limita a 9/16 da tela: em 360x640 o conteúdo
        // inteiro estourava). Em telas normais cabe tudo e não rola.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final status in AppointmentStatus.values)
                  ListTile(
                    onTap: () => Navigator.of(context).pop(status),
                    contentPadding: EdgeInsets.zero,
                    selected: status == current,
                    leading: Icon(
                      status == current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: status == current
                          ? context.colors.primary
                          : context.colors.textSecondary,
                    ),
                    // O badge é o próprio rótulo da opção (prévia do tom do
                    // status), para o nome não aparecer duplicado ao lado dele.
                    title: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppStatusBadge(
                        label: status.label(t.language),
                        tone: status.tone,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
