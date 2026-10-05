import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

class AppTheme {
  const AppTheme._();

  static const _fontFamily = 'Poppins';

  static ThemeData get light => _themeFor(AppColors.light, Brightness.light);

  static ThemeData get dark => _themeFor(AppColors.dark, Brightness.dark);

  /// ColorScheme completo: nenhum slot fica com o roxo/lilás do seed padrão
  /// do Material 3.
  static ColorScheme _schemeFor(AppColors c, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      primaryFixed: c.primaryContainer,
      primaryFixedDim: c.primaryContainer,
      onPrimaryFixed: c.onPrimaryContainer,
      onPrimaryFixedVariant: c.onPrimaryContainer,
      // Secundária neutra: chips, indicadores e afins não ganham uma
      // segunda cor de marca.
      secondary: c.textSecondary,
      onSecondary: c.surface,
      secondaryContainer: c.primaryContainer,
      onSecondaryContainer: c.onPrimaryContainer,
      secondaryFixed: c.primaryContainer,
      secondaryFixedDim: c.primaryContainer,
      onSecondaryFixed: c.onPrimaryContainer,
      onSecondaryFixedVariant: c.onPrimaryContainer,
      tertiary: c.success,
      onTertiary: c.surface,
      tertiaryContainer: c.surfaceMuted,
      onTertiaryContainer: c.textPrimary,
      tertiaryFixed: c.surfaceMuted,
      tertiaryFixedDim: c.surfaceMuted,
      onTertiaryFixed: c.textPrimary,
      onTertiaryFixedVariant: c.textPrimary,
      error: c.danger,
      onError: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF3A1214),
      errorContainer: isLight
          ? const Color(0xFFF6E3E3)
          : const Color(0xFF4A2023),
      onErrorContainer: isLight
          ? const Color(0xFF5A1E20)
          : const Color(0xFFF6D6D7),
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceDim: isLight ? const Color(0xFFEDE9E8) : c.background,
      surfaceBright: isLight ? c.surface : c.surfaceMuted,
      surfaceContainerLowest: isLight ? c.surface : c.background,
      surfaceContainerLow: isLight ? c.background : const Color(0xFF1B1719),
      surfaceContainer: isLight ? const Color(0xFFF6F3F2) : c.surface,
      surfaceContainerHigh: c.surfaceMuted,
      surfaceContainerHighest: isLight
          ? const Color(0xFFEDE9E8)
          : const Color(0xFF2F292C),
      outline: c.borderStrong,
      outlineVariant: c.border,
      inverseSurface: isLight
          ? const Color(0xFF2F2A2C)
          : const Color(0xFFECE6E8),
      onInverseSurface: isLight
          ? const Color(0xFFF3EEF0)
          : const Color(0xFF292326),
      inversePrimary: isLight
          ? AppColors.dark.primary
          : AppColors.light.primary,
      scrim: const Color(0xFF000000),
      shadow: const Color(0xFF000000),
      // Sem tint de elevação do M3: superfícies elevadas não ficam rosadas.
      surfaceTint: Colors.transparent,
    );
  }

  static TextTheme _textThemeFor(AppColors c, Brightness brightness) {
    // Poppins vem da família declarada no pubspec (todos os pesos), não do
    // google_fonts: o google_fonts prende cada estilo a um arquivo de peso
    // único e um fontWeight aplicado depois virava negrito sintético.
    final poppins = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: _fontFamily,
    ).textTheme;
    TextStyle s(
      TextStyle? from,
      double size,
      double lineHeight,
      FontWeight weight, {
      double letterSpacing = 0,
    }) => from!.copyWith(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );

    return poppins
        .copyWith(
          // pageTitle
          headlineSmall: s(poppins.headlineSmall, 22, 28, FontWeight.w600),
          // metricSmall / títulos de sheet
          titleLarge: s(poppins.titleLarge, 20, 26, FontWeight.w600),
          // sectionTitle
          titleMedium: s(poppins.titleMedium, 16, 22, FontWeight.w600),
          // tabs
          titleSmall: s(poppins.titleSmall, 14, 20, FontWeight.w600),
          // body
          bodyLarge: s(poppins.bodyLarge, 15, 22, FontWeight.w400),
          // bodySecondary (também é o DefaultTextStyle do Material)
          bodyMedium: s(poppins.bodyMedium, 13, 18, FontWeight.w400),
          // caption
          bodySmall: s(poppins.bodySmall, 12, 16, FontWeight.w400),
          // button
          labelLarge: s(poppins.labelLarge, 15, 20, FontWeight.w600),
          // label de campo
          labelMedium: s(poppins.labelMedium, 13, 18, FontWeight.w500),
          // overline
          labelSmall: s(
            poppins.labelSmall,
            11,
            16,
            FontWeight.w600,
            letterSpacing: 0.8,
          ),
          // metric
          displaySmall: s(poppins.displaySmall, 28, 34, FontWeight.w600),
        )
        .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
  }

  static ThemeData _themeFor(AppColors c, Brightness brightness) {
    final scheme = _schemeFor(c, brightness);
    final textTheme = _textThemeFor(c, brightness);

    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: BorderSide(color: c.borderStrong),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      splashFactory: InkRipple.splashFactory,
      extensions: [c],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.25),
        selectionHandleColor: c.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: c.textHint),
        errorStyle: textTheme.bodySmall?.copyWith(color: c.danger),
        errorMaxLines: 3,
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.textPrimary.withValues(alpha: 0.12),
          disabledForegroundColor: c.textPrimary.withValues(alpha: 0.38),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          backgroundColor: c.surface,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          side: BorderSide(color: c.borderStrong),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        extendedTextStyle: textTheme.labelLarge,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        overlayColor: WidgetStatePropertyAll(
          c.textPrimary.withValues(alpha: 0.06),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.bodySmall!.copyWith(
                  color: c.primary,
                  fontWeight: FontWeight.w600,
                )
              : textTheme.bodySmall!.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.primary,
        unselectedLabelColor: c.textSecondary,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        dividerColor: c.border,
        dividerHeight: 1,
        overlayColor: WidgetStatePropertyAll(
          c.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        selectedColor: c.primary,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
        ),
        minVerticalPadding: AppSpacing.s12,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primary,
        disabledColor: c.surfaceMuted,
        checkmarkColor: c.onPrimary,
        side: BorderSide(color: c.borderStrong),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
        // Texto do chip selecionado sobre o fundo primary precisa de
        // onPrimary (o padrão do M3 usaria onSecondaryContainer).
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c.onPrimary
                : c.textPrimary,
          ),
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: c.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        elevation: 0,
        pressElevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return states.contains(WidgetState.selected)
                ? c.surface
                : c.borderStrong.withValues(alpha: 0.5);
          }
          return states.contains(WidgetState.selected)
              ? c.onPrimary
              : c.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return states.contains(WidgetState.selected)
                ? c.primary.withValues(alpha: 0.38)
                : c.surfaceMuted;
          }
          return states.contains(WidgetState.selected)
              ? c.primary
              : c.surfaceMuted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : (states.contains(WidgetState.disabled)
                    ? c.border
                    : c.borderStrong),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: c.borderStrong, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.border,
        thumbColor: c.primary,
        // Sem sombra no thumb: o controle já se destaca pela cor.
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 10,
          elevation: 0,
          pressedElevation: 0,
        ),
        overlayColor: c.primary.withValues(alpha: 0.12),
        activeTickMarkColor: c.onPrimary.withValues(alpha: 0.6),
        inactiveTickMarkColor: c.borderStrong,
        valueIndicatorColor: c.primary,
        valueIndicatorTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
        circularTrackColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: Colors.black.withValues(alpha: 0.4),
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: c.textSecondary),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        headerBackgroundColor: c.surface,
        headerForegroundColor: c.textPrimary,
        dividerColor: c.border,
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.onPrimary : c.primary,
        ),
        todayBorder: BorderSide(color: c.primary),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.primary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: c.primary),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        hourMinuteShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.smAll,
        ),
        dayPeriodShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.smAll,
        ),
        dialBackgroundColor: c.surfaceMuted,
        dialHandColor: c.primary,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.primary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: c.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadius.xsAll,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: c.border),
        ),
      ),
    );
  }
}
