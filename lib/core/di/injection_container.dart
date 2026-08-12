import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/services/biometric_service.dart';
import 'package:fisioterapia_pelvica/features/agenda/data/agenda_repository_supabase.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/data/auth_repository_impl.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/data/financial_repository_supabase.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/repositories/financial_repository.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/data/attachment_repository_supabase.dart';
import 'package:fisioterapia_pelvica/features/patients/data/patient_repository_supabase.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/attachment_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/features/profile/data/profile_repository_supabase.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/repositories/profile_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<BiometricService>(
    () => BiometricService(LocalAuthentication()),
  );

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));

  sl.registerLazySingleton<PatientRepository>(
    () => PatientRepositorySupabase(sl()),
  );
  sl.registerLazySingleton<FinancialRepository>(
    () => FinancialRepositorySupabase(sl()),
  );
  sl.registerLazySingleton<AgendaRepository>(
    () => AgendaRepositorySupabase(sl()),
  );
  sl.registerLazySingleton<AttachmentRepository>(
    () => AttachmentRepositorySupabase(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositorySupabase(sl()),
  );

  sl.registerLazySingleton<PatientsCubit>(() => PatientsCubit(sl()));
  sl.registerLazySingleton<FinancialCubit>(() => FinancialCubit(sl()));
  sl.registerLazySingleton<AgendaCubit>(() => AgendaCubit(sl()));
}
