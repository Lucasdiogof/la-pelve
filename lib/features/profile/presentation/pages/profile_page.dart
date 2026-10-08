import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/router/app_page.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/core/theme/theme_cubit.dart';
import 'package:la_pelve/core/theme/theme_mode_label.dart';
import 'package:la_pelve/core/utils/app_loading.dart';
import 'package:la_pelve/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pelve/features/patients/presentation/pages/image_viewer_page.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_state.dart';
import 'package:la_pelve/features/profile/presentation/widgets/profile_avatar_section.dart';
import 'package:la_pelve/features/profile/presentation/widgets/profile_photo_picker_sheet.dart';
import 'package:la_pelve/features/profile/presentation/widgets/profile_row.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/widgets/app_confirm_sheet.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_error_state.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';

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

  Future<void> _changePhoto(
    BuildContext context, {
    required bool hasPhoto,
  }) async {
    final cubit = context.read<ProfileCubit>();
    final action = await showProfilePhotoActionSheet(
      context,
      canRemove: hasPhoto,
    );
    if (action == null || !context.mounted) return;
    if (action == ProfilePhotoAction.remove) {
      await _removePhoto(context);
      return;
    }
    final picked = await pickProfilePhotoFrom(action);
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

  Widget _header(BuildContext context, ProfileState state, ProfileStrings t) {
    final name = (state.profile?.name.trim().isNotEmpty ?? false)
        ? state.profile!.name.trim()
        : t.notInformedLabel;
    final email = state.profile?.email.trim() ?? '';
    final avatar = ProfileAvatarSection(
      photoUrl: state.photoUrl,
      initial: (state.profile?.name.isNotEmpty ?? false)
          ? state.profile!.name[0].toUpperCase()
          : '?',
      isSaving: state.savingPhoto,
      onTap: () => _changePhoto(context, hasPhoto: state.photoUrl != null),
      onViewPhoto: state.photoUrl == null
          ? null
          : () => _viewPhoto(context, state.photoUrl!),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Composição horizontal (avatar + nome/e-mail à esquerda) é o padrão;
        // só empilha em tela estreita com texto bem ampliado, pra não
        // esmagar o nome.
        final textScale = MediaQuery.textScalerOf(context).scale(100);
        final stacked = constraints.maxWidth < 300 && textScale >= 115;
        final nameText = Text(
          name,
          maxLines: 3,
          textAlign: stacked ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.titleLarge,
        );
        final emailText = email.isEmpty
            ? null
            : Text(
                email,
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              );
        if (stacked) {
          return Column(
            children: [
              avatar,
              const SizedBox(height: AppSpacing.s12),
              nameText,
              if (emailText != null) ...[const SizedBox(height: 2), emailText],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            avatar,
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  nameText,
                  if (emailText != null) ...[
                    const SizedBox(height: 2),
                    emailText,
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
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
                  child: state.profile == null && state.failure != null
                      // Falha sem perfil carregado: erro + tentar de novo,
                      // nunca os campos em branco como se fossem os dados.
                      ? AppErrorState(
                          title: context.strings.shared.loadErrorTitle,
                          message: context.strings.shared.loadErrorMessage,
                          retryLabel: context.strings.shared.retry,
                          retrying: state.loading,
                          onRetry: () => context.read<ProfileCubit>().load(),
                        )
                      : state.profile == null
                      ? Center(
                          child: CircularProgressIndicator(
                            color: context.colors.primary,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.gutter,
                            AppSpacing.s16,
                            AppSpacing.gutter,
                            AppSpacing.s32,
                          ),
                          children: [
                            _header(context, state, t),
                            const SizedBox(height: AppSpacing.s24),
                            AppSection(
                              title: t.profileSectionTitle,
                              children: [
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
                                ProfileRow(
                                  icon: Icons.email_outlined,
                                  label: t.emailRowLabel,
                                  value: state.profile?.email ?? '',
                                ),
                                ProfileRow(
                                  icon: Icons.verified_user_outlined,
                                  label: t.crefitoRowLabel,
                                  value: state.profile?.crefito ?? '',
                                  showDivider: false,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s20),
                            AppSection(
                              title: t.preferencesSectionTitle,
                              children: [
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
                                BlocBuilder<LocaleCubit, AppLanguage>(
                                  builder: (context, language) => ProfileRow(
                                    icon: Icons.translate,
                                    label: t.languageRowLabel,
                                    value: language.label,
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: context.colors.textSecondary,
                                    ),
                                    onTap: () => context.push('/perfil/idioma'),
                                    showDivider: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s20),
                            AppSection(
                              title: t.accountSectionTitle,
                              children: [
                                if (!kIsWeb)
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
                                ProfileRow(
                                  icon: Icons.password_outlined,
                                  label: t.changePasswordRowLabel,
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: context.colors.textSecondary,
                                  ),
                                  onTap: () =>
                                      context.push('/perfil/alterar-senha'),
                                ),
                                ProfileRow(
                                  icon: Icons.chat_outlined,
                                  label: t.whatsappRowLabel,
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: context.colors.textSecondary,
                                  ),
                                  onTap: () => context.push('/perfil/whatsapp'),
                                ),
                                ProfileRow(
                                  icon: Icons.logout,
                                  label: t.signOutButtonLabel,
                                  onTap: () => _signOut(context),
                                  showDivider: false,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s32),
                            Center(
                              child: TextButton(
                                onPressed: () => _deleteAccount(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: context.colors.danger,
                                ),
                                child: Text(t.deleteAccountLabel),
                              ),
                            ),
                          ],
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
