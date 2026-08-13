enum PaymentMethod { pix, cash, card, transfer, other }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.pix => 'Pix',
    PaymentMethod.cash => 'Dinheiro',
    PaymentMethod.card => 'Cartão',
    PaymentMethod.transfer => 'Transferência',
    PaymentMethod.other => 'Outro',
  };
}

enum PaymentStatus { paid, pending, partial, other }

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.paid => 'Pago',
    PaymentStatus.pending => 'Pendente',
    PaymentStatus.partial => 'Parcial',
    PaymentStatus.other => 'Outro',
  };
}
