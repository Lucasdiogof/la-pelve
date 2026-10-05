import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Tom semântico de um status. É o único vocabulário de cor de status do
/// app: cada enum de domínio se mapeia para um tom (ver
/// `appointment_status_style.dart`), nunca direto para uma cor.
enum AppStatusTone {
  /// Estado padrão, sem destaque (ex.: agendado).
  neutral,

  /// Destaque da marca (ex.: confirmado).
  primary,
  success,
  warning,
  danger,

  /// Estado inativo/encerrado (ex.: cancelado).
  muted,
}

extension AppStatusToneColors on AppStatusTone {
  Color foreground(AppColors c) => switch (this) {
    AppStatusTone.neutral => c.textPrimary,
    AppStatusTone.primary => c.primary,
    AppStatusTone.success => c.success,
    AppStatusTone.warning => c.warning,
    AppStatusTone.danger => c.danger,
    AppStatusTone.muted => c.textSecondary,
  };

  Color background(AppColors c) => switch (this) {
    AppStatusTone.neutral => c.surfaceMuted,
    AppStatusTone.muted => Colors.transparent,
    _ => foreground(c).withValues(alpha: 0.12),
  };
}

/// Badge compacto de status: texto pequeno, cor semântica, raio
/// [AppRadius.xs]. Não é tocável por si só; quem precisa de toque envolve
/// num InkWell com área >= 48.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({required this.label, required this.tone, super.key});

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = tone.foreground(c);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tone.background(c),
        borderRadius: AppRadius.xsAll,
        border: tone == AppStatusTone.muted
            ? Border.all(color: c.border)
            : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
