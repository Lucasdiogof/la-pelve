import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';

void main() {
  group('WhatsappConnection.fromJson', () {
    test('parses a fully populated connected row', () {
      final json = {
        'id': 'c1',
        'fisioterapeuta_id': 'f1',
        'waba_id': 'waba-123',
        'phone_number_id': 'phone-456',
        'display_phone_number': '+55 62 99999-9999',
        'status': 'connected',
        'connected_at': '2026-01-10T12:00:00.000Z',
        'disconnected_at': null,
        'last_error': null,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-10T12:00:00.000Z',
      };

      final connection = WhatsappConnection.fromJson(json);

      expect(connection.id, 'c1');
      expect(connection.fisioterapeutaId, 'f1');
      expect(connection.wabaId, 'waba-123');
      expect(connection.phoneNumberId, 'phone-456');
      expect(connection.displayPhoneNumber, '+55 62 99999-9999');
      expect(connection.status, WhatsappConnectionStatus.connected);
      expect(connection.connectedAt, DateTime.parse('2026-01-10T12:00:00.000Z'));
      expect(connection.disconnectedAt, isNull);
      expect(connection.lastError, isNull);
    });

    test('parses each known status', () {
      for (final status in [
        'pending',
        'connected',
        'disconnected',
        'error',
      ]) {
        final connection = WhatsappConnection.fromJson({
          'id': 'c1',
          'fisioterapeuta_id': 'f1',
          'status': status,
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T00:00:00.000Z',
        });
        expect(
          connection.status.name,
          status,
          reason: 'status "$status" should round-trip',
        );
      }
    });

    test('falls back to error for an unknown status', () {
      final connection = WhatsappConnection.fromJson({
        'id': 'c1',
        'fisioterapeuta_id': 'f1',
        'status': 'something-unexpected',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });

      expect(connection.status, WhatsappConnectionStatus.error);
    });

    test('keeps lastError available on the entity for diagnostics', () {
      final connection = WhatsappConnection.fromJson({
        'id': 'c1',
        'fisioterapeuta_id': 'f1',
        'status': 'error',
        'last_error': {'code': 'META_REJECTED', 'message': 'raw detail'},
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });

      expect(connection.lastError, {
        'code': 'META_REJECTED',
        'message': 'raw detail',
      });
    });

    test('parses a disconnected row with disconnectedAt', () {
      final connection = WhatsappConnection.fromJson({
        'id': 'c1',
        'fisioterapeuta_id': 'f1',
        'status': 'disconnected',
        'disconnected_at': '2026-02-01T00:00:00.000Z',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-02-01T00:00:00.000Z',
      });

      expect(connection.disconnectedAt, DateTime.parse('2026-02-01T00:00:00.000Z'));
    });
  });
}
