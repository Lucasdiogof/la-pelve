import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/features/auth/l10n/auth_strings.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/reset_password_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/reset_password_state.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/password_visibility_toggle.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formCubit = ResetPasswordCubit();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_formCubit.notifyFieldChanged);
    _confirmPasswordController.addListener(_formCubit.notifyFieldChanged);
  }

  @override
  void dispose() {
    _passwordController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _formCubit.close();
    super.dispose();
  }

  String? _passwordError(AuthStrings t) {
    final value = _passwordController.text;
    if (value.isEmpty || isValidPassword(value)) return null;
    return t.passwordMinLengthError;
  }

  String? _confirmPasswordError(AuthStrings t) {
    final value = _confirmPasswordController.text;
    if (value.isEmpty || value == _passwordController.text) return null;
    return t.passwordsDoNotMatch;
  }

  bool get _canSubmit =>
      isValidPassword(_passwordController.text) &&
      _confirmPasswordController.text == _passwordController.text;

  Future<void> _submit() async {
    _formCubit.setSaving(true);
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
        final t = AuthStrings(context.read<LocaleCubit>().state);
        context.go('/');
        await AppInfoBottomSheet.showSuccess(
          context,
          description: t.passwordChangedDescription,
        );
      case Error(:final failure):
        _formCubit.setSaving(false);
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AuthStrings(context.watch<LocaleCubit>().state);
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
        builder: (context, formState) => Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(title: Text(t.resetPasswordPageTitle)),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      t.resetPasswordInstructions,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      hintText: t.newPasswordHint,
                      obscureText: formState.obscurePassword,
                      suffixIcon: PasswordVisibilityToggle(
                        obscured: formState.obscurePassword,
                        color: context.colors.textSecondary,
                        onPressed: _formCubit.toggleObscurePassword,
                      ),
                      errorText: _passwordError(t),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _confirmPasswordController,
                      icon: Icons.lock_outline,
                      hintText: t.confirmNewPasswordHint,
                      obscureText: formState.obscureConfirmPassword,
                      suffixIcon: PasswordVisibilityToggle(
                        obscured: formState.obscureConfirmPassword,
                        color: context.colors.textSecondary,
                        onPressed: _formCubit.toggleObscureConfirmPassword,
                      ),
                      errorText: _confirmPasswordError(t),
                    ),
                  ],
                ),
              ),
              AppBottomActionBar(
                child: PrimaryButton(
                  label: t.saveNewPasswordButton,
                  isLoading: formState.saving,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
