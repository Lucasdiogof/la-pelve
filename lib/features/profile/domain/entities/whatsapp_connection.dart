import 'package:equatable/equatable.dart';
import 'package:la_pelve/shared/utils/enum_from_name.dart';

enum WhatsappConnectionStatus { pending, connected, disconnected, error }

enum WhatsappTemplateState { approved, pending, problem }

/// Os dois modelos de mensagem que o La Pelve usa.
const kWhatsappTemplateNames = ['appointment_confirmation', 'appointment_12h'];

/// Quais avisos automáticos a profissional quer enviar (profiles, migration 0043).
class WhatsappMessagePreferences extends Equatable {
  const WhatsappMessagePreferences({
    this.bookingNotice = true,
    this.reminder12h = true,
  });

  final bool bookingNotice;
  final bool reminder12h;

  @override
  List<Object?> get props => [bookingNotice, reminder12h];
}

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
    this.setupState,
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

  /// Progresso do onboarding gravado pelo servidor (sem segredos).
  final Map<String, dynamic>? setupState;
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
        setupState: json['setup_state'] as Map<String, dynamic>?,
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
    setupState,
    createdAt,
    updatedAt,
  ];

  /// Situação de cada modelo, a partir dos avisos da Meta (`setup_state.templates`,
  /// chave `nome:idioma`). Sem aviso registrado: conectada = verificada na conexão.
  WhatsappTemplateState templateState(String name) {
    final raw = setupState?['templates'];
    if (raw is Map) {
      final event = raw.entries
          .where(
            (e) => e.key is String && (e.key as String).startsWith('$name:'),
          )
          .map((e) => e.value is Map ? (e.value as Map)['event'] : null)
          .whereType<String>()
          .map((e) => e.toUpperCase())
          .firstOrNull;
      if (event != null) {
        if (event == 'APPROVED') return WhatsappTemplateState.approved;
        if (event == 'REJECTED' || event == 'DISABLED' || event == 'PAUSED') {
          return WhatsappTemplateState.problem;
        }
        return WhatsappTemplateState.pending;
      }
    }
    return status == WhatsappConnectionStatus.connected
        ? WhatsappTemplateState.approved
        : WhatsappTemplateState.pending;
  }
}

/// Resposta da ação `status` do `whatsapp-connect`: só o que a tela precisa
/// além da linha de `whatsapp_connections` (que continua sendo lida direto).
class WhatsappRemoteStatus extends Equatable {
  const WhatsappRemoteStatus({this.reason, this.tokenExpiresAt});

  /// Ex.: `token_expiring`, `token_invalid`, `credential_missing`.
  final String? reason;

  /// Só vem junto de `token_expiring`: quando a autorização da Meta vence.
  final DateTime? tokenExpiresAt;

  @override
  List<Object?> get props => [reason, tokenExpiresAt];
}
