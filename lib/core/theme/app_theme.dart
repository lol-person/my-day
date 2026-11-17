import 'package:flutter/material.dart';

class AppAccentColor {
  AppAccentColor._();

  static const String settingKey = 'appearance.accentColor';
  static const String defaultKey = 'purple';

  static const Map<String, Color> colors = {
    'purple': Color(0xFF6750A4),
    'green': Color(0xFF2E7D32),
    'red': Color(0xFFC62828),
    'blue': Color(0xFF1565C0),
    'orange': Color(0xFFAD5A00),
    'teal': Color(0xFF00796B),
  };

  static const Map<String, String> names = {
    'purple': 'Фиолетовый',
    'green': 'Зелёный',
    'red': 'Красный',
    'blue': 'Синий',
    'orange': 'Оранжевый',
    'teal': 'Бирюзовый',
  };

  static String normalize(String? value) {
    if (value != null && colors.containsKey(value)) {
      return value;
    }

    return defaultKey;
  }

  static Color colorFor(String key) {
    return colors[normalize(key)]!;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light(String accentColorName) =>
      _create(accentColorName: accentColorName, brightness: Brightness.light);

  static ThemeData dark(String accentColorName) =>
      _create(accentColorName: accentColorName, brightness: Brightness.dark);

  static ThemeData _create({
    required String accentColorName,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppAccentColor.colorFor(accentColorName),
      brightness: brightness,
    );
    final typography = Typography.material2021(
      platform: TargetPlatform.android,
    );
    final baseTextTheme = brightness == Brightness.light
        ? typography.black
        : typography.white;
    final resolvedTextTheme = baseTextTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final textTheme = resolvedTextTheme.copyWith(
      headlineLarge: resolvedTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineMedium: resolvedTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: resolvedTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: resolvedTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: resolvedTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18),
      ),
      shape: WidgetStatePropertyAll(buttonShape),
    );
    final fieldShape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: IconButtonThemeData(
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(48, 48)),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: fieldShape.copyWith(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: fieldShape.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: fieldShape.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: fieldShape.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
