import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_theme.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/repositories/financial_repository.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/pages/home_page.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

class _FakeAgendaRepository extends Mock implements AgendaRepository {}

class _FakeFinancialRepository extends Mock implements FinancialRepository {}

void main() {
  testWidgets('HomePage renders the dashboard with an empty schedule', (
    WidgetTester tester,
  ) async {
    final patientRepository = _FakePatientRepository();
    final agendaRepository = _FakeAgendaRepository();
    final financialRepository = _FakeFinancialRepository();
    when(
      () => patientRepository.getAll(),
    ).thenAnswer((_) async => const Success(<Patient>[]));
    when(
      () => agendaRepository.getAll(),
    ).thenAnswer((_) async => const Success(<Appointment>[]));
    when(
      () => financialRepository.getAll(),
    ).thenAnswer((_) async => const Success(<FinancialEntry>[]));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => PatientsCubit(patientRepository)),
            BlocProvider(create: (_) => AgendaCubit(agendaRepository)),
            BlocProvider(create: (_) => FinancialCubit(financialRepository)),
          ],
          child: HomePage(onNavigateToTab: (_) {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Próximos atendimentos'), findsOneWidget);
    expect(
      find.text('Nenhum atendimento nos próximos 7 dias.'),
      findsOneWidget,
    );
  });
}
