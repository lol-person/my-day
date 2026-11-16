// test/features/settings/settings_page_test.dart

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/features/settings/presentation/settings_page.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('Сохраняет выбор тёмной темы в локальной базе', (tester) async {
    var changedThemeMode = ThemeMode.system;

    await tester.pumpWidget(
      MaterialApp(
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
