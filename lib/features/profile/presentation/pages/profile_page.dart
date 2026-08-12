import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/theme/theme_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/theme_mode_label.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/core/utils/biometric_preference.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/entities/profile.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/repositories/profile_repository.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/widgets/profile_avatar_section.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/widgets/profile_photo_picker_sheet.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/widgets/profile_row.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repository = sl<ProfileRepository>();

  Profile? _profile;
  String? _photoUrl;
  bool _biometriaEnabled = false;
  bool _loading = true;
  bool _savingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final biometria = BiometricPreference.isEnabled();
    final profileResult = await _repository.getCurrent();
    final biometriaEnabled = await biometria;
    if (!mounted) return;
    switch (profileResult) {
      case Success(:final data):
        setState(() {
          _profile = data;
          _biometriaEnabled = biometriaEnabled;
          _loading = false;
        });
        if (data.fotoPath != null) {
          final urlResult = await _repository.getPhotoUrl(data.fotoPath!);
          if (mounted && urlResult is Success<String>) {
            setState(() => _photoUrl = urlResult.data);
          }
        }
      case Error(:final failure):
        setState(() => _loading = false);
        if (mounted) {
          await AppInfoBottomSheet.showError(
            context,
            description: failure.message,
          );
        }
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await pickProfilePhoto(context);
    if (picked == null || !mounted) return;
    setState(() => _savingPhoto = true);
    final result = await _repository.uploadPhoto(
      bytes: picked.bytes,
      contentType: picked.contentType,
    );
    if (!mounted) return;
    setState(() => _savingPhoto = false);
    switch (result) {
      case Success(:final data):
        final urlResult = await _repository.getPhotoUrl(data);
        if (mounted && urlResult is Success<String>) {
          setState(() => _photoUrl = urlResult.data);
        }
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  Future<void> _editNome() async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await context.push<String>(
      '/perfil/editar-nome',
      extra: profile.nome,
    );
    if (updated != null && mounted) {
      setState(() {
        _profile = profile.copyWith(nome: updated);
      });
    }
  }

  Future<void> _openBiometria() async {
    await context.push('/perfil/biometria');
    final enabled = await BiometricPreference.isEnabled();
    if (mounted) setState(() => _biometriaEnabled = enabled);
  }

  Future<void> _signOut() async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Sair',
      description: 'Deseja sair da sua conta?',
      confirmLabel: 'Sair',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    showAppLoading();
    await sl<AuthRepository>().signOut();
    hideAppLoading();
    if (mounted) context.go('/');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Excluir minha conta',
      description:
          'Tem certeza que deseja excluir sua conta? Isso apaga permanentemente '
          'todos os pacientes, evoluções, lançamentos, agendamentos e anexos. '
          'Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir conta',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    showAppLoading();
    final result = await sl<AuthRepository>().deleteAccount();
    hideAppLoading();
    if (!mounted) return;
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
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          const ModernAppBar(
            title: 'Perfil',
            subtitle: 'Gerencie seu perfil',
            showBackButton: true,
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.colors.primary,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      ProfileAvatarSection(
                        photoUrl: _photoUrl,
                        initial: (_profile?.nome.isNotEmpty ?? false)
                            ? _profile!.nome[0].toUpperCase()
                            : '?',
                        isSaving: _savingPhoto,
                        onTap: _pickPhoto,
                      ),
                      const SizedBox(height: 32),
                      ProfileRow(
                        icon: Icons.person_outline,
                        label: 'Nome',
                        value: _profile?.nome ?? '',
                        trailing: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: context.colors.primary,
                        ),
                        onTap: _editNome,
                      ),
                      const SizedBox(height: 8),
                      ProfileRow(
                        icon: Icons.email_outlined,
                        label: 'E-mail',
                        value: _profile?.email ?? '',
                      ),
                      const SizedBox(height: 8),
                      ProfileRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Crefito',
                        value: _profile?.crefito ?? '',
                      ),
                      const SizedBox(height: 8),
                      ProfileRow(
                        icon: Icons.fingerprint,
                        label: 'Biometria',
                        value: _biometriaEnabled ? 'Ativada' : 'Desativada',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: context.colors.textSecondary,
                        ),
                        onTap: _openBiometria,
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, mode) => ProfileRow(
                          icon: Icons.palette_outlined,
                          label: 'Tema',
                          value: themeModeLabel(mode),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: context.colors.textSecondary,
                          ),
                          onTap: () => context.push('/perfil/tema'),
                        ),
                      ),
                    ],
                  ),
          ),
          if (!_loading)
            AppBottomActionBar(
              child: Column(
                children: [
                  OutlinedButton(
                    onPressed: _signOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.error,
                      side: BorderSide(color: context.colors.error),
                    ),
                    child: const Text('Sair da conta'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _deleteAccount,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.error,
                    ),
                    child: const Text('Excluir minha conta'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
