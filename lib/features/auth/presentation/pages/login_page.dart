import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_state.dart';
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
  bool _obscurePassword = true;
  bool _submitted = false;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  String? get _emailError {
    final value = _emailController.text;
    if (value.isEmpty) {
      return _submitted ? 'Informe seu e-mail.' : null;
    }
    if (isValidEmail(value)) return null;
    return 'Informe um e-mail válido.';
  }

  String? get _passwordError {
    final value = _passwordController.text;
    if (value.isEmpty) {
      return _submitted ? 'Informe sua senha.' : null;
    }
    if (isValidPassword(value)) return null;
    return 'A senha precisa ter pelo menos $kMinPasswordLength caracteres.';
  }

  bool get _canSubmit =>
      isValidEmail(_emailController.text) &&
      isValidPassword(_passwordController.text);

  void _submit() {
    setState(() => _submitted = true);
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
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthLoading():
            setState(() => _isSigningIn = true);
          case AuthSuccess():
            context.go('/home');
          case AuthError(:final message, :final isInvalidCredentials):
            setState(() => _isSigningIn = false);
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
          case AuthInitial():
            break;
        }
      },
      child: Scaffold(
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
                  emailError: _emailError,
                  passwordController: _passwordController,
                  passwordError: _passwordError,
                  obscurePassword: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmit: _submit,
                  onForgotPassword: _forgotPassword,
                  onCreateAccount: () => context.push('/cadastro'),
                ),
              ],
            ),
            if (_isSigningIn)
              Container(
                color: context.colors.background,
                child: const Center(child: PulsingLogo(size: 140)),
              ),
          ],
        ),
      ),
    );
  }
}
