import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/router/app_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/theme/app_theme.dart';
import 'package:fisioterapia_pelvica/core/theme/theme_cubit.dart';
import 'package:fisioterapia_pelvica/core/utils/app_lock_gate.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_loading_widget.dart';
import 'package:fisioterapia_pelvica/shared/widgets/pulsing_logo.dart';

class App extends StatelessWidget {
  const App({required this.bootstrap, super.key});

  final Future<void> bootstrap;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider.value(value: sl<LocaleCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, AppLanguage>(
            builder: (context, language) {
              return MaterialApp.router(
                title: language.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                locale: language.locale,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
                routerConfig: appRouter,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: true),
                    child: GlobalLoaderOverlay(
                      overlayColor: context.colors.background.withValues(
                        alpha: 0.7,
                      ),
                      overlayWidgetBuilder: (progress) =>
                          const AppLoadingWidget(),
                      child: FutureBuilder<void>(
                        future: bootstrap,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return Scaffold(
                              backgroundColor: context.colors.background,
                              body: const Center(
                                child: PulsingLogo(size: 64, animate: false),
                              ),
                            );
                          }
                          return ColoredBox(
                            color: context.colors.background,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: AppLockGate(
                                  child: child ?? const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
