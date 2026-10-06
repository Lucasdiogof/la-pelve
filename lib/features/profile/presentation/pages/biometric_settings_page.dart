import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/services/biometric_service.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/features/profile/presentation/cubit/biometric_settings_cubit.dart';
import 'package:la_pelve/features/profile/presentation/cubit/biometric_settings_state.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';

class BiometricSettingsPage extends StatelessWidget {
  const BiometricSettingsPage({super.key});

  Future<void> _toggle(BuildContext context, bool value) async {
    final cubit = context.read<BiometricSettingsCubit>();
    final biometricService = sl<BiometricService>();
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    if (value) {
      final supported = await biometricService.isDeviceSupported();
      if (!supported) {
        if (context.mounted) {
          await AppInfoBottomSheet.showError(
            context,
            description: t.biometricUnsupportedDescription,
          );
        }
        return;
      }
      final authenticated = await biometricService.authenticate(
        t.biometricAuthReason,
      );
      if (!authenticated) return;
    }
    await cubit.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
    final textTheme = Theme.of(context).textTheme;
    return BlocProvider(
      create: (_) => BiometricSettingsCubit(),
      child: BlocBuilder<BiometricSettingsCubit, BiometricSettingsState>(
        builder: (context, state) => Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            children: [
              ModernAppBar(
                title: t.biometricPageTitle,
                subtitle: t.biometricPageSubtitle,
                showBackButton: true,
              ),
              Expanded(
                child: state.loading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: context.colors.primary,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.s8,
                          AppSpacing.gutter,
                          AppSpacing.s32,
                        ),
                        children: [
                          AppSection(
                            children: [
                              SwitchListTile(
                                value: state.enabled,
                                onChanged: (value) => _toggle(context, value),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s16,
                                ),
                                title: Text(
                                  t.biometricSwitchTitle,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  t.biometricSwitchSubtitle,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
