import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/services/biometric_service.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/profile/l10n/profile_strings.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/biometric_settings_cubit.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/biometric_settings_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

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
                        padding: const EdgeInsets.all(24),
                        children: [
                          Material(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: SwitchListTile(
                              value: state.enabled,
                              onChanged: (value) => _toggle(context, value),
                              activeThumbColor: context.colors.primary,
                              title: Text(t.biometricSwitchTitle),
                              subtitle: Text(t.biometricSwitchSubtitle),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
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
