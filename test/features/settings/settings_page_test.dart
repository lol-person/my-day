import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/core/theme/app_theme.dart';
import 'package:productivity_app/features/settings/presentation/settings_page.dart';
import 'package:productivity_app/l10n/app_localizations.dart';

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Темы сохраняют акцентный цвет и контраст текста', () {
    final lightTheme = AppTheme.light('teal');
    final darkTheme = AppTheme.dark('teal');

    expect(lightTheme.colorScheme.brightness, Brightness.light);
    expect(darkTheme.colorScheme.brightness, Brightness.dark);
    expect(
      lightTheme.colorScheme.primary,
      isNot(AppTheme.light(AppAccentColor.defaultKey).colorScheme.primary),
    );
    expect(
      darkTheme.colorScheme.primary,
      isNot(AppTheme.dark(AppAccentColor.defaultKey).colorScheme.primary),
    );
    expect(lightTheme.cardTheme.elevation, 0);
    expect(darkTheme.dialogTheme.elevation, 0);

    for (final accentColorName in AppAccentColor.colors.keys) {
      for (final theme in [
        AppTheme.light(accentColorName),
        AppTheme.dark(accentColorName),
      ]) {
        expect(
          _contrastRatio(
            theme.colorScheme.onSurface,
            theme.colorScheme.surface,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(
            theme.colorScheme.onPrimaryContainer,
            theme.colorScheme.primaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  testWidgets('Сохраняет выбор тёмной темы в локальной базе', (tester) async {
    var changedThemeMode = ThemeMode.system;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(
          database: database,
          themeMode: ThemeMode.system,
          onThemeModeChanged: (mode) {
            changedThemeMode = mode;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Тема приложения'), findsOneWidget);

    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();

    expect(await database.getSetting(SettingsPage.themeModeKey), 'dark');
    expect(changedThemeMode, ThemeMode.dark);
    expect(find.text('Всегда используется тёмное оформление.'), findsOneWidget);
  });

  testWidgets('Сохраняет системную тему в локальной базе', (tester) async {
    var changedThemeMode = ThemeMode.dark;

    await database.saveSetting(SettingsPage.themeModeKey, 'dark');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(
          database: database,
          themeMode: ThemeMode.dark,
          onThemeModeChanged: (mode) {
            changedThemeMode = mode;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Система'));
    await tester.pumpAndSettle();

    expect(await database.getSetting(SettingsPage.themeModeKey), 'system');
    expect(changedThemeMode, ThemeMode.system);
  });
}
