import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';

/// Linha de um painel ([AppSection]) do Perfil: ícone neutro, rótulo/valor e
/// trailing opcional. Sem card nem borda próprios — quem agrupa (o painel)
/// cuida disso; aqui só o divisor entre linhas (via [showDivider]).
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    super.key,
  });

  final IconData icon;
  final String label;

  /// Valor atual do campo, mostrado como uma segunda linha abaixo do
  /// [label]. Quando omitido, a linha mostra só o [label] — para entradas
  /// de navegação/ação sem um "valor atual" (ex.: WhatsApp, Sair da conta).
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  static const double _dividerIndent = AppSpacing.s16 + 20 + AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: context.colors.textSecondary),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (value != null)
                        Text(
                          label,
                          style: textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      Text(
                        value == null
                            ? label
                            : (value!.isEmpty ? t.notInformedLabel : value!),
                        style: value == null
                            ? textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              )
                            : textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.colors.textPrimary,
                              ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.s8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(indent: _dividerIndent, height: 1),
      ],
    );
  }
}
