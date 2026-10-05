import 'package:flutter/material.dart';

/// Escala de espaçamento do Design System V2 (base 4).
///
/// Use sempre um destes valores; [gutter] é a margem lateral padrão das
/// telas.
abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;

  static const double gutter = s20;
}

/// Escala de raios do Design System V2.
///
/// - [xs] (6): badges, barras de progresso.
/// - [sm] (10): campos e botões.
/// - [md] (12): grupos de conteúdo ([AppSection]) e FAB.
/// - [lg] (16): topo de bottom sheets e dialogs.
///
/// Formas totalmente circulares ([CircleBorder]/[BoxShape.circle]) só para
/// avatar, puxador de sheet e elementos realmente circulares.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;

  /// Controles compactos (chip, segmented control). Exceção documentada à
  /// escala: 8 fica entre [xs] e [sm] para o controle não parecer pílula nem
  /// botão.
  static const double control = 8;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius lgTop = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}

/// Papéis tipográficos que não têm um slot com nome próprio no
/// [TextTheme] do Material.
///
/// A Poppins empacotada em `lib/assets/google_fonts/` não traz a feature
/// OpenType `tnum` (nem nenhuma outra): os dígitos são proporcionais. Por
/// isso [metric] e [time] não dependem de `FontFeature.tabularFigures()`;
/// quem precisa alinhar números em coluna usa largura fixa (ex.:
/// [AppTimeRow]) ou alinhamento à direita.
extension AppTypography on TextTheme {
  /// Rótulo de seção em caixa alta ("CONTA", "SEG, 05 OUT"). Quem usa
  /// aplica `toUpperCase()` no texto.
  TextStyle get overline => labelSmall!;

  /// Número de destaque (métricas, totais).
  TextStyle get metric => displaySmall!;

  /// Número de destaque secundário.
  TextStyle get metricSmall => titleLarge!;
}
