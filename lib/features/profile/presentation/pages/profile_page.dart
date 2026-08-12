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
import 'package:fisioterapia_pelvica/features/profile/presentation/widgets/profile_photo_picker_sheet.dart';
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
          Expanded(child: _buildBody(context)),
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

  Widget _buildBody(BuildContext context) {
    return _loading
        ? Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          )
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: context.colors.primary.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : null,
                      child: _photoUrl == null
                          ? Text(
                              (_profile?.nome.isNotEmpty ?? false)
                                  ? _profile!.nome[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: context.colors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _savingPhoto ? null : _pickPhoto,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _savingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _ProfileRow(
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
              _ProfileRow(
                icon: Icons.email_outlined,
                label: 'E-mail',
                value: _profile?.email ?? '',
              ),
              const SizedBox(height: 8),
              _ProfileRow(
                icon: Icons.verified_user_outlined,
                label: 'Crefito',
                value: _profile?.crefito ?? '',
              ),
              const SizedBox(height: 8),
              _ProfileRow(
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
                builder: (context, mode) => _ProfileRow(
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
          );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.colors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      value.isEmpty ? 'Não informado' : value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
