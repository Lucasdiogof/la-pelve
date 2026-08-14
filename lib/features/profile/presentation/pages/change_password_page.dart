import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/features/auth/l10n/auth_strings.dart';
import 'package:fisioterapia_pelvica/features/profile/l10n/profile_strings.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/change_password_cubit.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/change_password_state.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/password_visibility_toggle.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formCubit = ChangePasswordCubit();

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_formCubit.notifyFieldChanged);
    _newPasswordController.addListener(_formCubit.notifyFieldChanged);
    _confirmPasswordController.addListener(_formCubit.notifyFieldChanged);
  }

  @override
  void dispose() {
    _currentPasswordController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _newPasswordController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _formCubit.close();
    super.dispose();
  }

  String? _newPasswordError(AuthStrings t) {
    final value = _newPasswordController.text;
    if (value.isEmpty || isValidPassword(value)) return null;
    return t.passwordMinLengthError;
  }

  String? _confirmPasswordError(AuthStrings t) {
    final value = _confirmPasswordController.text;
    if (value.isEmpty || value == _newPasswordController.text) return null;
    return t.passwordsDoNotMatch;
  }

  bool get _canSubmit =>
      _currentPasswordController.text.isNotEmpty &&
      isValidPassword(_newPasswordController.text) &&
      _confirmPasswordController.text == _newPasswordController.text;

  Future<void> _submit() async {
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;
    _formCubit.setSaving(true);
    final authRepository = sl<AuthRepository>();
    final verifyResult = await authRepository.signIn(
      email: email,
      password: _currentPasswordController.text,
    );
    if (verifyResult is Error) {
      if (!mounted) return;
      _formCubit.setSaving(false);
      await AppInfoBottomSheet.showError(
        context,
        description: t.currentPasswordIncorrectError,
      );
      return;
    }
    final result = await authRepository.updatePassword(
      _newPasswordController.text,
    );
    if (!mounted) return;
    _formCubit.setSaving(false);
    switch (result) {
      case Success():
        Navigator.of(context).pop();
        await AppInfoBottomSheet.showSuccess(
          context,
          description: t.passwordChangedSuccessMessage,
        );
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
    final authT = AuthStrings(context.watch<LocaleCubit>().state);
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<ChangePasswordCubit, ChangePasswordState>(
        builder: (context, formState) => Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            children: [
              ModernAppBar(
                title: t.changePasswordPageTitle,
                subtitle: t.changePasswordPageSubtitle,
                showBackButton: true,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    AppTextField(
                      controller: _currentPasswordController,
                      icon: Icons.lock_outline,
                      hintText: t.currentPasswordHint,
                      obscureText: formState.obscureCurrentPassword,
                      suffixIcon: PasswordVisibilityToggle(
                        obscured: formState.obscureCurrentPassword,
                        color: context.colors.textSecondary,
                        onPressed: _formCubit.toggleObscureCurrentPassword,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _newPasswordController,
                      icon: Icons.lock_outline,
                      hintText: t.newPasswordHint,
                      obscureText: formState.obscureNewPassword,
                      suffixIcon: PasswordVisibilityToggle(
                        obscured: formState.obscureNewPassword,
                        color: context.colors.textSecondary,
                        onPressed: _formCubit.toggleObscureNewPassword,
                      ),
                      errorText: _newPasswordError(authT),
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
                      errorText: _confirmPasswordError(authT),
                    ),
                  ],
                ),
              ),
              AppBottomActionBar(
                child: PrimaryButton(
                  label: t.saveButtonLabel,
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
