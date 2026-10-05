import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/shared/utils/money_format.dart';

void main() {
  group('formatBrl', () {
    test('português usa ponto no milhar e vírgula nos centavos', () {
      expect(formatBrl(250), 'R\$ 250,00');
      expect(formatBrl(1450), 'R\$ 1.450,00');
      expect(formatBrl(1234567.8), 'R\$ 1.234.567,80');
      expect(formatBrl(0), 'R\$ 0,00');
      expect(formatBrl(0.5), 'R\$ 0,50');
    });

    test('espanhol segue a mesma convenção do português', () {
      expect(formatBrl(1450, language: AppLanguage.spanish), 'R\$ 1.450,00');
    });

    test('inglês troca só os separadores, a moeda continua BRL', () {
      expect(formatBrl(1450, language: AppLanguage.english), 'R\$ 1,450.00');
      expect(formatBrl(250.5, language: AppLanguage.english), 'R\$ 250.50');
    });

    test('arredonda a exibição para duas casas', () {
      expect(formatBrl(10.005 + 0.001), 'R\$ 10,01');
      expect(formatBrl(99.999), 'R\$ 100,00');
    });

    test('negativo mostra o sinal antes do símbolo', () {
      expect(formatBrl(-1450), '-R\$ 1.450,00');
      expect(formatBrl(-0.001), 'R\$ 0,00');
    });
  });
}
