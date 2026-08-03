import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fisioterapia_pelvica/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('HomePage renders app name in the AppBar', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text('Fisioterapia Pélvica'), findsOneWidget);
  });
}
