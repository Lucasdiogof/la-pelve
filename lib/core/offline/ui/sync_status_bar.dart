import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/offline/sync/sync_status_cubit.dart';
import 'package:la_pelve/core/offline/ui/sync_strings.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Faixa discreta de estado da sincronização, logo acima da barra de
/// navegação. Some quando está tudo sincronizado (a confirmação aparece por
/// poucos segundos). Não bloqueia a navegação; o toque abre a central de
/// sincronização com os detalhes.
class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncStatusCubit, SyncUiState>(
      builder: (context, state) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.bottomCenter,
        child: state.visible
            ? _Bar(state: state)
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.state});

  final SyncUiState state;

  @override
  Widget build(BuildContext context) {
    final t = SyncStrings(context.watch<LocaleCubit>().state);
    final colors = context.colors;
    final (IconData icon, String text, Color tint) = switch (state.kind) {
      SyncUiKind.offline => (
        Icons.cloud_off_outlined,
        t.offline(state.pending),
        colors.textSecondary,
      ),
      SyncUiKind.pending => (
        Icons.cloud_upload_outlined,
        t.pending(state.pending),
        colors.textSecondary,
      ),
      SyncUiKind.syncing => (Icons.sync, t.syncing, colors.primary),
      SyncUiKind.error => (
        Icons.error_outline,
        t.error(state.failed),
        colors.warning,
      ),
      SyncUiKind.conflict => (
        Icons.call_split,
        t.conflict(state.conflicts),
        colors.danger,
      ),
      _ => (Icons.cloud_done_outlined, t.synced, colors.success),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      label: text,
      child: Material(
        color: colors.surfaceMuted,
        child: InkWell(
          onTap: () => context.push('/sincronizacao'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.s8,
            ),
            child: Row(
              children: [
                if (state.kind == SyncUiKind.syncing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tint,
                    ),
                  )
                else
                  Icon(icon, size: 18, color: tint),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textPrimary),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
