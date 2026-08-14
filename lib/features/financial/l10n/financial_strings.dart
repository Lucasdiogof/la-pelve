import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class FinancialStrings {
  const FinancialStrings(this.language);

  final AppLanguage language;

  String get pageTitle => switch (language) {
    AppLanguage.portuguese => 'Financeiro',
    AppLanguage.english => 'Financial',
  };

  String get pageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Lançamentos e relatórios',
    AppLanguage.english => 'Payments and reports',
  };

  String get registerPaymentFab => switch (language) {
    AppLanguage.portuguese => 'Registrar cobrança',
    AppLanguage.english => 'Add payment',
  };

  String get paymentsTab => switch (language) {
    AppLanguage.portuguese => 'Lançamentos',
    AppLanguage.english => 'Payments',
  };

  String get reportTab => switch (language) {
    AppLanguage.portuguese => 'Relatório',
    AppLanguage.english => 'Report',
  };

  String get emptyPaymentsTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhum lançamento',
    AppLanguage.english => 'No payments yet',
  };

  String get emptyPaymentsMessage => switch (language) {
    AppLanguage.portuguese => 'Nenhuma cobrança registrada ainda.',
    AppLanguage.english => 'No payments have been registered yet.',
  };

  String get deletePaymentTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir lançamento',
    AppLanguage.english => 'Delete payment',
  };

  String get deletePaymentDescription => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja excluir este lançamento? Essa ação não pode ser desfeita.',
    AppLanguage.english =>
      'Are you sure you want to delete this payment? This action cannot be undone.',
  };

  String get deleteLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir',
    AppLanguage.english => 'Delete',
  };

  String get formPageTitle => switch (language) {
    AppLanguage.portuguese => 'Registrar cobrança',
    AppLanguage.english => 'Add payment',
  };

  String get formPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Novo lançamento financeiro',
    AppLanguage.english => 'New payment entry',
  };

  String get editFormPageTitle => switch (language) {
    AppLanguage.portuguese => 'Editar lançamento',
    AppLanguage.english => 'Edit payment',
  };

  String get editFormPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Atualize os dados do lançamento',
    AppLanguage.english => 'Update the payment entry',
  };

  String get patientNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome do paciente',
    AppLanguage.english => 'Patient name',
  };

  String get selectRegisteredPatientTooltip => switch (language) {
    AppLanguage.portuguese => 'Selecionar paciente cadastrado',
    AppLanguage.english => 'Select a registered patient',
  };

  String get paymentDateHint => switch (language) {
    AppLanguage.portuguese => 'Data do pagamento',
    AppLanguage.english => 'Payment date',
  };

  String get amountPaidHint => switch (language) {
    AppLanguage.portuguese => 'Valor pago',
    AppLanguage.english => 'Amount paid',
  };

  String get notesHint => switch (language) {
    AppLanguage.portuguese => 'Observações',
    AppLanguage.english => 'Notes',
  };

  String get paymentMethodSectionTitle => switch (language) {
    AppLanguage.portuguese => 'FORMA DE PAGAMENTO',
    AppLanguage.english => 'PAYMENT METHOD',
  };

  String get whichPaymentMethodHint => switch (language) {
    AppLanguage.portuguese => 'Qual forma de pagamento',
    AppLanguage.english => 'Which payment method',
  };

  String get statusSectionTitle => switch (language) {
    AppLanguage.portuguese => 'STATUS',
    AppLanguage.english => 'STATUS',
  };

  String get whichStatusHint => switch (language) {
    AppLanguage.portuguese => 'Qual status',
    AppLanguage.english => 'Which status',
  };

  String get statusMinCharsError => switch (language) {
    AppLanguage.portuguese => 'Informe pelo menos 4 caracteres.',
    AppLanguage.english => 'Enter at least 4 characters.',
  };

  String get registerPaymentButton => switch (language) {
    AppLanguage.portuguese => 'Registrar pagamento',
    AppLanguage.english => 'Register payment',
  };

  String get paymentRegisteredSuccess => switch (language) {
    AppLanguage.portuguese => 'Lançamento registrado com sucesso.',
    AppLanguage.english => 'Payment registered successfully.',
  };

  String get paymentUpdatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Lançamento atualizado com sucesso.',
    AppLanguage.english => 'Payment updated successfully.',
  };

  String get periodLabel => switch (language) {
    AppLanguage.portuguese => 'Período',
    AppLanguage.english => 'Period',
  };

  String periodRange(String from, String to) => switch (language) {
    AppLanguage.portuguese => 'Período: $from a $to',
    AppLanguage.english => 'Period: $from to $to',
  };

  String get totalReceived => switch (language) {
    AppLanguage.portuguese => 'Total recebido',
    AppLanguage.english => 'Total received',
  };

  String monthName(int month) => switch (language) {
    AppLanguage.portuguese => switch (month) {
      1 => 'Janeiro',
      2 => 'Fevereiro',
      3 => 'Março',
      4 => 'Abril',
      5 => 'Maio',
      6 => 'Junho',
      7 => 'Julho',
      8 => 'Agosto',
      9 => 'Setembro',
      10 => 'Outubro',
      11 => 'Novembro',
      _ => 'Dezembro',
    },
    AppLanguage.english => switch (month) {
      1 => 'January',
      2 => 'February',
      3 => 'March',
      4 => 'April',
      5 => 'May',
      6 => 'June',
      7 => 'July',
      8 => 'August',
      9 => 'September',
      10 => 'October',
      11 => 'November',
      _ => 'December',
    },
  };
}
