import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/core/theme/theme_cubit.dart';
import 'package:la_pelve/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pelve/features/profile/domain/entities/profile.dart';
import 'package:la_pelve/features/profile/domain/repositories/profile_repository.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:la_pelve/features/profile/presentation/pages/profile_page.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

const _longName = 'Dra. Maria Aparecida Fernandes de Albuquerque Souza';
const _longEmail =
    'maria.aparecida.fernandes.albuquerque@clinicaexemplo.com.br';

void main() {
  late _MockProfileRepository profiles;
  late _MockAuthRepository auth;

  Profile profile({
    String name = 'Dra. Ana',
    String email = 'ana@exemplo.com',
  }) => Profile(
    id: 'p1',
    name: name,
    crefito: 'CREFITO-3/12345',
    phone: '',
    email: email,
  );

  /// Rotas falsas: cada destino vira um texto "ROTA <path>" para os testes
  /// verificarem a navegação sem montar as telas reais.
  Future<void> pumpProfile(
    WidgetTester tester, {
    Profile? loaded,
    Size size = const Size(390, 1000),
    double textScale = 1,
    bool settle = true,
    Future<Result<Profile>>? gate,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    when(
      () => profiles.getCurrent(),
    ).thenAnswer((_) => gate ?? Future.value(Success(loaded ?? profile())));
    sl.registerSingleton<ProfileCubit>(ProfileCubit(profiles));
    sl.registerSingleton<AuthRepository>(auth);

    GoRoute fake(String path) => GoRoute(
      path: path,
      builder: (_, _) => Scaffold(body: Text('ROTA $path')),
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ProfilePage()),
        fake('/perfil/editar-nome'),
        fake('/perfil/tema'),
        fake('/perfil/idioma'),
        fake('/perfil/biometria'),
        fake('/perfil/alterar-senha'),
        fake('/perfil/whatsapp'),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  setUp(() {
    profiles = _MockProfileRepository();
    auth = _MockAuthRepository();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('mostra loading enquanto o perfil carrega', (tester) async {
    final gate = Completer<Result<Profile>>();
    await pumpProfile(tester, gate: gate.future, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AppSection), findsNothing);

    gate.complete(Success(profile()));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AppSection), findsNWidgets(3));
  });

  testWidgets('header mostra nome e e-mail e há 3 painéis', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Gerencie seu perfil'), findsOneWidget);
    // Nome e e-mail aparecem no header e na linha do painel profissional.
    expect(find.text('Dra. Ana'), findsNWidgets(2));
    expect(find.text('ana@exemplo.com'), findsNWidgets(2));
    expect(find.text('CREFITO-3/12345'), findsOneWidget);

    expect(find.byType(AppSection), findsNWidgets(3));
    expect(find.text('PERFIL PROFISSIONAL'), findsOneWidget);
    expect(find.text('PREFERÊNCIAS'), findsOneWidget);
    expect(find.text('CONTA'), findsOneWidget);
  });

  testWidgets(
    'nome e e-mail longos não usam ellipsis e não estouram em 360/1.3',
    (tester) async {
      await pumpProfile(
        tester,
        loaded: profile(name: _longName, email: _longEmail),
        size: const Size(360, 800),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      for (final text in tester.widgetList<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == _longName || w.data == _longEmail),
        ),
      )) {
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
      expect(find.text(_longName), findsWidgets);
      expect(find.text(_longEmail), findsWidgets);
    },
  );

  Future<void> expectNavigates(
    WidgetTester tester,
    Finder tap,
    String route,
  ) async {
    await tester.ensureVisible(tap);
    await tester.tap(tap);
    await tester.pumpAndSettle();
    expect(find.text('ROTA $route'), findsOneWidget);
  }

  testWidgets('Nome abre /perfil/editar-nome', (tester) async {
    await pumpProfile(tester);
    await expectNavigates(
      tester,
      find.widgetWithText(InkWell, 'Nome'),
      '/perfil/editar-nome',
    );
  });

  testWidgets('Tema, Idioma, Alterar senha e WhatsApp abrem as rotas atuais', (
    tester,
  ) async {
    final cases = {
      'Tema': '/perfil/tema',
      'Idioma': '/perfil/idioma',
      'Alterar senha': '/perfil/alterar-senha',
      'WhatsApp': '/perfil/whatsapp',
    };
    for (final entry in cases.entries) {
      await pumpProfile(tester);
      await expectNavigates(
        tester,
        find.widgetWithText(InkWell, entry.key),
        entry.value,
      );
      await sl.reset();
    }
  });

  testWidgets('Biometria aparece fora da web e abre /perfil/biometria', (
    tester,
  ) async {
    await pumpProfile(tester);
    expect(find.text('Biometria'), findsOneWidget);
    expect(find.text('Desativada'), findsOneWidget);
    await expectNavigates(
      tester,
      find.widgetWithText(InkWell, 'Biometria'),
      '/perfil/biometria',
    );
  });

  testWidgets('Alterar senha não mostra bullets e é só rótulo + chevron', (
    tester,
  ) async {
    await pumpProfile(tester);
    expect(find.textContaining('•'), findsNothing);
    final row = find.widgetWithText(InkWell, 'Alterar senha');
    expect(
      find.descendant(of: row, matching: find.byType(Text)),
      findsOneWidget,
    );
  });

  testWidgets('Sair da conta: confirma antes e só então chama signOut', (
    tester,
  ) async {
    when(() => auth.signOut()).thenAnswer((_) async => const Success(null));
    await pumpProfile(tester);

    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Deseja sair da sua conta?'), findsOneWidget);
    verifyNever(() => auth.signOut());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sair'));
    await tester.pumpAndSettle();
    verify(() => auth.signOut()).called(1);
  });

  testWidgets('cancelar o logout não chama signOut', (tester) async {
    await pumpProfile(tester);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(() => auth.signOut());
  });

  testWidgets(
    'Excluir minha conta: confirma antes e só então chama deleteAccount',
    (tester) async {
      when(
        () => auth.deleteAccount(),
      ).thenAnswer((_) async => const Success(null));
      await pumpProfile(tester);

      final delete = find.widgetWithText(TextButton, 'Excluir minha conta');
      // Fica fora dos painéis, no fim da tela.
      expect(
        find.descendant(of: find.byType(AppSection), matching: delete),
        findsNothing,
      );
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      verifyNever(() => auth.deleteAccount());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Excluir conta'));
      await tester.pumpAndSettle();
      verify(() => auth.deleteAccount()).called(1);
    },
  );
}
