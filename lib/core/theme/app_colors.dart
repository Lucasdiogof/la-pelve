import 'package:flutter/material.dart';

/// Tokens de cor do Design System V2.
///
/// O vinho ([primary]) é a única cor de marca; o resto é neutro quente.
/// [success], [danger] e [warning] só aparecem quando carregam significado
/// (status, erro, ação destrutiva), nunca como decoração.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.primary,
    required this.primaryStrong,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.border,
    required this.borderStrong,
    required this.success,
    required this.danger,
    required this.warning,
  });

  /// Fundo das telas.
  final Color background;

  /// Campos, grupos, sheets, barra inferior.
  final Color surface;

  /// Estados pressionados/selecionados neutros e faixas discretas.
  final Color surfaceMuted;

  final Color textPrimary;
  final Color textSecondary;

  /// Placeholder e "Não informado". Mantém >= 4.5:1 em [surface],
  /// [background] e [surfaceMuted].
  final Color textHint;

  final Color primary;

  /// Variante de [primary] para estado pressionado.
  final Color primaryStrong;

  /// Fundo de seleção e avatar sem foto. Usar com parcimônia.
  final Color primaryContainer;
  final Color onPrimary;
  final Color onPrimaryContainer;

  /// Divisores e contorno de grupos (decorativo).
  final Color border;

  /// Contorno funcional de campos e botões secundários (>= 3:1).
  final Color borderStrong;

  final Color success;
  final Color danger;
  final Color warning;

  static const light = AppColors(
    background: Color(0xFFFAF8F7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF3F0EF),
    textPrimary: Color(0xFF292326),
    textSecondary: Color(0xFF70676B),
    textHint: Color(0xFF736A6E),
    primary: Color(0xFF74475C),
    primaryStrong: Color(0xFF573344),
    primaryContainer: Color(0xFFF1E9ED),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF3F2533),
    border: Color(0xFFE8E1E4),
    borderStrong: Color(0xFF958B90),
    success: Color(0xFF4D6B5C),
    danger: Color(0xFFA63D40),
    warning: Color(0xFF805D12),
  );

  static const dark = AppColors(
    background: Color(0xFF161314),
    surface: Color(0xFF1F1B1D),
    surfaceMuted: Color(0xFF272225),
    textPrimary: Color(0xFFECE6E8),
    textSecondary: Color(0xFFA69EA2),
    textHint: Color(0xFF958D91),
    primary: Color(0xFFC99AAE),
    primaryStrong: Color(0xFFDDB8C8),
    primaryContainer: Color(0xFF3A2A31),
    onPrimary: Color(0xFF2A1720),
    onPrimaryContainer: Color(0xFFF1DDE6),
    border: Color(0xFF332C30),
    borderStrong: Color(0xFF726A6E),
    success: Color(0xFF8FB8A0),
    danger: Color(0xFFE59A9C),
    warning: Color(0xFFD9B36A),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? primary,
    Color? primaryStrong,
    Color? primaryContainer,
    Color? onPrimary,
    Color? onPrimaryContainer,
    Color? border,
    Color? borderStrong,
    Color? success,
    Color? danger,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      primary: primary ?? this.primary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textHint: l(textHint, other.textHint),
      primary: l(primary, other.primary),
      primaryStrong: l(primaryStrong, other.primaryStrong),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimary: l(onPrimary, other.onPrimary),
      onPrimaryContainer: l(onPrimaryContainer, other.onPrimaryContainer),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      warning: l(warning, other.warning),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
