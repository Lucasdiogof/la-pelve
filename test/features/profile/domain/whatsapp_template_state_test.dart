import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';

WhatsappConnection _conn(
  WhatsappConnectionStatus status, [
  Map<String, dynamic>? setup,
]) => WhatsappConnection(
  id: 'c',
  fisioterapeutaId: 'f',
  status: status,
  setupState: setup,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test('sem aviso: conectada = aprovado; pendente = em análise', () {
    expect(
      _conn(
        WhatsappConnectionStatus.connected,
      ).templateState('appointment_12h'),
      WhatsappTemplateState.approved,
    );
    expect(
      _conn(WhatsappConnectionStatus.pending).templateState('appointment_12h'),
      WhatsappTemplateState.pending,
    );
  });

  test('avisos da Meta por modelo, independentes entre si', () {
    final c = _conn(WhatsappConnectionStatus.pending, {
      'templates': {
        'appointment_12h:pt_BR': {'event': 'approved', 'at': 'x'},
        'appointment_confirmation:pt_BR': {'event': 'PAUSED', 'at': 'x'},
      },
    });
    expect(c.templateState('appointment_12h'), WhatsappTemplateState.approved);
    expect(
      c.templateState('appointment_confirmation'),
      WhatsappTemplateState.problem,
    );
  });
}
