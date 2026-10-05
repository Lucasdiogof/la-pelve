import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/shared/utils/validators.dart';

class AuthStrings {
  const AuthStrings(this.language);

  final AppLanguage language;

  String get emailRequired => switch (language) {
    AppLanguage.portuguese => 'Informe seu e-mail.',
    AppLanguage.english => 'Enter your email.',
    AppLanguage.spanish => 'Ingresa tu correo electrónico.',
  };

  String get emailInvalid => switch (language) {
    AppLanguage.portuguese => 'Informe um e-mail válido.',
    AppLanguage.english => 'Enter a valid email.',
    AppLanguage.spanish => 'Ingresa un correo electrónico válido.',
  };

  String get passwordRequired => switch (language) {
    AppLanguage.portuguese => 'Informe sua senha.',
    AppLanguage.english => 'Enter your password.',
    AppLanguage.spanish => 'Ingresa tu contraseña.',
  };

  String get passwordMinLengthError => switch (language) {
    AppLanguage.portuguese =>
      'A senha precisa ter pelo menos $kMinPasswordLength caracteres.',
    AppLanguage.english =>
      'Password must be at least $kMinPasswordLength characters.',
    AppLanguage.spanish =>
      'La contraseña debe tener al menos $kMinPasswordLength caracteres.',
  };

  String get passwordsDoNotMatch => switch (language) {
    AppLanguage.portuguese => 'As senhas não coincidem.',
    AppLanguage.english => 'Passwords do not match.',
    AppLanguage.spanish => 'Las contraseñas no coinciden.',
  };

  String get resetLinkSentDescription => switch (language) {
    AppLanguage.portuguese =>
      'Enviamos um link de redefinição para o seu e-mail.',
    AppLanguage.english => 'We sent a password reset link to your email.',
    AppLanguage.spanish =>
      'Enviamos un enlace de restablecimiento a tu correo electrónico.',
  };

  String get accountNotFoundTitle => switch (language) {
    AppLanguage.portuguese => 'Não encontramos essa conta',
    AppLanguage.english => "We couldn't find that account",
    AppLanguage.spanish => 'No encontramos esa cuenta',
  };

  String get accountNotFoundDescription => switch (language) {
    AppLanguage.portuguese =>
      'Confira o e-mail e a senha, ou crie uma conta caso ainda não tenha uma.',
    AppLanguage.english =>
      "Check your email and password, or create an account if you don't have one yet.",
    AppLanguage.spanish =>
      'Revisa tu correo y contraseña, o crea una cuenta si aún no tienes una.',
  };

  String get createAccount => switch (language) {
    AppLanguage.portuguese => 'Criar conta',
    AppLanguage.english => 'Create account',
    AppLanguage.spanish => 'Crear cuenta',
  };

  String get physiotherapistSignUp => switch (language) {
    AppLanguage.portuguese => 'Cadastro de fisioterapeuta',
    AppLanguage.english => 'Physiotherapist sign-up',
    AppLanguage.spanish => 'Registro de fisioterapeuta',
  };

