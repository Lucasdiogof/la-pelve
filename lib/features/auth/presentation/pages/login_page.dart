import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_state.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/login_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/login_form_state.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/widgets/forgot_password_sheet.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/widgets/login_card.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/pulsing_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formCubit = LoginFormCubit();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_formCubit.notifyFieldChanged);
    _passwordController.addListener(_formCubit.notifyFieldChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_formCubit.notifyFieldChanged);
    _passwordController.removeListener(_formCubit.notifyFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _formCubit.close();
    super.dispose();
  }

  String? _emailError(bool submitted) {
    final value = _emailController.text;
    if (value.isEmpty) {
      return submitted ? 'Informe seu e-mail.' : null;
    }
    if (isValidEmail(value)) return null;
    return 'Informe um e-mail válido.';
  }

  String? _passwordError(bool submitted) {
    final value = _passwordController.text;
    if (value.isEmpty) {
      return submitted ? 'Informe sua senha.' : null;
    }
    if (isValidPassword(value)) return null;
    return 'A senha precisa ter pelo menos $kMinPasswordLength caracteres.';
  }

  bool get _canSubmit =>
      isValidEmail(_emailController.text) &&
      isValidPassword(_passwordController.text);

  void _submit() {
    _formCubit.markSubmitted();
    if (!_canSubmit) return;
    context.read<AuthCubit>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _forgotPassword() async {
    final sent = await showForgotPasswordSheet(context);
    if (sent == true && mounted) {
      await AppInfoBottomSheet.showSuccess(
        context,
        description: 'Enviamos um link de redefinição para o seu e-mail.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          switch (state) {
            case AuthSuccess():
              context.go('/home');
            case AuthError(:final message, :final isInvalidCredentials):
              if (isInvalidCredentials) {
                AppInfoBottomSheet.showError(
                  context,
                  title: 'Não encontramos essa conta',
                  description:
                      'Confira o e-mail e a senha, ou crie uma conta caso ainda não tenha uma.',
                  secondaryActionLabel: 'Criar conta',
                  onSecondaryAction: () => context.push('/cadastro'),
                );
              } else {
                AppInfoBottomSheet.showError(context, description: message);
              }
            case AuthLoading():
            case AuthInitial():
              break;
          }
        },
        builder: (context, authState) {
          final isSigningIn = authState is AuthLoading;
          return BlocBuilder<LoginFormCubit, LoginFormState>(
            builder: (context, formState) {
              return Scaffold(
                backgroundColor: context.colors.background,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                Theme.of(context).brightness == Brightness.dark
                                    ? 'lib/assets/dark_background.png'
                                    : 'lib/assets/background.png',
                                fit: BoxFit.cover,
                              ),
                              Align(
                                alignment: const Alignment(0, -0.3),
                                child: Image.asset(
                                  'lib/assets/app_icon.png',
                                  width: 160,
                                  height: 160,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LoginCard(
                          emailController: _emailController,
                          emailError: _emailError(formState.submitted),
                          passwordController: _passwordController,
                          passwordError: _passwordError(formState.submitted),
                          obscurePassword: formState.obscurePassword,
                          onToggleObscure: _formCubit.toggleObscurePassword,
                          onSubmit: _submit,
                          onForgotPassword: _forgotPassword,
                          onCreateAccount: () => context.push('/cadastro'),
                        ),
                      ],
                    ),
                    if (isSigningIn)
                      Container(
                        color: context.colors.background,
                        child: const Center(child: PulsingLogo(size: 100)),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
