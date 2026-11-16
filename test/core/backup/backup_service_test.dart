// test/core/backup/backup_service_test.dart

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/core/backup/backup_service.dart';
import 'package:productivity_app/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Экспорт и импорт сохраняют все пользовательские данные', () async {
    final habitId = await database
        .into(database.habits)
        .insert(
          HabitsCompanion.insert(
            title: 'Читать',
            description: const Value('Десять страниц'),
            createdAt: Value(DateTime(2026, 10, 20, 8)),
          ),
        );

    await database
        .into(database.habitScheduleDays)
        .insert(
          HabitScheduleDaysCompanion.insert(
            habitId: habitId,
            weekday: DateTime(2026, 10, 20).weekday,
          ),
        );

    await database
        .into(database.habitEntries)
        .insert(
          HabitEntriesCompanion.insert(
            habitId: habitId,
            day: '2026-10-20',
            completedAt: Value(DateTime(2026, 10, 20, 8, 30)),
            note: const Value('Выполнено'),
          ),
        );

    final taskId = await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Купить продукты',
            description: const Value('Молоко и хлеб'),
            createdAt: Value(DateTime(2026, 10, 19, 12)),
            dueDate: Value(DateTime(2026, 10, 21)),
            priority: const Value(2),
          ),
        );

    await database.saveSetting('reminders.habits.enabled', 'true');
    await database.saveSetting('reminders.habits.hour', '8');

    final bytes = await BackupService(database).createBackup();

    await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Новая задача после копии'));

    final summary = await BackupService(database).restoreBackup(bytes);

    expect(summary.settingsCount, 2);
    expect(summary.habitsCount, 1);
    expect(summary.entriesCount, 1);
    expect(summary.tasksCount, 1);

    final restoredHabits = await database.select(database.habits).get();

    expect(restoredHabits, hasLength(1));
    expect(restoredHabits.single.id, habitId);
    expect(restoredHabits.single.title, 'Читать');
    expect(restoredHabits.single.description, 'Десять страниц');

    final restoredSchedules = await database
        .select(database.habitScheduleDays)
        .get();

    expect(restoredSchedules, hasLength(1));
    expect(restoredSchedules.single.habitId, habitId);

    final restoredEntries = await database.select(database.habitEntries).get();

    expect(restoredEntries, hasLength(1));
    expect(restoredEntries.single.habitId, habitId);
    expect(restoredEntries.single.day, '2026-10-20');
    expect(restoredEntries.single.note, 'Выполнено');

    final restoredTasks = await database.select(database.tasks).get();

    expect(restoredTasks, hasLength(1));
    expect(restoredTasks.single.id, taskId);
    expect(restoredTasks.single.title, 'Купить продукты');
    expect(restoredTasks.single.priority, 2);

    expect(await database.getSetting('reminders.habits.enabled'), 'true');
    expect(await database.getSetting('reminders.habits.hour'), '8');
  });

  test('Неподдерживаемый JSON не удаляет текущие данные', () async {
    final existingTaskId = await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Сохранённая задача'));

    final invalidJson = utf8.encode(
      jsonEncode({
        'format': 'неизвестный_формат',
        'formatVersion': 1,
        'data': {},
      }),
    );

    await expectLater(
      BackupService(database).restoreBackup(invalidJson),
      throwsFormatException,
    );

    final tasks = await database.select(database.tasks).get();

    expect(tasks, hasLength(1));
    expect(tasks.single.id, existingTaskId);
    expect(tasks.single.title, 'Сохранённая задача');
  });
}
