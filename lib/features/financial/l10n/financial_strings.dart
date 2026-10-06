import 'package:la_pelve/core/l10n/app_language.dart';

class FinancialStrings {
  const FinancialStrings(this.language);

  final AppLanguage language;

  String get pageTitle => switch (language) {
    AppLanguage.portuguese => 'Financeiro',
    AppLanguage.english => 'Financial',
    AppLanguage.spanish => 'Finanzas',
  };

  String get pageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Lançamentos e relatórios',
    AppLanguage.english => 'Payments and reports',
    AppLanguage.spanish => 'Movimientos e informes',
  };

  String get registerPaymentFab => switch (language) {
    AppLanguage.portuguese => 'Registrar cobrança',
    AppLanguage.english => 'Add payment',
    AppLanguage.spanish => 'Registrar cobro',
  };

  String get paymentsTab => switch (language) {
    AppLanguage.portuguese => 'Lançamentos',
    AppLanguage.english => 'Payments',
    AppLanguage.spanish => 'Movimientos',
  };

  String get reportTab => switch (language) {
    AppLanguage.portuguese => 'Relatório',
    AppLanguage.english => 'Report',
    AppLanguage.spanish => 'Informe',
  };

  String get emptyPaymentsTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhum lançamento',
    AppLanguage.english => 'No payments yet',
    AppLanguage.spanish => 'Ningún movimiento',
  };

  String get emptyPaymentsMessage => switch (language) {
    AppLanguage.portuguese => 'Nenhuma cobrança registrada ainda.',
    AppLanguage.english => 'No payments have been registered yet.',
    AppLanguage.spanish => 'Aún no hay cobros registrados.',
  };

  String get deletePaymentTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir lançamento',
    AppLanguage.english => 'Delete payment',
    AppLanguage.spanish => 'Eliminar movimiento',
  };

  String get deletePaymentDescription => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja excluir este lançamento? Essa ação não pode ser desfeita.',
    AppLanguage.english =>
      'Are you sure you want to delete this payment? This action cannot be undone.',
    AppLanguage.spanish =>
      '¿Seguro que deseas eliminar este movimiento? Esta acción no se puede deshacer.',
  };

  String get deleteLabel => switch (language) {
    AppLanguage.portuguese => 'Excluir',
    AppLanguage.english => 'Delete',
    AppLanguage.spanish => 'Eliminar',
  };

  String get formPageTitle => switch (language) {
    AppLanguage.portuguese => 'Registrar cobrança',
    AppLanguage.english => 'Add payment',
    AppLanguage.spanish => 'Registrar cobro',
  };

  String get formPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Novo lançamento financeiro',
    AppLanguage.english => 'New payment entry',
    AppLanguage.spanish => 'Nuevo movimiento financiero',
  };

  String get editFormPageTitle => switch (language) {
    AppLanguage.portuguese => 'Editar lançamento',
    AppLanguage.english => 'Edit payment',
    AppLanguage.spanish => 'Editar movimiento',
  };

  String get editFormPageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Atualize os dados do lançamento',
    AppLanguage.english => 'Update the payment entry',
    AppLanguage.spanish => 'Actualiza los datos del movimiento',
  };

  String get patientNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome do paciente',
    AppLanguage.english => 'Patient name',
    AppLanguage.spanish => 'Nombre del paciente',
  };

  String get patientFieldLabel => switch (language) {
    AppLanguage.portuguese => 'Paciente',
    AppLanguage.english => 'Patient',
    AppLanguage.spanish => 'Paciente',
  };

  String get dateFieldLabel => switch (language) {
    AppLanguage.portuguese => 'Data',
    AppLanguage.english => 'Date',
    AppLanguage.spanish => 'Fecha',
  };

  String get amountFieldLabel => switch (language) {
    AppLanguage.portuguese => 'Valor',
    AppLanguage.english => 'Amount',
    AppLanguage.spanish => 'Monto',
  };

  String get statusFieldLabel => switch (language) {
    AppLanguage.portuguese => 'Status',
    AppLanguage.english => 'Status',
    AppLanguage.spanish => 'Estado',
  };

  String get paymentMethodFieldLabel => switch (language) {
    AppLanguage.portuguese => 'Forma de pagamento',
    AppLanguage.english => 'Payment method',
    AppLanguage.spanish => 'Forma de pago',
  };

  String get selectRegisteredPatientTooltip => switch (language) {
    AppLanguage.portuguese => 'Selecionar paciente cadastrado',
    AppLanguage.english => 'Select a registered patient',
    AppLanguage.spanish => 'Seleccionar paciente registrado',
  };

  String get paymentDateHint => switch (language) {
    AppLanguage.portuguese => 'Data do pagamento',
    AppLanguage.english => 'Payment date',
    AppLanguage.spanish => 'Fecha del pago',
  };

  String get amountPaidHint => switch (language) {
    AppLanguage.portuguese => 'Valor pago',
    AppLanguage.english => 'Amount paid',
    AppLanguage.spanish => 'Monto pagado',
  };

  String get notesHint => switch (language) {
    AppLanguage.portuguese => 'Observações',
    AppLanguage.english => 'Notes',
    AppLanguage.spanish => 'Observaciones',
  };

  String get paymentMethodSectionTitle => switch (language) {
    AppLanguage.portuguese => 'FORMA DE PAGAMENTO',
    AppLanguage.english => 'PAYMENT METHOD',
    AppLanguage.spanish => 'FORMA DE PAGO',
  };

  String get whichPaymentMethodHint => switch (language) {
    AppLanguage.portuguese => 'Qual forma de pagamento',
    AppLanguage.english => 'Which payment method',
    AppLanguage.spanish => 'Cuál forma de pago',
  };

  String get statusSectionTitle => switch (language) {
    AppLanguage.portuguese => 'STATUS',
    AppLanguage.english => 'STATUS',
    AppLanguage.spanish => 'ESTADO',
  };

  String get whichStatusHint => switch (language) {
    AppLanguage.portuguese => 'Qual status',
    AppLanguage.english => 'Which status',
    AppLanguage.spanish => 'Cuál estado',
  };

  String get statusMinCharsError => switch (language) {
    AppLanguage.portuguese => 'Informe pelo menos 4 caracteres.',
    AppLanguage.english => 'Enter at least 4 characters.',
    AppLanguage.spanish => 'Ingresa al menos 4 caracteres.',
  };

  String get registerPaymentButton => switch (language) {
    AppLanguage.portuguese => 'Registrar pagamento',
    AppLanguage.english => 'Register payment',
    AppLanguage.spanish => 'Registrar pago',
  };

  String get saveChangesButton => switch (language) {
    AppLanguage.portuguese => 'Salvar alterações',
    AppLanguage.english => 'Save changes',
    AppLanguage.spanish => 'Guardar cambios',
  };

  String get paymentRegisteredSuccess => switch (language) {
    AppLanguage.portuguese => 'Lançamento registrado com sucesso.',
    AppLanguage.english => 'Payment registered successfully.',
    AppLanguage.spanish => 'Movimiento registrado con éxito.',
  };

  String get paymentUpdatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Lançamento atualizado com sucesso.',
    AppLanguage.english => 'Payment updated successfully.',
    AppLanguage.spanish => 'Movimiento actualizado con éxito.',
  };

  String get periodLabel => switch (language) {
    AppLanguage.portuguese => 'Período',
    AppLanguage.english => 'Period',
    AppLanguage.spanish => 'Período',
  };

  String periodRange(String from, String to) => switch (language) {
    AppLanguage.portuguese => 'Período: $from a $to',
    AppLanguage.english => 'Period: $from to $to',
    AppLanguage.spanish => 'Período: $from a $to',
  };

  String get totalReceived => switch (language) {
    AppLanguage.portuguese => 'Total recebido',
    AppLanguage.english => 'Total received',
    AppLanguage.spanish => 'Total recibido',
  };

  String get unnamedEntryFallback => switch (language) {
    AppLanguage.portuguese => 'Sem nome',
    AppLanguage.english => 'No name',
    AppLanguage.spanish => 'Sin nombre',
  };

  String monthYearLabel(DateTime month) => switch (language) {
    AppLanguage.portuguese => '${monthName(month.month)} de ${month.year}',
    AppLanguage.english => '${monthName(month.month)} ${month.year}',
    AppLanguage.spanish => '${monthName(month.month)} de ${month.year}',
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
    AppLanguage.spanish => switch (month) {
      1 => 'Enero',
      2 => 'Febrero',
      3 => 'Marzo',
      4 => 'Abril',
      5 => 'Mayo',
      6 => 'Junio',
      7 => 'Julio',
      8 => 'Agosto',
      9 => 'Septiembre',
      10 => 'Octubre',
      11 => 'Noviembre',
      _ => 'Diciembre',
    },
  };
}
