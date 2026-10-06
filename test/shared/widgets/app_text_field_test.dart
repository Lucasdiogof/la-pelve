import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/shared/widgets/app_text_field.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppTextField.minLines', () {
    testWidgets('por padrão não define minLines (uso antigo inalterado)', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppTextField(label: 'Nome')));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, isNull);
      expect(field.maxLines, 1);
    });

    testWidgets('multilinha antiga (só maxLines) continua sem minLines', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AppTextField(label: 'Notas', maxLines: 4)),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, isNull);
      expect(field.maxLines, 4);
    });

    testWidgets('minLines informado chega ao TextField', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppTextField(label: 'Evolução', minLines: 6, maxLines: null),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 6);
      expect(field.maxLines, isNull);
    });

    testWidgets('campo de senha ignora minLines', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppTextField(label: 'Senha', obscureText: true, minLines: 6),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, isNull);
      expect(field.maxLines, 1);
    });
  });
}
