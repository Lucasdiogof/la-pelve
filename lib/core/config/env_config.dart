/// Reads secrets injected at build/run time via
/// `--dart-define-from-file=env.json` (see env.example.json).
///
/// Keeping these as compile-time `String.fromEnvironment` values means the
/// real keys never live in source control — only `env.json`, which is
/// gitignored.
class EnvConfig {
  const EnvConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError(
        'SUPABASE_URL ausente. Rode com --dart-define-from-file=env.json '
        '(copie env.example.json para env.json e preencha as chaves).',
      );
    }
    if (supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY ausente. Rode com --dart-define-from-file=env.json '
        '(copie env.example.json para env.json e preencha as chaves).',
      );
    }
  }
}
