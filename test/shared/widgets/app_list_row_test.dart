import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';

void main() {
  // Título longo o bastante para estourar 2 linhas numa tela estreita.
  const longTitle =
      'Maria Aparecida Fernandes de Albuquerque Souza Pereira Gonçalves';

  Future<void> pumpRow(WidgetTester tester, AppListRow row) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: row),
      ),
    );
  }

  test('o padrão de titleMaxLines continua sendo 2', () {
    expect(const AppListRow(title: 'x').titleMaxLines, 2);
  });

  testWidgets('sem passar titleMaxLines o título corta em 2 linhas', (
    tester,
  ) async {
    await pumpRow(
      tester,
      const AppListRow(
        title: longTitle,
        leading: AppInitialAvatar(name: 'M'),
        trailing: Icon(Icons.chevron_right),
      ),
    );

    expect(tester.widget<Text>(find.text(longTitle)).maxLines, 2);
    expect(
      tester
          .renderObject<RenderParagraph>(find.text(longTitle))
          .didExceedMaxLines,
      isTrue,
      reason: 'nome muito longo é cortado com reticências no padrão',
    );
  });

  testWidgets('titleMaxLines: 3 libera uma linha a mais', (tester) async {
    await pumpRow(
      tester,
      const AppListRow(
        title: longTitle,
        leading: AppInitialAvatar(name: 'M'),
        trailing: Icon(Icons.chevron_right),
        titleMaxLines: 3,
      ),
    );
    final threeLines = tester.getSize(find.text(longTitle)).height;
    expect(tester.widget<Text>(find.text(longTitle)).maxLines, 3);

    await pumpRow(
      tester,
      const AppListRow(
        title: longTitle,
        leading: AppInitialAvatar(name: 'M'),
        trailing: Icon(Icons.chevron_right),
      ),
    );
    final twoLines = tester.getSize(find.text(longTitle)).height;

    expect(threeLines, greaterThan(twoLines));
  });

  testWidgets('título que cabe em 2 linhas não muda com o parâmetro', (
    tester,
  ) async {
    const shortTitle = 'Maria Aparecida';
    await pumpRow(tester, const AppListRow(title: shortTitle));
    final padrao = tester.getSize(find.text(shortTitle));

    await pumpRow(
      tester,
      const AppListRow(title: shortTitle, titleMaxLines: 3),
    );
    expect(tester.getSize(find.text(shortTitle)), padrao);
  });
}
