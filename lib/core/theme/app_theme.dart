// lib/core/theme/app_theme.dart

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

  static List<Color> heroGradient(String key) {
    final base = colorFor(key);
    final hsl = HSLColor.fromColor(base);

    final darker = hsl
        .withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0).toDouble())
        .toColor();

    return [base, darker];
  }
}
