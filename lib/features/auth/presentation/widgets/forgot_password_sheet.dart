import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/features/auth/l10n/auth_strings.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/forgot_password_state.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

Future<bool?> showForgotPasswordSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ForgotPasswordSheet(),
  );
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  final _formCubit = ForgotPasswordCubit();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_formCubit.notifyFieldChanged);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_formCubit.notifyFieldChanged)
      ..dispose();
    _formCubit.close();
    super.dispose();
  }

  String? _emailError(AuthStrings t) {
    final value = _emailController.text;
    if (value.isEmpty || isValidEmail(value)) return null;
    return t.emailInvalid;
  }

  Future<void> _send() async {
    _formCubit.setSending(true);
    final result = await sl<AuthRepository>().sendPasswordResetEmail(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    _formCubit.setSending(false);
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
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
      child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
        builder: (context, formState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.border,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.forgotPasswordLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.primaryButton,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.forgotPasswordDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      hintText: t.emailHint,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError(t),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: t.sendLinkButton,
                      isLoading: formState.sending,
                      onPressed: isValidEmail(_emailController.text)
                          ? _send
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
