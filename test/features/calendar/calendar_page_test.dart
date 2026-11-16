// test/features/calendar/calendar_page_test.dart

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/features/calendar/presentation/calendar_page.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('Показывает привычки по расписанию и задачи по сроку', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    final habitId = await database
        .into(database.habits)
        .insert(HabitsCompanion.insert(title: 'Привычка сегодня'));

    await database
        .into(database.habitScheduleDays)
        .insert(
          HabitScheduleDaysCompanion.insert(
            habitId: habitId,
            weekday: today.weekday,
          ),
        );

    final otherWeekday = today.weekday == 7 ? 1 : today.weekday + 1;

    final otherHabitId = await database
        .into(database.habits)
        .insert(HabitsCompanion.insert(title: 'Привычка не на сегодня'));

    await database
        .into(database.habitScheduleDays)
        .insert(
          HabitScheduleDaysCompanion.insert(
            habitId: otherHabitId,
            weekday: otherWeekday,
          ),
        );

    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Задача на сегодня',
            dueDate: Value(today),
          ),
        );

    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Задача на завтра',
            dueDate: Value(tomorrow),
          ),
        );

    await tester.pumpWidget(
      MaterialApp(home: CalendarPage(database: database)),
    );

    await tester.pumpAndSettle();

    expect(find.text('План дня'), findsOneWidget);
    expect(find.text('Привычка сегодня'), findsOneWidget);
    expect(find.text('Привычка не на сегодня'), findsNothing);

    // Отмечаем привычку, пока её элемент находится на экране.
    final habitTile = find.widgetWithText(CheckboxListTile, 'Привычка сегодня');

    await tester.tap(habitTile);
    await tester.pumpAndSettle();

    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final entry =
        await (database.select(database.habitEntries)..where(
              (row) => row.habitId.equals(habitId) & row.day.equals(dateKey),
            ))
            .getSingleOrNull();

    expect(entry != null, isTrue);

    // Прокручиваем список к задачам, прежде чем их искать.
    await tester.scrollUntilVisible(
      find.text('Задача на сегодня'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Задача на сегодня'), findsOneWidget);
    expect(find.text('Задача на завтра'), findsNothing);
  });
}
