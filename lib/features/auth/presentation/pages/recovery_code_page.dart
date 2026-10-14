import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pelve/features/auth/l10n/auth_strings.dart';
import 'package:la_pelve/features/auth/presentation/cubit/recovery_code_cubit.dart';
import 'package:la_pelve/features/auth/presentation/cubit/recovery_code_state.dart';
import 'package:la_pelve/shared/utils/validators.dart';
import 'package:la_pelve/shared/widgets/app_bottom_action_bar.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_text_field.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

/// Passo 2 da recuperação de senha: e-mail + código de 6 dígitos.
///
/// Ao validar, a sessão de recuperação abre e o listener global de auth
/// (`main.dart`) leva o usuário para a tela de nova senha.
class RecoveryCodePage extends StatefulWidget {
  const RecoveryCodePage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<RecoveryCodePage> createState() => _RecoveryCodePageState();
}

class _RecoveryCodePageState extends State<RecoveryCodePage> {
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _codeController = TextEditingController();
  final _formCubit = RecoveryCodeCubit();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_formCubit.notifyFieldChanged);
    _codeController.addListener(_formCubit.notifyFieldChanged);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _codeController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _formCubit.close();
    super.dispose();
  }

  String get _email => _emailController.text.trim();
  String get _code => _codeController.text.trim();

  bool get _codeComplete => _code.length == 6;

  bool get _canSubmit => isValidEmail(_email) && _codeComplete;

  String? _emailError(AuthStrings t) {
    if (_email.isEmpty || isValidEmail(_email)) return null;
    return t.emailInvalid;
  }

  Future<void> _verify() async {
    _formCubit.setVerifying(true);
    final result = await sl<AuthRepository>().verifyRecoveryCode(
      email: _email,
      code: _code,
    );
    if (!mounted) return;
    _formCubit.setVerifying(false);
    switch (result) {
      case Success():
        // A navegação para a nova senha vem do evento passwordRecovery.
        break;
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  Future<void> _resend() async {
    _formCubit.setResending(true);
    final result = await sl<AuthRepository>().sendPasswordResetEmail(_email);
    if (!mounted) return;
    _formCubit.setResending(false);
    switch (result) {
      case Success():
        _formCubit.restartCooldown();
        final t = AuthStrings(context.read<LocaleCubit>().state);
        await AppInfoBottomSheet.showSuccess(
          context,
          description: t.resetLinkSentDescription,
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
    final t = AuthStrings(context.watch<LocaleCubit>().state);
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<RecoveryCodeCubit, RecoveryCodeState>(
        builder: (context, formState) {
          final cooling = formState.cooldownSeconds > 0;
          return Scaffold(
            backgroundColor: context.colors.background,
            appBar: AppBar(title: Text(t.recoveryCodePageTitle)),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        t.recoveryCodeInstructions,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        label: t.emailHint,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError(t),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _codeController,
                        icon: Icons.pin_outlined,
                        label: t.recoveryCodeHint,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed:
                              cooling ||
                                  formState.resending ||
                                  !isValidEmail(_email)
                              ? null
                              : _resend,
                          child: Text(
                            cooling
                                ? t.resendCodeIn(formState.cooldownSeconds)
                                : t.resendCodeButton,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppBottomActionBar(
                  child: PrimaryButton(
                    label: t.verifyCodeButton,
                    isLoading: formState.verifying,
                    onPressed: _canSubmit ? _verify : null,
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
