import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';

void main() {
  group('EvolutionEntry.toJson/fromJson', () {
    test('round-trips through the wire format', () {
      final entry = EvolutionEntry(
        id: 'e1',
        patientId: 'p1',
        date: DateTime(2026, 3, 5),
        description: 'Paciente relatou melhora',
        updatedAt: DateTime.utc(2026, 3, 6, 10),
      );

      final json = entry.toJson();
      final restored = EvolutionEntry.fromJson({
        ...json,
        'physiotherapist_id': 'therapist-1',
        'created_at': DateTime.utc(2026, 3, 5, 9).toIso8601String(),
      });

      expect(restored.id, entry.id);
      expect(restored.patientId, entry.patientId);
      expect(restored.date, entry.date);
      expect(restored.description, entry.description);
      expect(restored.updatedAt, entry.updatedAt);
      expect(restored.createdBy, 'therapist-1');
    });

    test('toJson does not include createdBy or createdAt', () {
      final entry = EvolutionEntry(
        id: 'e1',
        patientId: 'p1',
        date: DateTime.utc(2026, 3, 5),
        description: 'Nota',
        createdBy: 'therapist-1',
        createdAt: DateTime.utc(2026, 3, 5),
      );

      final json = entry.toJson();

      expect(json.containsKey('physiotherapist_id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
    });
  });

  group('EvolutionEntry.copyWith', () {
    test('keeps id, patientId, createdBy and createdAt fixed', () {
      final original = EvolutionEntry(
        id: 'e1',
        patientId: 'p1',
        date: DateTime.utc(2026, 3, 5),
        description: 'Original',
        createdBy: 'therapist-1',
        createdAt: DateTime.utc(2026, 3, 5),
      );

      final updated = original.copyWith(description: 'Editada');

      expect(updated.id, original.id);
      expect(updated.patientId, original.patientId);
      expect(updated.createdBy, original.createdBy);
      expect(updated.createdAt, original.createdAt);
      expect(updated.description, 'Editada');
    });
  });
}
