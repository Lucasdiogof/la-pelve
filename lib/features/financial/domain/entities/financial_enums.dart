import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

enum PaymentMethod { pix, cash, card, transfer, other }

extension PaymentMethodLabel on PaymentMethod {
  String label(AppLanguage language) => switch ((this, language)) {
    (PaymentMethod.pix, AppLanguage.portuguese) => 'Pix',
    (PaymentMethod.pix, AppLanguage.english) => 'Pix',
    (PaymentMethod.cash, AppLanguage.portuguese) => 'Dinheiro',
    (PaymentMethod.cash, AppLanguage.english) => 'Cash',
    (PaymentMethod.card, AppLanguage.portuguese) => 'Cartão',
    (PaymentMethod.card, AppLanguage.english) => 'Card',
    (PaymentMethod.transfer, AppLanguage.portuguese) => 'Transferência',
    (PaymentMethod.transfer, AppLanguage.english) => 'Bank transfer',
    (PaymentMethod.other, AppLanguage.portuguese) => 'Outro',
    (PaymentMethod.other, AppLanguage.english) => 'Other',
  };
}

enum PaymentStatus { paid, pending, partial, other }

extension PaymentStatusLabel on PaymentStatus {
  String label(AppLanguage language) => switch ((this, language)) {
    (PaymentStatus.paid, AppLanguage.portuguese) => 'Pago',
    (PaymentStatus.paid, AppLanguage.english) => 'Paid',
    (PaymentStatus.pending, AppLanguage.portuguese) => 'Pendente',
    (PaymentStatus.pending, AppLanguage.english) => 'Pending',
    (PaymentStatus.partial, AppLanguage.portuguese) => 'Parcial',
    (PaymentStatus.partial, AppLanguage.english) => 'Partial',
    (PaymentStatus.other, AppLanguage.portuguese) => 'Outro',
    (PaymentStatus.other, AppLanguage.english) => 'Other',
  };
}
