/// Situação de um lembrete do WhatsApp de uma consulta (linha de
/// `whatsapp_messages`), só com o que a fisioterapeuta precisa ver: tipo,
/// status e instantes. Sem telefone, wamid, consentimento ou erro bruto.
class AppointmentReminder {
  const AppointmentReminder({
    required this.reminderType,
    required this.status,
    required this.scheduledFor,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.failedAt,
    this.createdAt,
  });

  /// appointment_12h (pedido de confirmação), appointment_confirmation (aviso
  /// de agendamento) ou appointment_rescheduled (aviso de remarcação).
  final String reminderType;

  /// scheduled, processing, sent, delivered, read, failed ou cancelled.
  final String status;
  final DateTime scheduledFor;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? failedAt;
  final DateTime? createdAt;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  factory AppointmentReminder.fromJson(Map<String, dynamic> json) {
    return AppointmentReminder(
      reminderType: json['reminder_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      scheduledFor: _date(json['scheduled_for']) ?? DateTime.now(),
      sentAt: _date(json['sent_at']),
      deliveredAt: _date(json['delivered_at']),
      readAt: _date(json['read_at']),
      failedAt: _date(json['failed_at']),
      createdAt: _date(json['created_at']),
    );
  }

  /// Instante mais relevante para o status atual.
  DateTime? get statusAt => switch (status) {
    'read' => readAt,
    'delivered' => deliveredAt,
    'sent' => sentAt,
    'failed' => failedAt,
    'scheduled' => scheduledFor,
    _ => null,
  };
}

/// Um lembrete por tipo: o mais recente (remarcação cria uma linha nova).
List<AppointmentReminder> latestRemindersByType(List<AppointmentReminder> all) {
  const order = [
    'appointment_confirmation',
    'appointment_rescheduled',
    'appointment_12h',
  ];
  final byType = <String, AppointmentReminder>{};
  for (final reminder in all) {
    if (!order.contains(reminder.reminderType)) continue;
    final current = byType[reminder.reminderType];
    final created = reminder.createdAt ?? reminder.scheduledFor;
    final currentCreated = current?.createdAt ?? current?.scheduledFor;
    if (current == null || created.isAfter(currentCreated!)) {
      byType[reminder.reminderType] = reminder;
    }
  }
  return [
    for (final type in order)
      if (byType[type] != null) byType[type]!,
  ];
}
