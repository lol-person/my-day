import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/core/widgets/today_widget_service.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Пустая база даёт корректный нулевой снимок', () async {
    final snapshot = await TodayWidgetService.readSnapshot(
      database,
      now: DateTime(2026, 11, 16),
    );

    expect(snapshot.completedHabits, 0);
    expect(snapshot.totalHabits, 0);
    expect(snapshot.activeTasks, 0);
    expect(snapshot.progressPercent, 0);
    expect(snapshot.toMap().keys.toSet(), {
      'completedHabits',
      'totalHabits',
      'activeTasks',
    });
  });

  test('Считает только привычки по расписанию и доступные задачи', () async {
    final today = DateTime(2026, 11, 16);
    final completedId = await _createHabit(database, 'Готовая', today);
    final pendingId = await _createHabit(database, 'Обычная', today);
    final archivedId = await _createHabit(
      database,
      'Архивная',
      today,
      isArchived: true,
    );
    final trashedId = await _createHabit(
      database,
      'Удалённая',
      today,
      deletedAt: today,
    );
    final otherDayId = await _createHabit(database, 'Не на сегодня', today);

    for (final id in [completedId, pendingId, archivedId, trashedId]) {
      await database
          .into(database.habitScheduleDays)
          .insert(
            HabitScheduleDaysCompanion.insert(
              habitId: id,
              weekday: today.weekday,
            ),
          );
    }
    await database
        .into(database.habitScheduleDays)
        .insert(
          HabitScheduleDaysCompanion.insert(
            habitId: otherDayId,
            weekday: today.weekday == 7 ? 1 : today.weekday + 1,
          ),
        );
    await database
        .into(database.habitEntries)
        .insert(
          HabitEntriesCompanion.insert(habitId: completedId, day: '2026-11-16'),
        );
    await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Активная'));
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Готовая',
            isCompleted: const Value(true),
          ),
        );
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(title: 'В корзине', deletedAt: Value(today)),
        );

    final snapshot = await TodayWidgetService.readSnapshot(
      database,
      now: today,
    );

    expect(snapshot.completedHabits, 1);
    expect(snapshot.totalHabits, 2);
    expect(snapshot.activeTasks, 1);
    expect(snapshot.progressPercent, 50);
  });
}

Future<int> _createHabit(
  AppDatabase database,
  String title,
  DateTime now, {
  bool isArchived = false,
  DateTime? deletedAt,
}) {
  return database
      .into(database.habits)
      .insert(
        HabitsCompanion.insert(
          title: title,
          createdAt: Value(now),
          isArchived: Value(isArchived),
          deletedAt: Value(deletedAt),
        ),
      );
}