  String get fullNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome completo',
    AppLanguage.english => 'Full name',
    AppLanguage.spanish => 'Nombre completo',
  };

  String get crefitoHint => switch (language) {
    AppLanguage.portuguese => 'Crefito (apenas números)',
    AppLanguage.english => 'Crefito (numbers only)',
    AppLanguage.spanish => 'Crefito (solo números)',
  };

  String get emailHint => switch (language) {
    AppLanguage.portuguese => 'Email',
    AppLanguage.english => 'Email',
    AppLanguage.spanish => 'Correo electrónico',
  };

  String get loginEmailHint => switch (language) {
    AppLanguage.portuguese => 'E-mail',
    AppLanguage.english => 'Email',
    AppLanguage.spanish => 'Correo electrónico',
  };

  String get passwordHint => switch (language) {
    AppLanguage.portuguese => 'Senha',
    AppLanguage.english => 'Password',
    AppLanguage.spanish => 'Contraseña',
  };

  String get confirmPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Confirmar senha',
    AppLanguage.english => 'Confirm password',
    AppLanguage.spanish => 'Confirmar contraseña',
  };

  String get registerSubmitButton => switch (language) {
    AppLanguage.portuguese => 'Cadastrar',
    AppLanguage.english => 'Sign up',
    AppLanguage.spanish => 'Registrarse',
  };

  String get accountCreatedDescription => switch (language) {
    AppLanguage.portuguese => 'Conta criada com sucesso.',
    AppLanguage.english => 'Account created successfully.',
    AppLanguage.spanish => 'Cuenta creada con éxito.',
  };

  String get resetPasswordPageTitle => switch (language) {
    AppLanguage.portuguese => 'Nova senha',
    AppLanguage.english => 'New password',
    AppLanguage.spanish => 'Nueva contraseña',
  };

  String get newPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Nova senha',
    AppLanguage.english => 'New password',
    AppLanguage.spanish => 'Nueva contraseña',
  };

  String get resetPasswordInstructions => switch (language) {
    AppLanguage.portuguese => 'Defina uma nova senha para sua conta.',
    AppLanguage.english => 'Set a new password for your account.',
    AppLanguage.spanish => 'Define una nueva contraseña para tu cuenta.',
  };

  String get confirmNewPasswordHint => switch (language) {
    AppLanguage.portuguese => 'Confirmar nova senha',
    AppLanguage.english => 'Confirm new password',
    AppLanguage.spanish => 'Confirmar nueva contraseña',
  };

  String get saveNewPasswordButton => switch (language) {
    AppLanguage.portuguese => 'Salvar nova senha',
    AppLanguage.english => 'Save new password',
    AppLanguage.spanish => 'Guardar nueva contraseña',
  };

  String get passwordChangedDescription => switch (language) {
    AppLanguage.portuguese => 'Senha alterada. Faça login com a nova senha.',
    AppLanguage.english => 'Password changed. Sign in with your new password.',
    AppLanguage.spanish =>
      'Contraseña cambiada. Inicia sesión con tu nueva contraseña.',
  };

  String get forgotPasswordLabel => switch (language) {
    AppLanguage.portuguese => 'Esqueci minha senha',
    AppLanguage.english => 'Forgot my password',
    AppLanguage.spanish => 'Olvidé mi contraseña',
  };

  String get forgotPasswordDescription => switch (language) {
    AppLanguage.portuguese =>
      'Informe seu e-mail para receber um link de redefinição de senha.',
    AppLanguage.english => 'Enter your email to receive a password reset link.',
    AppLanguage.spanish =>
      'Ingresa tu correo para recibir un enlace de restablecimiento de contraseña.',
  };

  String get sendLinkButton => switch (language) {
    AppLanguage.portuguese => 'Enviar link',
    AppLanguage.english => 'Send link',
    AppLanguage.spanish => 'Enviar enlace',
  };

  String get tagline => switch (language) {
    AppLanguage.portuguese => 'Feito para sua rotina clínica',
    AppLanguage.english => 'Built for your clinical routine',
    AppLanguage.spanish => 'Hecho para tu rutina clínica',
  };

  String get clinicRoutineSubtitle => switch (language) {
    AppLanguage.portuguese =>
      'Organize pacientes, agenda, evoluções e financeiro com facilidade.',
    AppLanguage.english =>
      'Easily manage patients, agenda, progress notes and finances.',
    AppLanguage.spanish =>
      'Organiza pacientes, agenda, evoluciones y finanzas con facilidad.',
  };

  String get signInButton => switch (language) {
    AppLanguage.portuguese => 'Entrar',
    AppLanguage.english => 'Sign in',
    AppLanguage.spanish => 'Iniciar sesión',
  };

  String get orDivider => switch (language) {
    AppLanguage.portuguese => 'ou',
    AppLanguage.english => 'or',
    AppLanguage.spanish => 'o',
  };
}
