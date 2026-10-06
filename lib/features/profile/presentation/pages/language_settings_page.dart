import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/profile/presentation/widgets/profile_option_row.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.strings.profile;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          ModernAppBar(
            title: t.languagePageTitle,
            subtitle: t.languagePageSubtitle,
            showBackButton: true,
          ),
          Expanded(
            child: BlocBuilder<LocaleCubit, AppLanguage>(
              builder: (context, language) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.s8,
                  AppSpacing.gutter,
                  AppSpacing.s32,
                ),
                children: [
                  AppSection(
                    children: [
                      for (final (i, option) in AppLanguage.values.indexed)
                        ProfileOptionRow(
                          title: option.label,
                          description: t.languageOptionDescription(option),
                          selected: language == option,
                          showDivider: i != AppLanguage.values.length - 1,
                          onTap: () =>
                              context.read<LocaleCubit>().setLanguage(option),
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
