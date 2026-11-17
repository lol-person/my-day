import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';

void main() {
  test('Миграция v5 добавляет корзину, сохраняя существующие данные', () async {
    final createdAt = DateTime(2026, 1, 2).millisecondsSinceEpoch;
    final executor = NativeDatabase.memory(
      setup: (sqlite) {
        sqlite.execute('''
          CREATE TABLE habits (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            created_at INTEGER NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            is_archived INTEGER NOT NULL DEFAULT 0
          )
        ''');
        sqlite.execute('''
          CREATE TABLE tasks (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            created_at INTEGER NOT NULL,
            due_date INTEGER,
            priority INTEGER NOT NULL DEFAULT 1,
            is_completed INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        sqlite.execute('''
          CREATE TABLE habit_schedule_days (
            habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
            weekday INTEGER NOT NULL,
            PRIMARY KEY (habit_id, weekday)
          )
        ''');
        sqlite.execute('''
          CREATE TABLE habit_entries (
            habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
            day TEXT NOT NULL,
            completed_at INTEGER NOT NULL,
            note TEXT,
            PRIMARY KEY (habit_id, day)
          )
        ''');
        sqlite.execute(
          "INSERT INTO habits VALUES (12, 'Йога', 'Утренняя', $createdAt, 7, 1)",
        );
        sqlite.execute(
          "INSERT INTO tasks VALUES (21, 'Позвонить', NULL, $createdAt, NULL, 2, 1, -3)",
        );
        sqlite.execute('INSERT INTO habit_schedule_days VALUES (12, 2)');
        sqlite.execute(
          "INSERT INTO habit_entries VALUES (12, '2026-01-06', $createdAt, 'Готово')",
        );
        sqlite.execute('PRAGMA user_version = 5');
      },
    );
    final migrated = AppDatabase.forTesting(executor);

    final habit = await migrated.select(migrated.habits).getSingle();
    final task = await migrated.select(migrated.tasks).getSingle();
    final schedules = await migrated.select(migrated.habitScheduleDays).get();
    final entries = await migrated.select(migrated.habitEntries).get();

    expect(habit.id, 12);
    expect(habit.isArchived, isTrue);
    expect(habit.sortOrder, 7);
    expect(habit.deletedAt, isNull);
    expect(task.id, 21);
    expect(task.isCompleted, isTrue);
    expect(task.sortOrder, -3);
    expect(task.deletedAt, isNull);
    expect(schedules.single.weekday, 2);
    expect(entries.single.note, 'Готово');

    await migrated.close();
  });
}
