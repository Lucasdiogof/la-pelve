import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/router/app_page.dart';
import 'package:la_pelve/core/session/session_data_controller.dart';
import 'package:la_pelve/core/session/session_data_gate.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/agenda/presentation/pages/agenda_form_page.dart';
import 'package:la_pelve/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:la_pelve/features/auth/presentation/pages/login_page.dart';
import 'package:la_pelve/features/auth/presentation/pages/register_page.dart';
import 'package:la_pelve/features/auth/presentation/pages/reset_password_page.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/financial/presentation/pages/financial_form_page.dart';
import 'package:la_pelve/features/home/presentation/cubit/home_financial_visibility_cubit.dart';
import 'package:la_pelve/features/home/presentation/pages/home_shell_page.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/pages/evolution_form_page.dart';
import 'package:la_pelve/features/patients/presentation/pages/evolution_list_page.dart';
import 'package:la_pelve/features/patients/presentation/pages/patient_detail_page.dart';
import 'package:la_pelve/features/patients/presentation/pages/patient_form_page.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:la_pelve/features/profile/presentation/pages/biometric_settings_page.dart';
import 'package:la_pelve/features/profile/presentation/pages/change_password_page.dart';
import 'package:la_pelve/features/profile/presentation/pages/edit_name_page.dart';
import 'package:la_pelve/features/profile/presentation/pages/language_settings_page.dart';
import 'package:la_pelve/features/profile/presentation/pages/profile_page.dart';
import 'package:la_pelve/features/profile/presentation/pages/theme_settings_page.dart';
import 'package:la_pelve/features/profile/presentation/pages/whatsapp_connection_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Set by `main()` before `runApp` to the app's bootstrap future
/// (Supabase session restore + DI setup). The initial redirect awaits it
/// so the router never resolves `/` before the real session state is known.
Future<void>? appBootstrapFuture;

/// Rotas acessíveis sem sessão. Todas as outras são da área logada.
const publicRoutes = {'/', '/cadastro', '/redefinir-senha'};

/// Decide o redirecionamento só a partir da sessão e do destino (puro, para
/// teste): com sessão, a tela de login leva à Home; sem sessão, qualquer
/// rota da área logada (ex.: link direto na web) leva ao login.
String? authRedirect({required bool hasSession, required String location}) {
  if (hasSession && location == '/') return '/home';
  if (!hasSession && !publicRoutes.contains(location)) return '/';
  return null;
}

/// Envolve uma tela da área logada: ela só é montada com os dados críticos
/// da sessão carregados (ver [SessionDataGate]).
Widget _authenticated(Widget child) =>
    SessionDataGate(controller: sl<SessionDataController>(), child: child);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  redirect: (context, state) async {
    if (appBootstrapFuture != null) await appBootstrapFuture;
    return authRedirect(
      hasSession: Supabase.instance.client.auth.currentSession != null,
      location: state.matchedLocation,
    );
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => appPage(
        state,
        BlocProvider(create: (_) => sl<AuthCubit>(), child: const LoginPage()),
      ),
    ),
    GoRoute(
      path: '/cadastro',
      pageBuilder: (context, state) => appPage(
        state,
        BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: const RegisterPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/redefinir-senha',
      pageBuilder: (context, state) =>
          appPage(state, const ResetPasswordPage()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: sl<PatientsCubit>()),
              BlocProvider.value(value: sl<FinancialCubit>()),
              BlocProvider.value(value: sl<AgendaCubit>()),
              BlocProvider.value(value: sl<ProfileCubit>()),
              BlocProvider.value(value: sl<HomeFinancialVisibilityCubit>()),
            ],
            child: const HomeShellPage(),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/novo',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          BlocProvider.value(
            value: sl<PatientsCubit>(),
            child: const PatientFormPage(),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          BlocProvider.value(
            value: sl<PatientsCubit>(),
            child: PatientDetailPage(patient: state.extra! as Patient),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id/editar',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          BlocProvider.value(
            value: sl<PatientsCubit>(),
            child: PatientFormPage(patient: state.extra! as Patient),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id/evolucao',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(EvolutionListPage(patient: state.extra! as Patient)),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id/evolucao/novo',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          EvolutionFormPage(patientId: state.pathParameters['id']!),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id/evolucao/:entryId/editar',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          EvolutionFormPage(
            patientId: state.pathParameters['id']!,
            existingEntry: state.extra! as EvolutionEntry,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/perfil',
      pageBuilder: (context, state) =>
          appPage(state, _authenticated(const ProfilePage())),
    ),
    GoRoute(
      path: '/perfil/editar-nome',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(EditNamePage(initialNome: state.extra! as String)),
      ),
    ),
    GoRoute(
      path: '/perfil/tema',
      pageBuilder: (context, state) =>
          appPage(state, _authenticated(const ThemeSettingsPage())),
    ),
    GoRoute(
      path: '/perfil/idioma',
      pageBuilder: (context, state) =>
          appPage(state, _authenticated(const LanguageSettingsPage())),
    ),
    GoRoute(
      path: '/perfil/biometria',
      pageBuilder: (context, state) =>
          appPage(state, _authenticated(const BiometricSettingsPage())),
    ),
    GoRoute(
      path: '/perfil/alterar-senha',
      pageBuilder: (context, state) =>
          appPage(state, _authenticated(const ChangePasswordPage())),
    ),
    GoRoute(
      path: '/perfil/whatsapp',
      pageBuilder: (context, state) =>
          appPage(state, _authenticated(const WhatsappConnectionPage())),
    ),
    GoRoute(
      path: '/financeiro/novo',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: sl<FinancialCubit>()),
              BlocProvider.value(value: sl<PatientsCubit>()),
            ],
            child: const FinancialFormPage(),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/financeiro/:id/editar',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: sl<FinancialCubit>()),
              BlocProvider.value(value: sl<PatientsCubit>()),
            ],
            child: FinancialFormPage(
              existingEntry: state.extra! as FinancialEntry,
            ),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/agenda/novo',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: sl<AgendaCubit>()),
              BlocProvider.value(value: sl<PatientsCubit>()),
            ],
            child: const AgendaFormPage(),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/agenda/:id/editar',
      pageBuilder: (context, state) => appPage(
        state,
        _authenticated(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: sl<AgendaCubit>()),
              BlocProvider.value(value: sl<PatientsCubit>()),
            ],
            child: AgendaFormPage(
              existingAppointment: state.extra! as Appointment,
            ),
          ),
        ),
      ),
    ),
  ],
);
