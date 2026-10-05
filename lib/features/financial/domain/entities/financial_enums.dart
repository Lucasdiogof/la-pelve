import 'package:la_pelve/core/l10n/app_language.dart';

enum PaymentMethod { pix, cash, card, transfer, other }

extension PaymentMethodLabel on PaymentMethod {
  String label(AppLanguage language) => switch ((this, language)) {
    (PaymentMethod.pix, AppLanguage.portuguese) => 'Pix',
    (PaymentMethod.pix, AppLanguage.english) => 'Pix',
    (PaymentMethod.pix, AppLanguage.spanish) => 'Pix',
    (PaymentMethod.cash, AppLanguage.portuguese) => 'Dinheiro',
    (PaymentMethod.cash, AppLanguage.english) => 'Cash',
    (PaymentMethod.cash, AppLanguage.spanish) => 'Efectivo',
    (PaymentMethod.card, AppLanguage.portuguese) => 'Cartão',
    (PaymentMethod.card, AppLanguage.english) => 'Card',
    (PaymentMethod.card, AppLanguage.spanish) => 'Tarjeta',
    (PaymentMethod.transfer, AppLanguage.portuguese) => 'Transferência',
    (PaymentMethod.transfer, AppLanguage.english) => 'Bank transfer',
    (PaymentMethod.transfer, AppLanguage.spanish) => 'Transferencia bancaria',
    (PaymentMethod.other, AppLanguage.portuguese) => 'Outro',
    (PaymentMethod.other, AppLanguage.english) => 'Other',
    (PaymentMethod.other, AppLanguage.spanish) => 'Otro',
  };
}

enum PaymentStatus { paid, pending, partial, other }

extension PaymentStatusLabel on PaymentStatus {
  String label(AppLanguage language) => switch ((this, language)) {
    (PaymentStatus.paid, AppLanguage.portuguese) => 'Pago',
    (PaymentStatus.paid, AppLanguage.english) => 'Paid',
    (PaymentStatus.paid, AppLanguage.spanish) => 'Pagado',
    (PaymentStatus.pending, AppLanguage.portuguese) => 'Pendente',
    (PaymentStatus.pending, AppLanguage.english) => 'Pending',
    (PaymentStatus.pending, AppLanguage.spanish) => 'Pendiente',
    (PaymentStatus.partial, AppLanguage.portuguese) => 'Parcial',
    (PaymentStatus.partial, AppLanguage.english) => 'Partial',
    (PaymentStatus.partial, AppLanguage.spanish) => 'Parcial',
    (PaymentStatus.other, AppLanguage.portuguese) => 'Outro',
    (PaymentStatus.other, AppLanguage.english) => 'Other',
    (PaymentStatus.other, AppLanguage.spanish) => 'Otro',
  };
}
