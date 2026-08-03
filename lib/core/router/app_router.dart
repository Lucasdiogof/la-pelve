import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/pages/login_page.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/pages/home_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
