import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
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

  String? get _crefitoError => crefitoErrorText(_crefitoController.text);

  String? get _emailError {
    final value = _emailController.text;
    if (value.isEmpty || isValidEmail(value)) return null;
    return 'Informe um e-mail válido.';
  }

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
              description: 'Conta criada com sucesso.',
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
                                'Criar conta',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cadastro de fisioterapeuta',
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              AppTextField(
                                controller: _nameController,
                                icon: Icons.person_outline,
                                hintText: 'Nome completo',
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _crefitoController,
                                icon: Icons.verified_user_outlined,
                                hintText: 'Crefito (ex: 123456-F3)',
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                errorText: _crefitoError,
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
                                ),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _emailController,
                                icon: Icons.email_outlined,
                                hintText: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                errorText: _emailError,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                hintText: 'Senha',
                                obscureText: formState.obscurePassword,
                                suffixIcon: PasswordVisibilityToggle(
                                  obscured: formState.obscurePassword,
                                  color: context.colors.textSecondary,
                                  onPressed: _formCubit.toggleObscurePassword,
                                ),
                                errorText: _passwordError,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _confirmPasswordController,
                                icon: Icons.lock_outline,
                                hintText: 'Confirmar senha',
                                obscureText: formState.obscureConfirmPassword,
                                suffixIcon: PasswordVisibilityToggle(
                                  obscured: formState.obscureConfirmPassword,
                                  color: context.colors.textSecondary,
                                  onPressed:
                                      _formCubit.toggleObscureConfirmPassword,
                                ),
                                errorText: _confirmPasswordError,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppBottomActionBar(
                    child: PrimaryButton(
                      label: 'Cadastrar',
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
