import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/session/session_data_controller.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/profile/domain/entities/profile.dart';
import 'package:la_pelve/features/profile/domain/repositories/profile_repository.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_cubit.dart';

class MockPatientRepository extends Mock implements PatientRepository {}

class MockAgendaRepository extends Mock implements AgendaRepository {}

class MockFinancialRepository extends Mock implements FinancialRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

/// Sessão de teste com repositórios controláveis: cada `getAll` responde
/// pelo que estiver configurado em [patientsAnswer], [agendaAnswer] e
/// [financialAnswer] no momento da chamada.
class SessionHarness {
  SessionHarness() {
    when(() => patientRepository.getAll()).thenAnswer((_) {
      patientCalls++;
      return patientsAnswer();
    });
    when(() => agendaRepository.getAll()).thenAnswer((_) {
      agendaCalls++;
      return agendaAnswer();
    });
    when(() => financialRepository.getAll()).thenAnswer((_) {
      financialCalls++;
      return financialAnswer();
    });
    when(
      () => profileRepository.getCurrent(),
    ).thenAnswer((_) async => Success(profile));
    controller = SessionDataController(
      patients: PatientsCubit(patientRepository),
      agenda: AgendaCubit(agendaRepository),
      financial: FinancialCubit(financialRepository),
      profile: ProfileCubit(profileRepository),
    );
  }

  final patientRepository = MockPatientRepository();
  final agendaRepository = MockAgendaRepository();
  final financialRepository = MockFinancialRepository();
  final profileRepository = MockProfileRepository();
  late final SessionDataController controller;

  int patientCalls = 0;
  int agendaCalls = 0;
  int financialCalls = 0;

  Future<Result<List<Patient>>> Function() patientsAnswer = () async =>
      const Success([]);
  Future<Result<List<Appointment>>> Function() agendaAnswer = () async =>
      const Success([]);
  Future<Result<List<FinancialEntry>>> Function() financialAnswer = () async =>
      const Success([]);

  final profile = const Profile(
    id: 'u1',
    email: 'clinica@exemplo.com',
    name: 'Clínica',
    crefito: '',
    phone: '',
  );

  Future<void> close() async {
    await controller.patients.close();
    await controller.agenda.close();
    await controller.financial.close();
    await controller.profile.close();
  }
}

Patient patientNamed(String id, String name) => Patient(
  id: id,
  createdAt: DateTime.utc(2026, 1, 1),
  personalInfo: PersonalInfo(name: name),
);

/// Resposta que só chega quando o teste completar o [Completer].
Future<Result<T>> Function() pendingAnswer<T>(Completer<Result<T>> c) =>
    () => c.future;
