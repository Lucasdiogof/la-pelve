import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/current_user.dart';
import 'package:fisioterapia_pelvica/features/home/l10n/home_strings.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/profile_cubit.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final t = HomeStrings(context.watch<LocaleCubit>().state);
    final now = DateTime.now();
    final textTheme = Theme.of(context).textTheme;
    final name = currentUserName();
    final firstName = name?.split(' ').first ?? t.defaultUserName;
    final photoUrl = context.watch<ProfileCubit>().state.photoUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.greetingFor(now.hour),
                  style: textTheme.bodyLarge?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.dateLine(now.weekday, now.day, now.month),
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () => context.push('/perfil'),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: context.colors.primary,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl != null
                  ? null
                  : Text(
                      firstName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
