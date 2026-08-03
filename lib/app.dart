import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/constants/app_constants.dart';
import 'package:fisioterapia_pelvica/core/router/app_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
