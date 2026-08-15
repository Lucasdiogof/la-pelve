import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// On the web the browser already owns back navigation: WebKit's own
// edge-swipe drives window.history, which go_router mirrors. Letting Flutter
// also install its Cupertino interactive back gesture means one finger drag
// runs two competing pop animations, so web pages render without a Flutter
// transition. Native builds keep the platform-adaptive one.
Page<void> appPage(GoRouterState state, Widget child) => kIsWeb
    ? NoTransitionPage<void>(key: state.pageKey, child: child)
    : MaterialPage<void>(key: state.pageKey, child: child);

// Same reasoning as appPage, for the screens still pushed imperatively with
// Navigator.push instead of going through the router.
Route<T> appRoute<T>(Widget child) => kIsWeb
    ? PageRouteBuilder<T>(
        pageBuilder: (_, _, _) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      )
    : MaterialPageRoute<T>(builder: (_) => child);
