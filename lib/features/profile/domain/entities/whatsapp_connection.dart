import 'package:equatable/equatable.dart';
import 'package:la_pelve/shared/utils/enum_from_name.dart';

enum WhatsappConnectionStatus { pending, connected, disconnected, error }

/// Conexão do WhatsApp Business do profissional autenticado
/// (`whatsapp_connections`, uma linha por `fisioterapeuta_id`).
///
/// Nunca contém token, App Secret nem nenhuma credencial da Meta — essa
/// tabela não guarda isso. [lastError] é só diagnóstico para suporte e
/// nunca deve ser exibido bruto na UI.
class WhatsappConnection extends Equatable {
  const WhatsappConnection({
    required this.id,
    required this.fisioterapeutaId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.wabaId,
    this.phoneNumberId,
    this.displayPhoneNumber,
    this.connectedAt,
    this.disconnectedAt,
    this.lastError,
  });

  final String id;
  final String fisioterapeutaId;
  final String? wabaId;
  final String? phoneNumberId;
  final String? displayPhoneNumber;
  final WhatsappConnectionStatus status;
  final DateTime? connectedAt;
  final DateTime? disconnectedAt;
  final Map<String, dynamic>? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WhatsappConnection.fromJson(Map<String, dynamic> json) =>
      WhatsappConnection(
        id: json['id'] as String,
        fisioterapeutaId: json['fisioterapeuta_id'] as String,
        wabaId: json['waba_id'] as String?,
        phoneNumberId: json['phone_number_id'] as String?,
        displayPhoneNumber: json['display_phone_number'] as String?,
        status:
            enumFromName(WhatsappConnectionStatus.values, json['status']) ??
            WhatsappConnectionStatus.error,
        connectedAt: json['connected_at'] == null
            ? null
            : DateTime.parse(json['connected_at'] as String),
        disconnectedAt: json['disconnected_at'] == null
            ? null
            : DateTime.parse(json['disconnected_at'] as String),
        lastError: json['last_error'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  @override
  List<Object?> get props => [
    id,
    fisioterapeutaId,
    wabaId,
    phoneNumberId,
    displayPhoneNumber,
    status,
    connectedAt,
    disconnectedAt,
    lastError,
    createdAt,
    updatedAt,
  ];
}
