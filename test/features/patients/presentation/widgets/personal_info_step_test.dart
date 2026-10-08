import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_cubit.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/personal_info_step.dart';

void main() {
  const invalidPhoneError = 'Informe um telefone válido.';

  Future<void> pumpStep(WidgetTester tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final cubit = PatientFormCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider.value(value: cubit),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocBuilder<PatientFormCubit, PatientFormState>(
                builder: (context, state) => PersonalInfoStep(
                  patient: state.patient,
                  onChanged: cubit.updatePatient,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder phoneField() => find.byType(TextField).at(3);

  testWidgets('número incompleto não mostra erro enquanto o campo tem foco', (
    tester,
  ) async {
    await pumpStep(tester);
    await tester.enterText(phoneField(), '6299999');
    await tester.pump();

    expect(find.text(invalidPhoneError), findsNothing);
  });

  testWidgets('ao perder o foco com número inválido, o erro aparece no campo '
      'e some ao voltar a editar', (tester) async {
    await pumpStep(tester);
    await tester.enterText(phoneField(), '6299999');
    await tester.pump();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(find.text(invalidPhoneError), findsOneWidget);

    await tester.tap(phoneField());
    await tester.pump();
    expect(find.text(invalidPhoneError), findsNothing);
  });

  testWidgets('telefone vazio não mostra erro, nem depois de perder o foco', (
    tester,
  ) async {
    await pumpStep(tester);
    await tester.tap(phoneField());
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(find.text(invalidPhoneError), findsNothing);
  });

  testWidgets(
    'telefone fixo válido não mostra erro e não habilita o WhatsApp',
    (tester) async {
      await pumpStep(tester);
      await tester.enterText(phoneField(), '6232221111');
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(find.text(invalidPhoneError), findsNothing);
      final whatsapp = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(whatsapp.onChanged, isNull);
      expect(find.text('Receber lembretes pelo WhatsApp'), findsOneWidget);
    },
  );
}
