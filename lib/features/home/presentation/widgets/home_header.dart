import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/core/utils/current_user.dart';
import 'package:la_pelve/features/home/l10n/home_strings.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';

/// Cabeçalho da Home: saudação, nome, data e avatar (abre o Perfil).
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    final t = HomeStrings(context.watch<LocaleCubit>().state);
    final now = DateTime.now();
    final textTheme = Theme.of(context).textTheme;
    final name = currentUserName();
    final firstName = name?.split(' ').first ?? t.defaultUserName;
    final photoUrl = context.watch<ProfileCubit>().state.photoUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.s8,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.greetingFor(now.hour),
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(firstName, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  t.dateLine(now.weekday, now.day, now.month),
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Semantics(
            button: true,
            label: context.strings.profile.profilePageTitle,
            child: InkResponse(
              onTap: () => context.push('/perfil'),
              radius: 24,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: photoUrl != null
                      ? CircleAvatar(
                          radius: _avatarSize / 2,
                          backgroundColor: context.colors.primaryContainer,
                          backgroundImage: NetworkImage(photoUrl),
                        )
                      : ExcludeSemantics(
                          child: AppInitialAvatar(
                            name: firstName,
                            size: _avatarSize,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
