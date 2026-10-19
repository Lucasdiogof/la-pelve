import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/auth/domain/entities/data_deletion_schedule.dart';
import 'package:la_pelve/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pelve/features/auth/presentation/widgets/deletion_scheduled_gate.dart';

class _MockAuth extends Mock implements AuthRepository {}

void main() {
  late _MockAuth auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    auth = _MockAuth();
    await sl.reset();
    sl.registerSingleton<AuthRepository>(auth);
  });

  tearDown(() => sl.reset());

  Future<void> pump(WidgetTester tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LocaleCubit(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DeletionScheduledGate(child: Text('APP LIBERADO')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final schedule = DataDeletionSchedule(
    requestedAt: DateTime(2026, 10, 19),
    purgeAfter: DateTime(2026, 11, 18),
  );

  testWidgets('sem pedido de exclusão: abre o app normalmente', (tester) async {
    when(
      () => auth.getDataDeletionSchedule(),
    ).thenAnswer((_) async => const Success(null));
    await pump(tester);
    expect(find.text('APP LIBERADO'), findsOneWidget);
  });

  testWidgets('falha na checagem (offline): NÃO bloqueia o app', (
    tester,
  ) async {
    when(
      () => auth.getDataDeletionSchedule(),
    ).thenAnswer((_) async => Error(NetworkFailure()));
    await pump(tester);
    expect(find.text('APP LIBERADO'), findsOneWidget);
  });

  testWidgets('exclusão agendada: mostra só a tela de restaurar', (
    tester,
  ) async {
    when(
      () => auth.getDataDeletionSchedule(),
    ).thenAnswer((_) async => Success(schedule));
    await pump(tester);
    expect(find.text('APP LIBERADO'), findsNothing);
    expect(find.text('Exclusão agendada'), findsOneWidget);
    expect(find.textContaining('18/11/2026'), findsOneWidget);
  });

  testWidgets('restaurar com sucesso libera o app', (tester) async {
    when(
      () => auth.getDataDeletionSchedule(),
    ).thenAnswer((_) async => Success(schedule));
    when(
      () => auth.cancelDataDeletion(),
    ).thenAnswer((_) async => const Success(null));
    await pump(tester);
    await tester.tap(find.text('Restaurar minha conta'));
    await tester.pumpAndSettle();
    verify(() => auth.cancelDataDeletion()).called(1);
    expect(find.text('APP LIBERADO'), findsOneWidget);
  });

  testWidgets('restaurar com falha mantém a tela e avisa', (tester) async {
    when(
      () => auth.getDataDeletionSchedule(),
    ).thenAnswer((_) async => Success(schedule));
    when(
      () => auth.cancelDataDeletion(),
    ).thenAnswer((_) async => Error(ServerFailure()));
    await pump(tester);
    await tester.tap(find.text('Restaurar minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('APP LIBERADO'), findsNothing);
    expect(find.textContaining('Não foi possível restaurar'), findsOneWidget);
  });
}
