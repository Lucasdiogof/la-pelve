enum FormaPagamento { pix, dinheiro, cartao, transferencia, outro }

extension FormaPagamentoLabel on FormaPagamento {
  String get label => switch (this) {
    FormaPagamento.pix => 'Pix',
    FormaPagamento.dinheiro => 'Dinheiro',
    FormaPagamento.cartao => 'Cartão',
    FormaPagamento.transferencia => 'Transferência',
    FormaPagamento.outro => 'Outro',
  };
}

enum StatusPagamento { pago, pendente, parcial, outro }

extension StatusPagamentoLabel on StatusPagamento {
  String get label => switch (this) {
    StatusPagamento.pago => 'Pago',
    StatusPagamento.pendente => 'Pendente',
    StatusPagamento.parcial => 'Parcial',
    StatusPagamento.outro => 'Outro',
  };
}
