import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/services/biometric_service.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/core/theme/theme_cubit.dart';
import 'package:la_pelve/features/profile/presentation/pages/biometric_settings_page.dart';
import 'package:la_pelve/features/profile/presentation/pages/language_settings_page.dart';
import 'package:la_pelve/features/profile/presentation/pages/theme_settings_page.dart';
import 'package:la_pelve/features/profile/presentation/widgets/profile_option_row.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';

class _MockBiometricService extends Mock implements BiometricService {}

const _bioKey = 'biometria_enabled';

/// Store em memória cuja leitura só termina quando [gate] completa: segura o
/// carregamento da preferência para o teste enxergar o estado de loading.
class _GatedStore extends InMemorySharedPreferencesStore {
  _GatedStore(this.gate) : super.empty();

  final Future<void> gate;

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    await gate;
    return super.getAllWithParameters(parameters);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    ThemeCubit? theme,
    LocaleCubit? locale,
    bool settle = true,
  }) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: locale ?? LocaleCubit()),
          BlocProvider.value(value: theme ?? ThemeCubit()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: page),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// Títulos das opções marcadas como selecionadas.
  List<String> selectedOptions(WidgetTester tester) => [
    for (final row in tester.widgetList<ProfileOptionRow>(
      find.byType(ProfileOptionRow),
    ))
      if (row.selected) row.title,
  ];

  bool switchValue(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value;

  group('Tema', () {
    testWidgets('mostra as 3 opções num painel único, com 1 marcada', (
      tester,
    ) async {
      await pump(tester, const ThemeSettingsPage());

      expect(find.text('Automático'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
      expect(find.byType(AppSection), findsOneWidget);
      expect(find.byType(ProfileOptionRow), findsNWidgets(3));
      expect(find.byType(Card), findsNothing);
      expect(selectedOptions(tester), ['Automático']);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tocar em cada opção troca o ThemeCubit e move a marca', (
      tester,
    ) async {
      final theme = ThemeCubit();
      await pump(tester, const ThemeSettingsPage(), theme: theme);

      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();
      expect(theme.state, ThemeMode.dark);
      expect(selectedOptions(tester), ['Escuro']);

      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();
      expect(theme.state, ThemeMode.light);
      expect(selectedOptions(tester), ['Claro']);

      await tester.tap(find.text('Automático'));
      await tester.pumpAndSettle();
      expect(theme.state, ThemeMode.system);
      expect(selectedOptions(tester), ['Automático']);
    });
  });

  group('Idioma', () {
    testWidgets('mostra os idiomas de AppLanguage.values, com 1 marcado', (
      tester,
    ) async {
      await pump(tester, const LanguageSettingsPage());

      for (final language in AppLanguage.values) {
        expect(find.text(language.label), findsOneWidget);
      }
      expect(
        find.byType(ProfileOptionRow),
        findsNWidgets(AppLanguage.values.length),
      );
      expect(find.byType(AppSection), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(selectedOptions(tester), [AppLanguage.portuguese.label]);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tocar troca pelo LocaleCubit e move a marca', (tester) async {
      final locale = LocaleCubit();
      await pump(tester, const LanguageSettingsPage(), locale: locale);

      await tester.tap(find.text(AppLanguage.english.label));
      await tester.pumpAndSettle();
      expect(locale.state, AppLanguage.english);
      expect(selectedOptions(tester), [AppLanguage.english.label]);

      await tester.tap(find.text(AppLanguage.spanish.label));
      await tester.pumpAndSettle();
      expect(locale.state, AppLanguage.spanish);
      expect(selectedOptions(tester), [AppLanguage.spanish.label]);
    });
  });

  group('ProfileOptionRow', () {
    testWidgets('mantém a Semantics de seleção da opção atual', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const ThemeSettingsPage());

      bool isSelected(String label) => tester
          .getSemantics(find.text(label))
          // ignore: deprecated_member_use
          .hasFlag(SemanticsFlag.isSelected);

      expect(isSelected('Automático'), isTrue);
      expect(isSelected('Claro'), isFalse);
      handle.dispose();
    });
  });

  group('Biometria', () {
    late _MockBiometricService service;

    setUp(() {
      service = _MockBiometricService();
      sl.registerSingleton<BiometricService>(service);
    });

    Future<bool> stored() async =>
        (await SharedPreferences.getInstance()).getBool(_bioKey) ?? false;

    testWidgets('mostra loading enquanto a preferência carrega', (
      tester,
    ) async {
      final gate = Completer<void>();
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _GatedStore(gate.future);
      await pump(tester, const BiometricSettingsPage(), settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('estado desligado, em painel único', (tester) async {
      await pump(tester, const BiometricSettingsPage());
      expect(switchValue(tester), isFalse);
      expect(find.byType(AppSection), findsOneWidget);
      expect(find.text('Entrar com biometria'), findsOneWidget);
    });

    testWidgets('estado ligado vem da preferência salva', (tester) async {
      SharedPreferences.setMockInitialValues({_bioKey: true});
      await pump(tester, const BiometricSettingsPage());
      expect(switchValue(tester), isTrue);
    });

    testWidgets('desligar grava direto, sem checar nem autenticar', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({_bioKey: true});
      await pump(tester, const BiometricSettingsPage());

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(await stored(), isFalse);
      expect(switchValue(tester), isFalse);
      verifyNever(() => service.isDeviceSupported());
      verifyNever(() => service.authenticate(any()));
    });

    testWidgets('ligar: disponibilidade -> autenticação -> persistência', (
      tester,
    ) async {
      when(() => service.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => service.authenticate(any())).thenAnswer((_) async => true);
      await pump(tester, const BiometricSettingsPage());

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      verifyInOrder([
        () => service.isDeviceSupported(),
        () => service.authenticate(
          'Confirme sua identidade para ativar a biometria',
        ),
      ]);
      expect(await stored(), isTrue);
      expect(switchValue(tester), isTrue);
    });

    testWidgets('dispositivo não suportado: mostra o erro e não persiste', (
      tester,
    ) async {
      when(() => service.isDeviceSupported()).thenAnswer((_) async => false);
      await pump(tester, const BiometricSettingsPage());

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      verifyNever(() => service.authenticate(any()));
      expect(await stored(), isFalse);
      expect(switchValue(tester), isFalse);
      // O bottom sheet de erro existente aparece.
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('autenticação cancelada: não persiste e nada muda', (
      tester,
    ) async {
      when(() => service.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => service.authenticate(any())).thenAnswer((_) async => false);
      await pump(tester, const BiometricSettingsPage());

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(await stored(), isFalse);
      expect(switchValue(tester), isFalse);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });
}
