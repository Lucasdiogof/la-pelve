import 'package:loader_overlay/loader_overlay.dart';
import 'package:fisioterapia_pelvica/core/router/app_router.dart';

void showAppLoading() {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null || ctx.loaderOverlay.visible) return;
  ctx.loaderOverlay.show();
}

void hideAppLoading() {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null || !ctx.loaderOverlay.visible) return;
  ctx.loaderOverlay.hide();
}
