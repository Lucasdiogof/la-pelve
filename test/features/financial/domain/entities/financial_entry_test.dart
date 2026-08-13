import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';

void main() {
  group('FinancialEntry.toJson/fromJson', () {
    test('round-trips a fully populated entry', () {
      final entry = FinancialEntry(
        id: 'f1',
        patientId: 'p1',
        patientName: 'Maria',
        data: DateTime(2026, 3, 5),
        valor: 180.5,
        observacoes: 'Pagamento da avaliação',
        formaPagamento: FormaPagamento.pix,
        status: StatusPagamento.pago,
      );

      final restored = FinancialEntry.fromJson(entry.toJson());

      expect(restored, entry);
    });

    test('defaults status to pago for an unknown value', () {
      final json = {
        'id': 'f1',
        'patient_name': 'Maria',
        'data': '2026-03-05',
        'valor': 100,
        'status': 'unknown_status',
      };

      expect(FinancialEntry.fromJson(json).status, StatusPagamento.pago);
    });

    test('accepts an integer valor from JSON', () {
      final json = {
        'id': 'f1',
        'patient_name': 'Maria',
        'data': '2026-03-05',
        'valor': 100,
        'status': 'pago',
      };

      expect(FinancialEntry.fromJson(json).valor, 100.0);
    });

    test('allows a null patientId for a manual entry', () {
      final entry = FinancialEntry(
        id: 'f1',
        patientName: 'Consulta avulsa',
        data: DateTime(2026, 3, 5),
        valor: 100,
      );

      final restored = FinancialEntry.fromJson(entry.toJson());

      expect(restored.patientId, isNull);
    });
  });
}
