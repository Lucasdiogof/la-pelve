import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/app.dart';
import 'package:fisioterapia_pelvica/core/config/env_config.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/network/logging_http_client.dart';
import 'package:fisioterapia_pelvica/core/router/app_router.dart';
import 'package:fisioterapia_pelvica/core/theme/theme_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  EnvConfig.validate();

  sl.registerLazySingleton<ThemeCubit>(ThemeCubit.new);

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'lib/assets/google_fonts/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  runApp(App(bootstrap: _bootstrap()));
}

Future<void> _bootstrap() async {
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    publishableKey: EnvConfig.supabasePublishableKey,
    httpClient: kDebugMode ? LoggingHttpClient() : null,
  );

  await initDependencies();

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
        if (data.session != null) {
          rootNavigatorKey.currentContext?.go('/home');
        }
      case AuthChangeEvent.passwordRecovery:
        rootNavigatorKey.currentContext?.go('/redefinir-senha');
      case AuthChangeEvent.signedOut:
        rootNavigatorKey.currentContext?.go('/');
      default:
        break;
    }
  });
}
