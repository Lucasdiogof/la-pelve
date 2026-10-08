import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';

import 'session_test_support.dart';

void main() {
  late SessionHarness h;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    h = SessionHarness();
  });
  tearDown(() => h.close());

  test('bootstrap espera TODOS os dados críticos', () async {
    final agenda = Completer<Result<List<Appointment>>>();
    h.agendaAnswer = pendingAnswer(agenda);

    var done = false;
    final bootstrap = h.controller.ensureLoaded().then((_) => done = true);
    await Future<void>.delayed(Duration.zero);

    expect(h.controller.patients.state.hasData, isTrue);
    expect(h.controller.financial.state.hasData, isTrue);
    expect(h.controller.isReady, isFalse, reason: 'agenda ainda carregando');
    expect(done, isFalse);

    agenda.complete(const Success([]));
    await bootstrap;
    expect(h.controller.isReady, isTrue);
  });

  test('carrega as três fontes em paralelo, uma vez cada', () async {
    await Future.wait([
      h.controller.ensureLoaded(),
      h.controller.ensureLoaded(),
    ]);
    expect((h.patientCalls, h.agendaCalls, h.financialCalls), (1, 1, 1));

    // Já pronto: nova chamada não refaz nada.
    await h.controller.ensureLoaded();
    expect((h.patientCalls, h.agendaCalls, h.financialCalls), (1, 1, 1));
  });

  test('uma fonte falhando deixa a sessão com falha bloqueante', () async {
    h.financialAnswer = () async => Error(NetworkFailure());
    await h.controller.ensureLoaded();

    expect(h.controller.isReady, isFalse);
    expect(h.controller.hasBlockingFailure, isTrue);
    expect(h.controller.financial.state.data, isNull);
  });

  test('retry do bootstrap busca só o que falhou', () async {
    h.financialAnswer = () async => Error(NetworkFailure());
    await h.controller.ensureLoaded();

    h.financialAnswer = () async => const Success([]);
    await h.controller.ensureLoaded();

    expect(h.controller.isReady, isTrue);
    expect(h.controller.hasBlockingFailure, isFalse);
    expect((h.patientCalls, h.agendaCalls, h.financialCalls), (1, 1, 2));
  });

  test('refreshAll mantém os dados e uma falha não os apaga', () async {
    h.patientsAnswer = () async => Success([patientNamed('p1', 'Ana')]);
    await h.controller.ensureLoaded();

    h.patientsAnswer = () async => Error(NetworkFailure());
    await h.controller.refreshAll();

    expect(h.controller.isReady, isTrue);
    expect(h.controller.patients.state.data!.single.id, 'p1');
    expect(h.controller.patients.state.failure, isA<NetworkFailure>());
  });

  group('sessão / privacidade', () {
    test('logout limpa todos os dados em memória', () async {
      h.patientsAnswer = () async =>
          Success([patientNamed('a1', 'Paciente A')]);
      h.controller.onSessionUser('user-a');
      await h.controller.ensureLoaded();
      await h.controller.profile.ensureLoaded();
      expect(h.controller.profile.state.profile, isNotNull);

      h.controller.onSessionUser(null); // signedOut

      expect(h.controller.isReady, isFalse);
      for (final resource in h.controller.criticalResources) {
        expect(resource.state.data, isNull);
      }
      expect(h.controller.profile.state.profile, isNull);
      expect(h.controller.profile.state.photoUrl, isNull);
    });

    test('outro usuário nunca recebe os dados do anterior', () async {
      h.patientsAnswer = () async =>
          Success([patientNamed('a1', 'Paciente A')]);
      h.controller.onSessionUser('user-a');
      await h.controller.ensureLoaded();

      // Uma recarga da conta A ainda está no ar quando a conta B entra.
      final staleA = Completer<Result<List<Patient>>>();
      h.patientsAnswer = pendingAnswer(staleA);
      final staleRefresh = h.controller.patients.refresh();

      h.controller.onSessionUser('user-b');
      expect(h.controller.patients.state.data, isNull);

      h.patientsAnswer = () async =>
          Success([patientNamed('b1', 'Paciente B')]);
      await h.controller.ensureLoaded();

      staleA.complete(Success([patientNamed('a1', 'Paciente A')]));
      await staleRefresh;

      expect(h.controller.patients.state.data!.single.id, 'b1');
    });

    test('mesmo usuário (token renovado) não apaga nada', () async {
      h.controller.onSessionUser('user-a');
      await h.controller.ensureLoaded();
      h.controller.onSessionUser('user-a');
      expect(h.controller.isReady, isTrue);
    });
  });
}
