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
        date: DateTime(2026, 3, 5),
        amount: 180.5,
        notes: 'Pagamento da avaliação',
        paymentMethod: PaymentMethod.pix,
        status: PaymentStatus.paid,
      );

      final restored = FinancialEntry.fromJson(entry.toJson());

      expect(restored, entry);
    });

    test('defaults status to paid for an unknown value', () {
      final json = {
        'id': 'f1',
        'patient_name': 'Maria',
        'date': '2026-03-05',
        'amount': 100,
        'status': 'unknown_status',
      };

      expect(FinancialEntry.fromJson(json).status, PaymentStatus.paid);
    });

    test('accepts an integer amount from JSON', () {
      final json = {
        'id': 'f1',
        'patient_name': 'Maria',
        'date': '2026-03-05',
        'amount': 100,
        'status': 'paid',
      };

      expect(FinancialEntry.fromJson(json).amount, 100.0);
    });

    test('allows a null patientId for a manual entry', () {
      final entry = FinancialEntry(
        id: 'f1',
        patientName: 'Consulta avulsa',
        date: DateTime(2026, 3, 5),
        amount: 100,
      );

      final restored = FinancialEntry.fromJson(entry.toJson());

      expect(restored.patientId, isNull);
    });
  });
}
