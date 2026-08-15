import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/router/app_page.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/pages/agenda_form_page.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/pages/login_page.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/pages/register_page.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/pages/reset_password_page.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/pages/financial_form_page.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/pages/home_shell_page.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/evolution_form_page.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/evolution_list_page.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/patient_detail_page.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/patient_form_page.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/pages/biometric_settings_page.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/pages/change_password_page.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/pages/edit_name_page.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/pages/language_settings_page.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/pages/profile_page.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/pages/theme_settings_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  redirect: (context, state) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (hasSession && state.matchedLocation == '/') return '/home';
    return null;
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
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sl<PatientsCubit>()),
            BlocProvider.value(value: sl<FinancialCubit>()),
            BlocProvider.value(value: sl<AgendaCubit>()),
            BlocProvider.value(value: sl<ProfileCubit>()),
          ],
          child: const HomeShellPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/novo',
      pageBuilder: (context, state) => appPage(
        state,
        BlocProvider.value(
          value: sl<PatientsCubit>(),
          child: const PatientFormPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id',
      pageBuilder: (context, state) => appPage(
        state,
        BlocProvider.value(
          value: sl<PatientsCubit>(),
          child: PatientDetailPage(patient: state.extra! as Patient),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id/editar',
      pageBuilder: (context, state) => appPage(
        state,
        BlocProvider.value(
          value: sl<PatientsCubit>(),
          child: PatientFormPage(patient: state.extra! as Patient),
        ),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id/evolucao',
      pageBuilder: (context, state) =>
          appPage(state, EvolutionListPage(patient: state.extra! as Patient)),
    ),
    GoRoute(
      path: '/pacientes/:id/evolucao/novo',
      pageBuilder: (context, state) => appPage(
        state,
        EvolutionFormPage(patientId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/pacientes/:id/evolucao/:entryId/editar',
      pageBuilder: (context, state) => appPage(
        state,
        EvolutionFormPage(
          patientId: state.pathParameters['id']!,
          existingEntry: state.extra! as EvolutionEntry,
        ),
      ),
    ),
    GoRoute(
      path: '/perfil',
      pageBuilder: (context, state) => appPage(state, const ProfilePage()),
    ),
    GoRoute(
      path: '/perfil/editar-nome',
      pageBuilder: (context, state) =>
          appPage(state, EditNamePage(initialNome: state.extra! as String)),
    ),
    GoRoute(
      path: '/perfil/tema',
      pageBuilder: (context, state) =>
          appPage(state, const ThemeSettingsPage()),
    ),
    GoRoute(
      path: '/perfil/idioma',
      pageBuilder: (context, state) =>
          appPage(state, const LanguageSettingsPage()),
    ),
    GoRoute(
      path: '/perfil/biometria',
      pageBuilder: (context, state) =>
          appPage(state, const BiometricSettingsPage()),
    ),
    GoRoute(
      path: '/perfil/alterar-senha',
      pageBuilder: (context, state) =>
          appPage(state, const ChangePasswordPage()),
    ),
    GoRoute(
      path: '/financeiro/novo',
      pageBuilder: (context, state) => appPage(
        state,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sl<FinancialCubit>()),
            BlocProvider.value(value: sl<PatientsCubit>()),
          ],
          child: const FinancialFormPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/financeiro/:id/editar',
      pageBuilder: (context, state) => appPage(
        state,
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
    GoRoute(
      path: '/agenda/novo',
      pageBuilder: (context, state) => appPage(
        state,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sl<AgendaCubit>()),
            BlocProvider.value(value: sl<PatientsCubit>()),
          ],
          child: const AgendaFormPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/agenda/:id/editar',
      pageBuilder: (context, state) => appPage(
        state,
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
  ],
);
