import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';

class AuthStrings {
  const AuthStrings(this.language);

  final AppLanguage language;

  String get emailRequired => switch (language) {
    AppLanguage.portuguese => 'Informe seu e-mail.',
    AppLanguage.english => 'Enter your email.',
  };

  String get emailInvalid => switch (language) {
    AppLanguage.portuguese => 'Informe um e-mail válido.',
    AppLanguage.english => 'Enter a valid email.',
  };

  String get passwordRequired => switch (language) {
    AppLanguage.portuguese => 'Informe sua senha.',
    AppLanguage.english => 'Enter your password.',
  };

  String get passwordMinLengthError => switch (language) {
    AppLanguage.portuguese =>
      'A senha precisa ter pelo menos $kMinPasswordLength caracteres.',
    AppLanguage.english =>
      'Password must be at least $kMinPasswordLength characters.',
  };

  String get passwordsDoNotMatch => switch (language) {
    AppLanguage.portuguese => 'As senhas não coincidem.',
    AppLanguage.english => 'Passwords do not match.',
  };

  String get resetLinkSentDescription => switch (language) {
    AppLanguage.portuguese =>
      'Enviamos um link de redefinição para o seu e-mail.',
    AppLanguage.english => 'We sent a password reset link to your email.',
  };

  String get accountNotFoundTitle => switch (language) {
    AppLanguage.portuguese => 'Não encontramos essa conta',
    AppLanguage.english => "We couldn't find that account",
  };

  String get accountNotFoundDescription => switch (language) {
    AppLanguage.portuguese =>
      'Confira o e-mail e a senha, ou crie uma conta caso ainda não tenha uma.',
    AppLanguage.english =>
      "Check your email and password, or create an account if you don't have one yet.",
  };

  String get createAccount => switch (language) {
    AppLanguage.portuguese => 'Criar conta',
    AppLanguage.english => 'Create account',
  };

  String get physiotherapistSignUp => switch (language) {
    AppLanguage.portuguese => 'Cadastro de fisioterapeuta',
    AppLanguage.english => 'Physiotherapist sign-up',
  };

  String get fullNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome completo',
    AppLanguage.english => 'Full name',
  };

  String get crefitoHint => switch (language) {
    AppLanguage.portuguese => 'Crefito (ex: 123456-F3)',
    AppLanguage.english => 'Crefito (e.g. 123456-F3)',
  };

  String get emailHint => switch (language) {
    AppLanguage.portuguese => 'Email',
    AppLanguage.english => 'Email',
  };

  String get loginEmailHint => switch (language) {
    AppLanguage.portuguese => 'E-mail',
    AppLanguage.english => 'Email',
  };

  String get passwordHint => switch (language) {
    AppLanguage.portuguese => 'Senha',
    AppLanguage.english => 'Password',
  };

  String get confirmPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Confirmar senha',
    AppLanguage.english => 'Confirm password',
  };

  String get registerSubmitButton => switch (language) {
    AppLanguage.portuguese => 'Cadastrar',
    AppLanguage.english => 'Sign up',
  };

  String get accountCreatedDescription => switch (language) {
    AppLanguage.portuguese => 'Conta criada com sucesso.',
    AppLanguage.english => 'Account created successfully.',
  };

  String get resetPasswordPageTitle => switch (language) {
    AppLanguage.portuguese => 'Nova senha',
    AppLanguage.english => 'New password',
  };

  String get newPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Nova senha',
    AppLanguage.english => 'New password',
  };

  String get resetPasswordInstructions => switch (language) {
    AppLanguage.portuguese => 'Defina uma nova senha para sua conta.',
    AppLanguage.english => 'Set a new password for your account.',
  };

  String get confirmNewPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Confirmar nova senha',
    AppLanguage.english => 'Confirm new password',
  };

  String get saveNewPasswordButton => switch (language) {
    AppLanguage.portuguese => 'Salvar nova senha',
    AppLanguage.english => 'Save new password',
  };

  String get passwordChangedDescription => switch (language) {
    AppLanguage.portuguese => 'Senha alterada. Faça login com a nova senha.',
    AppLanguage.english => 'Password changed. Sign in with your new password.',
  };

  String get forgotPasswordLabel => switch (language) {
    AppLanguage.portuguese => 'Esqueci minha senha',
    AppLanguage.english => 'Forgot my password',
  };

  String get forgotPasswordDescription => switch (language) {
    AppLanguage.portuguese =>
      'Informe seu e-mail para receber um link de redefinição de senha.',
    AppLanguage.english => 'Enter your email to receive a password reset link.',
  };

  String get sendLinkButton => switch (language) {
    AppLanguage.portuguese => 'Enviar link',
    AppLanguage.english => 'Send link',
  };

  String get tagline => switch (language) {
    AppLanguage.portuguese => 'Feito para sua rotina clínica',
    AppLanguage.english => 'Built for your clinical routine',
  };

  String get clinicRoutineSubtitle => switch (language) {
    AppLanguage.portuguese =>
      'Organize pacientes, agenda, evoluções e financeiro com facilidade.',
    AppLanguage.english =>
      'Easily manage patients, agenda, progress notes and finances.',
  };

  String get signInButton => switch (language) {
    AppLanguage.portuguese => 'Entrar',
    AppLanguage.english => 'Sign in',
  };

  String get orDivider => switch (language) {
    AppLanguage.portuguese => 'ou',
    AppLanguage.english => 'or',
  };
}
