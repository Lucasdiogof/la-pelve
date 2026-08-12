import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';

void main() {
  group('Patient.toJson/fromJson', () {
    test('round-trips a fully populated patient', () {
      final patient = Patient(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 10, 12),
        dadosPessoais: const DadosPessoais(
          nome: 'Maria',
          idade: 32,
          telefone: '11933334444',
          profissao: 'Professora',
          sexo: Sexo.feminino,
        ),
        anamnese: const Anamnese(
          queixaPrincipal: 'Dor pélvica',
          temDiagnosticoMedico: true,
          tabagismo: false,
        ),
        planoTratamento: const PlanoTratamento(
          diagnosticoFisioterapeutico: 'Disfunção do assoalho pélvico',
        ),
        encerramento: Encerramento(
          data: DateTime.utc(2026, 2, 1),
          motivo: MotivoEncerramento.alta,
          observacaoFinal: 'Paciente evoluiu bem',
        ),
        valorConsulta: 180.5,
      );

      final json = patient.toJson();
      final restored = Patient.fromJson(json);

      expect(restored, patient);
    });

    test('round-trips a patient with only required fields', () {
      final patient = Patient(id: 'p2', createdAt: DateTime.utc(2026, 1, 1));

      final restored = Patient.fromJson(patient.toJson());

      expect(restored, patient);
      expect(restored.encerramento, isNull);
      expect(restored.dadosPessoais.sexo, isNull);
    });

    test('fromJson tolerates missing nested sections', () {
      final json = {
        'id': 'p3',
        'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      };

      final patient = Patient.fromJson(json);

      expect(patient.dadosPessoais.nome, '');
      expect(patient.anamnese.queixaPrincipal, '');
      expect(patient.encerramento, isNull);
    });
  });

  group('Patient.copyWith', () {
    test('keeps the original id and createdAt', () {
      final original = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));
      final updated = original.copyWith(
        dadosPessoais: const DadosPessoais(nome: 'Ana'),
      );

      expect(updated.id, original.id);
      expect(updated.createdAt, original.createdAt);
      expect(updated.dadosPessoais.nome, 'Ana');
    });

    test('clears encerramento when explicitly passed null', () {
      final withEncerramento = Patient(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        encerramento: Encerramento(
          data: DateTime.utc(2026, 2, 1),
          motivo: MotivoEncerramento.abandono,
        ),
      );

      final reopened = withEncerramento.copyWith(encerramento: null);

      expect(reopened.encerramento, isNull);
    });

    test('keeps encerramento when the argument is omitted', () {
      final encerramento = Encerramento(
        data: DateTime.utc(2026, 2, 1),
        motivo: MotivoEncerramento.abandono,
      );
      final withEncerramento = Patient(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        encerramento: encerramento,
      );

      final updated = withEncerramento.copyWith(valorConsulta: 200);

      expect(updated.encerramento, encerramento);
    });
  });

  group('Anamnese.copyWith', () {
    test('clears a nullable bool when explicitly passed null', () {
      const original = Anamnese(tabagismo: true);
      final updated = original.copyWith(tabagismo: null);

      expect(updated.tabagismo, isNull);
    });

    test('keeps the field when the argument is omitted', () {
      const original = Anamnese(tabagismo: true);
      final updated = original.copyWith(queixaPrincipal: 'Nova queixa');

      expect(updated.tabagismo, isTrue);
      expect(updated.queixaPrincipal, 'Nova queixa');
    });
  });

  group('Patient equality', () {
    test('two patients with the same values are equal', () {
      final a = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));
      final b = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));

      expect(a, b);
    });

    test('patients with different ids are not equal', () {
      final a = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));
      final b = Patient(id: 'p2', createdAt: DateTime.utc(2026, 1, 1));

      expect(a == b, isFalse);
    });
  });
}
