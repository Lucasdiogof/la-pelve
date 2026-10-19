import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/offline/connectivity_monitor.dart';
import 'package:la_pelve/core/offline/local/key_vault.dart';
import 'package:la_pelve/core/offline/local/local_store_factory.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/remote_gateway.dart';
import 'package:la_pelve/core/offline/sync/sync_status_cubit.dart';
import 'package:la_pelve/core/services/biometric_service.dart';
import 'package:la_pelve/core/session/session_data_controller.dart';
import 'package:la_pelve/features/agenda/data/agenda_repository_offline.dart';
import 'package:la_pelve/features/agenda/data/agenda_repository_supabase.dart';
import 'package:la_pelve/features/agenda/data/appointment_reminder_repository.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/profile/data/export/data_export_repository.dart';
import 'package:la_pelve/features/profile/data/export/data_export_service.dart';
import 'package:la_pelve/features/profile/data/export/supabase_export_data_source.dart';
import 'package:la_pelve/features/auth/data/auth_repository_impl.dart';
import 'package:la_pelve/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pelve/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:la_pelve/features/financial/data/financial_repository_offline.dart';
import 'package:la_pelve/features/financial/data/financial_repository_supabase.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/patients/data/attachment_repository_supabase.dart';
import 'package:la_pelve/features/patients/data/patient_consent_repository_supabase.dart';
import 'package:la_pelve/features/patients/data/patient_repository_offline.dart';
import 'package:la_pelve/features/patients/data/patient_repository_supabase.dart';
import 'package:la_pelve/features/patients/domain/repositories/attachment_repository.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/profile/data/profile_repository_supabase.dart';
import 'package:la_pelve/features/profile/data/whatsapp_connection_repository_supabase.dart';
import 'package:la_pelve/features/profile/domain/repositories/profile_repository.dart';
import 'package:la_pelve/features/profile/domain/repositories/whatsapp_connection_repository.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_cubit.dart';

final GetIt sl = GetIt.instance;

/// Serviço opcional: null quando não registrado (testes de widget, Web sem
/// armazenamento offline). As telas usam isto para o que é só um extra.
T? maybeSl<T extends Object>() => sl.isRegistered<T>() ? sl<T>() : null;

Future<void> initDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<BiometricService>(
    () => BiometricService(LocalAuthentication()),
  );

  // Offline-first (Android/iOS): banco local cifrado + fila + sincronização.
  // Na Web `enabled` é falso e os repositórios operam direto no Supabase.
  sl.registerLazySingleton<KeyVault>(SecureStorageKeyVault.new);
  sl.registerLazySingleton<ConnectivityMonitor>(
    PlatformConnectivityMonitor.new,
  );
  sl.registerLazySingleton<RemoteGateway>(() => SupabaseRemoteGateway(sl()));
  sl.registerLazySingleton<OfflineSession>(
    () => OfflineSession(
      vault: sl(),
      remote: sl(),
      monitor: sl(),
      currentUserId: () => Supabase.instance.client.auth.currentUser?.id,
      enabled: offlineStoreSupported,
    ),
  );
  sl.registerLazySingleton<SyncStatusCubit>(() => SyncStatusCubit(sl(), sl()));
  await sl<ConnectivityMonitor>().start();

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), offline: sl<OfflineSession>()),
  );
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));
  sl.registerLazySingleton<DataExportRepository>(
    () => DataExportRepository(
      sl(),
      DataExportService(
        SupabaseExportDataSource(
          sl(),
          pendingLocalChanges: () async =>
              sl<OfflineSession>().active?.store.counts().total ?? 0,
        ),
      ),
    ),
  );

  sl.registerLazySingleton<PatientRepository>(
    () => PatientRepositoryOffline(sl(), PatientRepositorySupabase(sl())),
  );
  sl.registerLazySingleton<FinancialRepository>(
    () => FinancialRepositoryOffline(sl(), FinancialRepositorySupabase(sl())),
  );
  sl.registerLazySingleton<AgendaRepository>(
    () => AgendaRepositoryOffline(sl(), AgendaRepositorySupabase(sl()), sl()),
  );
  sl.registerLazySingleton<AppointmentReminderRepository>(
    () => AppointmentReminderRepositorySupabase(sl()),
  );
  sl.registerLazySingleton<AttachmentRepository>(
    () => AttachmentRepositorySupabase(sl()),
  );
  sl.registerLazySingleton<PatientConsentRepository>(
    () => PatientConsentRepositorySupabase(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositorySupabase(sl()),
  );
  sl.registerLazySingleton<WhatsappConnectionRepository>(
    () => WhatsappConnectionRepositorySupabase(sl()),
  );

  sl.registerLazySingleton<PatientsCubit>(() => PatientsCubit(sl()));
  sl.registerLazySingleton<FinancialCubit>(() => FinancialCubit(sl()));
  sl.registerLazySingleton<AgendaCubit>(() => AgendaCubit(sl()));
  sl.registerLazySingleton<ProfileCubit>(() => ProfileCubit(sl()));
  sl.registerLazySingleton<SessionDataController>(
    () => SessionDataController(
      patients: sl(),
      agenda: sl(),
      financial: sl(),
      profile: sl(),
      offline: sl(),
    ),
  );
}
