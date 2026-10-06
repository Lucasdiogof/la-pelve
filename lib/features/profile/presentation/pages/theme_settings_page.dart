import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/core/theme/theme_cubit.dart';
import 'package:la_pelve/core/theme/theme_mode_label.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/features/profile/presentation/widgets/profile_option_row.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          ModernAppBar(
            title: t.themePageTitle,
            subtitle: t.themePageSubtitle,
            showBackButton: true,
          ),
          Expanded(
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.s8,
                  AppSpacing.gutter,
                  AppSpacing.s32,
                ),
                children: [
                  AppSection(
                    children: [
                      for (final (i, option) in ThemeMode.values.indexed)
                        ProfileOptionRow(
                          title: themeModeLabel(option, t.language),
                          description: t.themeOptionDescription(option),
                          selected: mode == option,
                          showDivider: i != ThemeMode.values.length - 1,
                          onTap: () =>
                              context.read<ThemeCubit>().setMode(option),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
