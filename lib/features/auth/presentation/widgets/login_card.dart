import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/auth/l10n/auth_strings.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/password_visibility_toggle.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({
    required this.emailController,
    required this.emailError,
    required this.passwordController,
    required this.passwordError,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onCreateAccount,
    super.key,
  });

  final TextEditingController emailController;
  final String? emailError;
  final TextEditingController passwordController;
  final String? passwordError;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final t = AuthStrings(context.watch<LocaleCubit>().state);
    return Material(
      color: context.colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t.tagline,
                      maxLines: 1,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primaryButton,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    t.clinicRoutineSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: emailController,
                  icon: Icons.email_outlined,
                  hintText: t.loginEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  errorText: emailError,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: passwordController,
                  icon: Icons.lock_outline,
                  hintText: t.passwordHint,
                  obscureText: obscurePassword,
                  suffixIcon: PasswordVisibilityToggle(
                    obscured: obscurePassword,
                    color: context.colors.primary,
                    onPressed: onToggleObscure,
                  ),
                  errorText: passwordError,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgotPassword,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        t.forgotPasswordLabel,
                        style: TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: context.colors.primaryButton,
                          color: context.colors.primaryButton,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: t.signInButton, onPressed: onSubmit),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: context.colors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        t.orDivider,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: context.colors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onCreateAccount,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: context.colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: context.colors.primaryButton,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.createAccount,
                        style: TextStyle(
                          color: context.colors.primaryButton,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
