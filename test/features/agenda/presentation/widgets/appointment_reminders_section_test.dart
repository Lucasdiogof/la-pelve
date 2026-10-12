import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/agenda/data/appointment_reminder_repository.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_reminder.dart';
import 'package:la_pelve/features/agenda/presentation/widgets/appointment_reminders_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepository implements AppointmentReminderRepository {
  _FakeRepository(this.result);

  final Result<List<AppointmentReminder>> result;
  final calls = <String>[];

  @override
  Future<Result<List<AppointmentReminder>>> remindersFor(
    String appointmentId,
  ) async {
    calls.add(appointmentId);
    return result;
  }
}

AppointmentReminder _reminder(
  String type,
  String status, {
  DateTime? created,
  DateTime? read,
  DateTime? failed,
}) => AppointmentReminder(
  reminderType: type,
  status: status,
  scheduledFor: DateTime(2026, 10, 12, 8),
  sentAt: DateTime(2026, 10, 12, 8, 1),
  deliveredAt: read == null ? null : DateTime(2026, 10, 12, 8, 2),
  readAt: read,
  failedAt: failed,
  createdAt: created ?? DateTime(2026, 10, 11),
);

Future<void> _pump(WidgetTester tester, _FakeRepository repository) async {
  tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LocaleCubit(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppointmentRemindersSection(
            appointmentId: 'appt-1',
            repository: repository,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra tipo, situação e horário do lembrete', (tester) async {
    final repository = _FakeRepository(
      Success([
        _reminder(
          'appointment_12h',
          'read',
          read: DateTime(2026, 10, 12, 9, 30),
        ),
      ]),
    );
    await _pump(tester, repository);

    expect(repository.calls, ['appt-1']);
    expect(find.text('Lembretes pelo WhatsApp'.toUpperCase()), findsOneWidget);
    expect(find.text('Pedido de confirmação'), findsOneWidget);
    expect(find.text('Lido'), findsOneWidget);
    expect(find.text('12/10 09:30'), findsOneWidget);
  });

  testWidgets('falha de entrega aparece como "Não entregue"', (tester) async {
    await _pump(
      tester,
      _FakeRepository(
        Success([
          _reminder(
            'appointment_12h',
            'failed',
            failed: DateTime(2026, 10, 12, 8, 5),
          ),
        ]),
      ),
    );
    expect(find.text('Não entregue'), findsOneWidget);
    expect(find.text('12/10 08:05'), findsOneWidget);
  });

  testWidgets('sem lembretes ou com erro de leitura, não mostra nada', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository(const Success([])));
    expect(find.text('Pedido de confirmação'), findsNothing);
    expect(find.byType(Text), findsNothing);
    await _pump(tester, _FakeRepository(Error(ServerFailure())));
    expect(find.byType(Text), findsNothing);
  });

  test('latestRemindersByType: um por tipo, o mais recente, em ordem fixa', () {
    final old12h = _reminder(
      'appointment_12h',
      'cancelled',
      created: DateTime(2026, 10, 1),
    );
    final new12h = _reminder(
      'appointment_12h',
      'sent',
      created: DateTime(2026, 10, 5),
    );
    final notice = _reminder('appointment_confirmation', 'delivered');
    final unknown = _reminder('outro', 'sent');
    expect(latestRemindersByType([old12h, unknown, new12h, notice]), [
      notice,
      new12h,
    ]);
  });

  test(
    'fromJson converte para hora local e não depende de colunas sensíveis',
    () {
      final reminder = AppointmentReminder.fromJson({
        'reminder_type': 'appointment_12h',
        'status': 'delivered',
        'scheduled_for': '2026-10-12T11:00:00Z',
        'delivered_at': '2026-10-12T11:01:00Z',
        'created_at': '2026-10-11T00:00:00Z',
      });
      expect(reminder.status, 'delivered');
      expect(reminder.statusAt, DateTime.utc(2026, 10, 12, 11, 1).toLocal());
    },
  );
}
