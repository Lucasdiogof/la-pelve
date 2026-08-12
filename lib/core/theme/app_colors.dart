import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.primaryButton,
    required this.primaryButtonText,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.error,
    required this.success,
    required this.logoTeal,
    required this.logoPurple,
  });

  final Color background;
  final Color surface;
  final Color primary;
  final Color primaryButton;
  final Color primaryButtonText;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color error;
  final Color success;
  final Color logoTeal;
  final Color logoPurple;

  static const light = AppColors(
    background: Color(0xFFF8F3F6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF8C5C74),
    primaryButton: Color(0xFF72445B),
    primaryButtonText: Color(0xFFFFFFFF),
    secondary: Color(0xFFDDBFCC),
    textPrimary: Color(0xFF41343A),
    textSecondary: Color(0xFF715F67),
    textHint: Color(0xFFA8949D),
    border: Color(0xFFEADAE2),
    error: Color(0xFFB85C74),
    success: Color(0xFF6F927B),
    logoTeal: Color.fromRGBO(126, 183, 175, 1),
    logoPurple: Color.fromRGBO(208, 175, 237, 1),
  );

  static const dark = AppColors(
    background: Color(0xFF1C1418),
    surface: Color(0xFF251C21),
    primary: Color(0xFFC79AB0),
    primaryButton: Color(0xFFB07E97),
    primaryButtonText: Color(0xFF241B20),
    secondary: Color(0xFF4A343E),
    textPrimary: Color(0xFFF2E9ED),
    textSecondary: Color(0xFFC9B7C0),
    textHint: Color(0xFF8C7981),
    border: Color(0xFF3A2A31),
    error: Color(0xFFE08CA0),
    success: Color(0xFF8FB79B),
    logoTeal: Color.fromRGBO(126, 183, 175, 1),
    logoPurple: Color.fromRGBO(208, 175, 237, 1),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? primaryButton,
    Color? primaryButtonText,
    Color? secondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? error,
    Color? success,
    Color? logoTeal,
    Color? logoPurple,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      primaryButton: primaryButton ?? this.primaryButton,
      primaryButtonText: primaryButtonText ?? this.primaryButtonText,
      secondary: secondary ?? this.secondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      error: error ?? this.error,
      success: success ?? this.success,
      logoTeal: logoTeal ?? this.logoTeal,
      logoPurple: logoPurple ?? this.logoPurple,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryButton: Color.lerp(primaryButton, other.primaryButton, t)!,
      primaryButtonText: Color.lerp(
        primaryButtonText,
        other.primaryButtonText,
        t,
      )!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      logoTeal: Color.lerp(logoTeal, other.logoTeal, t)!,
      logoPurple: Color.lerp(logoPurple, other.logoPurple, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
