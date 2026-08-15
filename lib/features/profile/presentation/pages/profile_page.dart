import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/router/app_page.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/theme/theme_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/theme_mode_label.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/image_viewer_page.dart';
import 'package:fisioterapia_pelvica/features/profile/l10n/profile_strings.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/profile_state.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/widgets/profile_avatar_section.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/widgets/profile_photo_picker_sheet.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/widgets/profile_row.dart';
import 'package:fisioterapia_pelvica/shared/l10n/app_strings.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _viewPhoto(BuildContext context, String photoUrl) {
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    Navigator.of(context).push(
      appRoute<void>(
        ImageViewerPage(url: photoUrl, title: t.profilePhotoTitle),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final picked = await pickProfilePhoto(context);
    if (picked == null || !context.mounted) return;
    final result = await cubit.uploadPhoto(
      bytes: picked.bytes,
      contentType: picked.contentType,
    );
    if (!context.mounted) return;
    if (result case Error(:final failure)) {
      await AppInfoBottomSheet.showError(context, description: failure.message);
    }
  }

  Future<void> _removePhoto(BuildContext context) async {
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    final confirmed = await AppConfirmSheet.show(
      context,
      title: t.removePhotoTitle,
      description: t.removePhotoDescription,
      confirmLabel: t.removePhotoTitle,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await context.read<ProfileCubit>().removePhoto();
    if (!context.mounted) return;
    if (result case Error(:final failure)) {
      await AppInfoBottomSheet.showError(context, description: failure.message);
    }
  }

  Future<void> _editNome(BuildContext context, String? currentNome) async {
    if (currentNome == null) return;
    final cubit = context.read<ProfileCubit>();
    final updated = await context.push<String>(
      '/perfil/editar-nome',
      extra: currentNome,
    );
    if (updated == null || !context.mounted) return;
    cubit.applyNome(updated);
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    await AppInfoBottomSheet.showSuccess(
      context,
      description: t.nameUpdatedSuccessMessage,
    );
  }

  Future<void> _openBiometria(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    await context.push('/perfil/biometria');
    await cubit.refreshBiometria();
  }

  Future<void> _signOut(BuildContext context) async {
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    final confirmed = await AppConfirmSheet.show(
      context,
      title: t.signOutTitle,
      description: t.signOutConfirmDescription,
      confirmLabel: t.signOutTitle,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    showAppLoading();
    await sl<AuthRepository>().signOut();
    hideAppLoading();
    if (context.mounted) context.go('/');
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    final confirmed = await AppConfirmSheet.show(
      context,
      title: t.deleteAccountLabel,
      description: t.deleteAccountConfirmDescription,
      confirmLabel: t.deleteAccountConfirmLabel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    showAppLoading();
    final result = await sl<AuthRepository>().deleteAccount();
    hideAppLoading();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        context.go('/');
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings.profile;
    return BlocProvider.value(
      value: sl<ProfileCubit>(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.colors.background,
            body: Column(
              children: [
                ModernAppBar(
                  title: t.profilePageTitle,
                  subtitle: t.profilePageSubtitle,
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
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 2),
                          children: [
                            ProfileAvatarSection(
                              photoUrl: state.photoUrl,
                              initial: (state.profile?.name.isNotEmpty ?? false)
                                  ? state.profile!.name[0].toUpperCase()
                                  : '?',
                              isSaving: state.savingPhoto,
                              onTap: () => _pickPhoto(context),
                              onViewPhoto: state.photoUrl == null
                                  ? null
                                  : () => _viewPhoto(context, state.photoUrl!),
                              onRemove: state.photoUrl == null
                                  ? null
                                  : () => _removePhoto(context),
                            ),
                            const SizedBox(height: 32),
                            ProfileRow(
                              icon: Icons.person_outline,
                              label: t.nameRowLabel,
                              value: state.profile?.name ?? '',
                              trailing: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: context.colors.primary,
                              ),
                              onTap: () =>
                                  _editNome(context, state.profile?.name),
                            ),
                            const SizedBox(height: 8),
                            ProfileRow(
                              icon: Icons.email_outlined,
                              label: t.emailRowLabel,
                              value: state.profile?.email ?? '',
                            ),
                            const SizedBox(height: 8),
                            ProfileRow(
                              icon: Icons.verified_user_outlined,
                              label: t.crefitoRowLabel,
                              value: state.profile?.crefito ?? '',
                            ),
                            if (!kIsWeb) ...[
                              const SizedBox(height: 8),
                              ProfileRow(
                                icon: Icons.fingerprint,
                                label: t.biometricsRowLabel,
                                value: state.biometriaEnabled
                                    ? t.statusEnabled
                                    : t.statusDisabled,
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: context.colors.textSecondary,
                                ),
                                onTap: () => _openBiometria(context),
                              ),
                            ],
                            const SizedBox(height: 8),
                            ProfileRow(
                              icon: Icons.password_outlined,
                              label: t.changePasswordRowLabel,
                              value: '••••••••',
                              trailing: Icon(
                                Icons.chevron_right,
                                color: context.colors.textSecondary,
                              ),
                              onTap: () =>
                                  context.push('/perfil/alterar-senha'),
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<ThemeCubit, ThemeMode>(
                              builder: (context, mode) => ProfileRow(
                                icon: Icons.palette_outlined,
                                label: t.themeRowLabel,
                                value: themeModeLabel(mode, t.language),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: context.colors.textSecondary,
                                ),
                                onTap: () => context.push('/perfil/tema'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<LocaleCubit, AppLanguage>(
                              builder: (context, language) => ProfileRow(
                                icon: Icons.translate,
                                label: context.strings.profile.languageRowLabel,
                                value: language.label,
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: context.colors.textSecondary,
                                ),
                                onTap: () => context.push('/perfil/idioma'),
                              ),
                            ),
                          ],
                        ),
                ),
                if (!state.loading)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.colors.border),
                      ),
                    ),
                    child: AppBottomActionBar(
                      child: Column(
                        children: [
                          OutlinedButton(
                            onPressed: () => _signOut(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.colors.error,
                              side: BorderSide(color: context.colors.error),
                            ),
                            child: Text(t.signOutButtonLabel),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _deleteAccount(context),
                            style: TextButton.styleFrom(
                              foregroundColor: context.colors.error,
                            ),
                            child: Text(t.deleteAccountLabel),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
