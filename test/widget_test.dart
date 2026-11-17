import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/main.dart';

void main() {
  testWidgets('Главный экран приложения отображается', (
    WidgetTester tester,
  ) async {
    final originalLocales = tester.binding.platformDispatcher.locales;
    tester.binding.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(() {
      tester.binding.platformDispatcher.localesTestValue = originalLocales;
    });
    final database = AppDatabase.forTesting(NativeDatabase.memory());

    addTearDown(database.close);

    await tester.pumpWidget(ProductivityApp(database: database));

    await tester.pumpAndSettle();

    expect(find.text('Мой день'), findsOneWidget);
    expect(find.text('Локальная база данных подключена'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Экспорт и импорт данных'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();

    expect(find.text('Экспорт и импорт данных'), findsOneWidget);
    expect(find.text('Рабочее пространство'), findsNothing);
    expect(find.text('Здесь всё начнётся'), findsNothing);
  });

  testWidgets('Системные компоненты Material используют русскую локаль', (
    WidgetTester tester,
  ) async {
    final originalLocales = tester.binding.platformDispatcher.locales;
    tester.binding.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(() {
      tester.binding.platformDispatcher.localesTestValue = originalLocales;
    });
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(ProductivityApp(database: database));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DashboardPage));
    final localizations = MaterialLocalizations.of(context);

    expect(Localizations.localeOf(context), const Locale('ru'));
    expect(localizations.cancelButtonLabel.toLowerCase(), contains('отмен'));
    expect(localizations.okButtonLabel.toLowerCase(), contains('ок'));
    expect(
      localizations.formatMediumDate(DateTime(2026, 3, 14)).toLowerCase(),
      contains('мар'),
    );
    expect(
      localizations.formatFullDate(DateTime(2026, 3, 14)).toLowerCase(),
      contains('суббота'),
    );
    expect(
      localizations.formatTimeOfDay(const TimeOfDay(hour: 13, minute: 5)),
      '13:05',
    );
  });

  testWidgets('Основные разделы отображаются на русском и английском', (
    WidgetTester tester,
  ) async {
    final originalLocales = tester.binding.platformDispatcher.locales;
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    addTearDown(() {
      tester.binding.platformDispatcher.localesTestValue = originalLocales;
    });

    final cases = [
      (
        const Locale('ru'),
        'Мой день',
        'Открыть задачник',
        'Задачи',
        'Открыть трекер привычек',
        'Привычки',
        'Открыть календарь и план дня',
        'Календарь',
        'Посмотреть статистику',
        'Статистика',
        'Настроить напоминания',
        'Напоминания',
        'Экспорт и импорт данных',
        'Экспорт и импорт',
        'Корзина',
        'Корзина',
        'Настройки',
        'Архив привычек',
        'Архив привычек',
        'Фокус-сессия Pomodoro',
        'Фокус-сессия',
      ),
      (
        const Locale('en'),
        'My Day',
        'Open task list',
        'Tasks',
        'Open habit tracker',
        'Habits',
        'Open calendar and daily plan',
        'Calendar',
        'View statistics',
        'Statistics',
        'Manage reminders',
        'Reminders',
        'Backup and restore data',
        'Backup and restore',
        'Trash',
        'Trash',
        'Settings',
        'Archived habits',
        'Archived habits',
        'Start a Pomodoro session',
        'Focus session',
      ),
    ];

    for (final testCase in cases) {
      tester.binding.platformDispatcher.localesTestValue = [testCase.$1];
      await tester.pumpWidget(ProductivityApp(database: database));
      await tester.pumpAndSettle();
      expect(find.text(testCase.$2), findsOneWidget);

      final sections = [
        (testCase.$3, testCase.$4),
        (testCase.$5, testCase.$6),
        (testCase.$7, testCase.$8),
        (testCase.$9, testCase.$10),
        (testCase.$11, testCase.$12),
        (testCase.$13, testCase.$14),
        (testCase.$15, testCase.$16),
      ];

      for (final section in sections) {
        final navigation = find.text(section.$1);
        await tester.scrollUntilVisible(
          navigation,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(navigation);
        await tester.pumpAndSettle();
        expect(find.text(section.$2), findsWidgets);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byTooltip(testCase.$17));
      await tester.pumpAndSettle();
      expect(find.text(testCase.$17), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final habitsNavigation = find.text(testCase.$5);
      await tester.ensureVisible(habitsNavigation);
      await tester.tap(habitsNavigation);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(testCase.$18));
      await tester.pumpAndSettle();
      expect(find.text(testCase.$19), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final focusNavigation = find.text(testCase.$20);
      await tester.ensureVisible(focusNavigation);
      await tester.tap(focusNavigation);
      await tester.pumpAndSettle();
      expect(find.text(testCase.$21), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'Плейсхолдеры даты, времени и кнопок используют выбранную локаль',
    (WidgetTester tester) async {
      final originalLocales = tester.binding.platformDispatcher.locales;
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      addTearDown(() {
        tester.binding.platformDispatcher.localesTestValue = originalLocales;
      });

      for (final locale in const [Locale('ru'), Locale('en')]) {
        tester.binding.platformDispatcher.localesTestValue = [locale];
        await tester.pumpWidget(ProductivityApp(database: database));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(DashboardPage));
        final localizations = MaterialLocalizations.of(context);
        expect(
          Localizations.localeOf(context).languageCode,
          locale.languageCode,
        );
        expect(localizations.cancelButtonLabel, isNotEmpty);
        expect(localizations.okButtonLabel, isNotEmpty);
        expect(
          localizations.formatFullDate(DateTime(2026, 3, 14)),
          contains(locale.languageCode == 'ru' ? 'суббота' : 'Saturday'),
        );
        expect(
          localizations.formatFullDate(DateTime(2026, 3, 14)),
          contains(locale.languageCode == 'ru' ? 'марта' : 'March'),
        );
        expect(
          localizations.formatTimeOfDay(const TimeOfDay(hour: 13, minute: 5)),
          locale.languageCode == 'ru' ? '13:05' : contains('1:05'),
        );
      }
    },
  );
}
