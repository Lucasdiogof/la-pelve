import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:fisioterapia_pelvica/core/constants/app_constants.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
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
    return BlocProvider.value(
      value: sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: appRouter,
            builder: (context, child) {
              return GlobalLoaderOverlay(
                overlayColor: context.colors.background.withValues(alpha: 0.7),
                overlayWidgetBuilder: (progress) => const AppLoadingWidget(),
                child: FutureBuilder<void>(
                  future: bootstrap,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Scaffold(
                        backgroundColor: context.colors.background,
                        body: const Center(child: PulsingLogo(size: 140)),
                      );
                    }
                    return ColoredBox(
                      color: context.colors.background,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: AppLockGate(
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
