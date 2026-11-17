import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/core/theme/app_theme.dart';
import 'package:productivity_app/features/tasks/data/task_repository.dart';
import 'package:productivity_app/features/tasks/presentation/tasks_page.dart';
import 'package:productivity_app/l10n/app_localizations.dart';

const _todayWidgetChannel = MethodChannel(
  'com.example.productivity_app/today_widget',
);

MaterialApp _app({
  required Widget home,
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode? themeMode,
}) => MaterialApp(
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: theme,
  darkTheme: darkTheme,
  themeMode: themeMode,
  home: home,
);

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_todayWidgetChannel, (_) async => null);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_todayWidgetChannel, null);

    await database.close();
  });

  testWidgets('Различает пустой список и пустой фильтр', (tester) async {
    await tester.pumpWidget(_app(home: TasksPage(database: database)));
    await tester.pumpAndSettle();

    expect(find.text('Пока нет задач'), findsOneWidget);
    expect(find.text('Все задачи выполнены'), findsNothing);

    await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Активная задача'));

    await tester.pumpWidget(
      _app(
        home: TasksPage(
          key: const ValueKey('with-active-task'),
          database: database,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Готовые'));
    await tester.pumpAndSettle();

    expect(find.text('Нет выполненных задач'), findsOneWidget);
    expect(find.text('Все задачи выполнены'), findsNothing);
  });

  testWidgets('Показывает состояние, когда все задачи выполнены', (
    tester,
  ) async {
    final repository = TaskRepository(database);
    final taskId = await repository.createTask(title: 'Готовая задача');
    await repository.setCompleted(taskId: taskId, completed: true);

    await tester.pumpWidget(_app(home: TasksPage(database: database)));
    await tester.pumpAndSettle();

    expect(find.text('Все задачи выполнены'), findsOneWidget);
    expect(find.text('Пока нет задач'), findsNothing);
  });

  testWidgets('Склоняет слово «задача» для разных количеств', (tester) async {
    const expectedWords = <int, String>{
      0: 'задач',
      1: 'задача',
      2: 'задачи',
      4: 'задачи',
      5: 'задач',
      11: 'задач',
      12: 'задач',
      14: 'задач',
      21: 'задача',
      22: 'задачи',
      25: 'задач',
      101: 'задача',
      111: 'задач',
    };

    var insertedCount = 0;
    for (final entry in expectedWords.entries) {
      if (entry.key > insertedCount) {
        await database.batch((batch) {
          for (var index = insertedCount; index < entry.key; index++) {
            batch.insert(
              database.tasks,
              TasksCompanion.insert(title: 'Задача ${index + 1}'),
            );
          }
        });
        insertedCount = entry.key;
      }

      await tester.pumpWidget(
        _app(
          theme: AppTheme.light('purple'),
          darkTheme: AppTheme.dark('purple'),
          themeMode: ThemeMode.light,
          home: TasksPage(key: ValueKey(entry.key), database: database),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(entry.key == 0 ? 'Нет задач' : '${entry.key} ${entry.value}'),
        findsOneWidget,
      );
    }
  });

  testWidgets('Экран задач использует светлую и тёмную темы', (tester) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        _app(
          theme: AppTheme.light('teal'),
          darkTheme: AppTheme.dark('teal'),
          themeMode: mode,
          home: TasksPage(key: ValueKey(mode), database: database),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(TasksPage));
      expect(
        Theme.of(context).brightness,
        mode == ThemeMode.light ? Brightness.light : Brightness.dark,
      );
      expect(find.text('Нет задач'), findsOneWidget);
    }
  });

  testWidgets('Ошибка базы отображается без технических деталей', (
    tester,
  ) async {
    await database.customStatement('DROP TABLE tasks');

    await tester.pumpWidget(_app(home: TasksPage(database: database)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Не удалось загрузить задачи.'), findsOneWidget);
    expect(find.textContaining('SqliteException'), findsNothing);
    expect(find.textContaining('Bad state'), findsNothing);
  });
}
