import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onChanged);
    _confirmPasswordController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _passwordController
      ..removeListener(_onChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String? get _passwordError {
    final value = _passwordController.text;
    if (value.isEmpty || isValidPassword(value)) return null;
    return 'A senha precisa ter pelo menos $kMinPasswordLength caracteres.';
  }

  String? get _confirmPasswordError {
    final value = _confirmPasswordController.text;
    if (value.isEmpty || value == _passwordController.text) return null;
    return 'As senhas não coincidem.';
  }

  bool get _canSubmit =>
      isValidPassword(_passwordController.text) &&
      _confirmPasswordController.text == _passwordController.text;

  Future<void> _submit() async {
    setState(() => _saving = true);
    final result = await sl<AuthRepository>().updatePassword(
      _passwordController.text,
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        showAppLoading();
        await sl<AuthRepository>().signOut();
        hideAppLoading();
        if (!mounted) return;
        context.go('/');
        await AppInfoBottomSheet.showSuccess(
          context,
          description: 'Senha alterada. Faça login com a nova senha.',
        );
      case Error(:final failure):
        setState(() => _saving = false);
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
      appBar: AppBar(title: const Text('Nova senha')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Defina uma nova senha para sua conta.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  hintText: 'Nova senha',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.colors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  errorText: _passwordError,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  hintText: 'Confirmar nova senha',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.colors.textSecondary,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  errorText: _confirmPasswordError,
                ),
              ],
            ),
          ),
          AppBottomActionBar(
            child: PrimaryButton(
              label: 'Salvar nova senha',
              isLoading: _saving,
              onPressed: _canSubmit ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}
