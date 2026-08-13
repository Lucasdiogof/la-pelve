import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/auth/l10n/auth_strings.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_state.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/register_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/register_form_state.dart';
import 'package:fisioterapia_pelvica/shared/utils/phone_input_formatter.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/password_visibility_toggle.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _crefitoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formCubit = RegisterFormCubit();

  static const double _maxContentWidth = 480;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _crefitoController,
      _phoneController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_formCubit.notifyFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _crefitoController,
      _phoneController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller
        ..removeListener(_formCubit.notifyFieldChanged)
        ..dispose();
    }
    _formCubit.close();
    super.dispose();
  }

  String? _crefitoError(AuthStrings t) =>
      crefitoErrorText(_crefitoController.text, language: t.language);

  String? _emailError(AuthStrings t) {
    final value = _emailController.text;
    if (value.isEmpty || isValidEmail(value)) return null;
    return t.emailInvalid;
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
      _nameController.text.trim().isNotEmpty &&
      isValidCrefito(_crefitoController.text) &&
      isValidPhone(_phoneController.text) &&
      isValidEmail(_emailController.text) &&
      isValidPassword(_passwordController.text) &&
      _confirmPasswordController.text == _passwordController.text;

  void _submit() {
    context.read<AuthCubit>().signUp(
      nome: _nameController.text.trim(),
      crefito: _crefitoController.text.trim(),
      telefone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AuthStrings(context.watch<LocaleCubit>().state);
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthLoading():
            showAppLoading();
          case AuthSuccess():
            hideAppLoading();
            context.go('/home');
            AppInfoBottomSheet.showSuccess(
              context,
              description: t.accountCreatedDescription,
            );
          case AuthError(:final message):
            hideAppLoading();
            AppInfoBottomSheet.showError(context, description: message);
          case AuthInitial():
            break;
        }
      },
      child: BlocProvider.value(
        value: _formCubit,
        child: BlocBuilder<RegisterFormCubit, RegisterFormState>(
          builder: (context, formState) => Scaffold(
            backgroundColor: context.colors.background,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxContentWidth,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                t.createAccount,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.physiotherapistSignUp,
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              AppTextField(
                                controller: _nameController,
                                icon: Icons.person_outline,
                                hintText: t.fullNameHint,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _crefitoController,
                                icon: Icons.verified_user_outlined,
                                hintText: t.crefitoHint,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                errorText: _crefitoError(t),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _phoneController,
                                icon: Icons.phone_outlined,
                                hintText: '(XX) X XXXX-XXXX',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [PhoneInputFormatter()],
                                errorText: phoneErrorText(
                                  _phoneController.text,
                                  language: t.language,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _emailController,
                                icon: Icons.email_outlined,
                                hintText: t.emailHint,
                                keyboardType: TextInputType.emailAddress,
                                errorText: _emailError(t),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                hintText: t.passwordHint,
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
                                hintText: t.confirmPasswordHint,
                                obscureText: formState.obscureConfirmPassword,
                                suffixIcon: PasswordVisibilityToggle(
                                  obscured: formState.obscureConfirmPassword,
                                  color: context.colors.textSecondary,
                                  onPressed:
                                      _formCubit.toggleObscureConfirmPassword,
                                ),
                                errorText: _confirmPasswordError(t),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppBottomActionBar(
                    child: PrimaryButton(
                      label: t.registerSubmitButton,
                      onPressed: _canSubmit ? _submit : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
