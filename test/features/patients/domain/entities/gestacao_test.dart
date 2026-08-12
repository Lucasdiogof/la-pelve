import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/gestacao.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';

void main() {
  group('Gestacao.toJson/fromJson', () {
    test('round-trips a fully populated value', () {
      const gestacao = Gestacao(
        perdaGestacional: false,
        viaDeParto: ViaDeParto.cesarea,
        complicacaoParto: ComplicacaoParto.laceracao,
        teveComplicacoes: true,
        descricaoComplicacao: 'Sangramento leve',
        pesoAproximadoBebe: '3.2kg',
        usoForcepsOuVacuo: false,
      );

      final restored = Gestacao.fromJson(gestacao.toJson());

      expect(restored, gestacao);
    });

    test('fromJson defaults to nulls for an empty map', () {
      final restored = Gestacao.fromJson(const {});

      expect(restored, const Gestacao());
    });
  });

  group('Gestacao.copyWith', () {
    test('clears a nullable bool when explicitly passed null', () {
      const original = Gestacao(teveComplicacoes: true);
      final updated = original.copyWith(teveComplicacoes: null);

      expect(updated.teveComplicacoes, isNull);
    });

    test('keeps the field when the argument is omitted', () {
      const original = Gestacao(teveComplicacoes: true);
      final updated = original.copyWith(pesoAproximadoBebe: '3kg');

      expect(updated.teveComplicacoes, isTrue);
      expect(updated.pesoAproximadoBebe, '3kg');
    });
  });
}
