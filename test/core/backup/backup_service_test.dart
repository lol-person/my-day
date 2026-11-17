import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/core/backup/backup_service.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/features/focus/data/focus_session_repository.dart';

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

  test('Экспорт и импорт сохраняют историю и активный таймер фокуса', () async {
    final startedAt = DateTime(2026, 11, 16, 9);
    final deadline = startedAt.add(const Duration(minutes: 25));
    await database
        .into(database.focusTimerState)
        .insert(
          FocusTimerStateCompanion.insert(
            id: const Value(1),
            phase: 'work',
            status: 'running',
            completedWorkSessions: 2,
            sessionStartedAt: Value(startedAt),
            deadline: Value(deadline),
            segmentStartedAt: Value(startedAt),
            elapsedSeconds: 0,
          ),
        );
    await database
        .into(database.focusSessions)
        .insert(
          FocusSessionsCompanion.insert(
            startedAt: startedAt.subtract(const Duration(days: 1)),
            completedAt: startedAt
                .subtract(const Duration(days: 1))
                .add(const Duration(minutes: 25)),
            durationSeconds: 1500,
          ),
        );

    final backup = await BackupService(database).createBackup();
    await database.delete(database.focusTimerState).go();
    await database.delete(database.focusSessions).go();
    await BackupService(database).restoreBackup(backup);

    final restoredState = await database
        .select(database.focusTimerState)
        .getSingle();
    final restoredSessions = await database
        .select(database.focusSessions)
        .get();
    expect(restoredState.deadline, deadline);
    expect(restoredState.completedWorkSessions, 2);
    expect(restoredSessions, hasLength(1));
    expect(restoredSessions.single.durationSeconds, 1500);
  });

  test('Восстанавливает приостановленную рабочую сессию с остатком больше 15 минут', () async {
    final start = DateTime(2026, 11, 16, 9);
    final repository = FocusSessionRepository(database);
    await repository.load(now: start);
    await repository.start(now: start);
    final paused = await repository.pause(
      now: start.add(const Duration(minutes: 5)),
    );
    await database
        .into(database.focusSessions)
        .insert(
          FocusSessionsCompanion.insert(
            startedAt: start.subtract(const Duration(days: 1)),
            completedAt: start.subtract(const Duration(days: 1)),
            durationSeconds: 1500,
          ),
        );

    expect(paused.remainingSeconds, 20 * 60);

    final backup = await BackupService(database).createBackup();
    await BackupService(database).restoreBackup(backup);

    final restoredRepository = FocusSessionRepository(database);
    final restored = await restoredRepository.load(now: start);
    expect(restored.status, FocusStatus.paused.name);
    expect(restored.phase, FocusPhase.work.name);
    expect(restored.remainingSeconds, 20 * 60);
    expect(restored.elapsedSeconds, 5 * 60);
    expect(await restoredRepository.history(), hasLength(1));

    final resumed = await restoredRepository.resume(
      now: start.add(const Duration(hours: 1)),
    );
    expect(resumed.deadline, start.add(const Duration(hours: 1, minutes: 20)));
  });

  test(
    'Завершает истёкший рабочий таймер после восстановления копии',
    () async {
      final now = DateTime.now();
      final startedAt = now.subtract(const Duration(minutes: 26));
      final deadline = startedAt.add(const Duration(minutes: 25));
      await database
          .into(database.focusTimerState)
          .insert(
            FocusTimerStateCompanion.insert(
              id: const Value(1),
              phase: FocusPhase.work.name,
              status: FocusStatus.running.name,
              completedWorkSessions: 0,
              sessionStartedAt: Value(startedAt),
              deadline: Value(deadline),
              segmentStartedAt: Value(startedAt),
              elapsedSeconds: 0,
            ),
          );
      await database
          .into(database.focusSessions)
          .insert(
            FocusSessionsCompanion.insert(
              startedAt: startedAt.subtract(const Duration(days: 1)),
              completedAt: startedAt.subtract(const Duration(days: 1)),
              durationSeconds: 1500,
            ),
          );

      final backup = await BackupService(database).createBackup();
      await BackupService(database).restoreBackup(backup);

      final repository = FocusSessionRepository(database);
      final restored = await repository.load(now: now);
      final history = await repository.history();
      expect(restored.phase, FocusPhase.shortBreak.name);
      expect(restored.status, FocusStatus.ready.name);
      expect(history, hasLength(2));
      expect(
        history.any(
          (session) =>
              session.completedAt.isAfter(
                now.subtract(const Duration(minutes: 2)),
              ) &&
              session.completedAt.isBefore(now),
        ),
        isTrue,
      );

      await repository.load(now: now);
      expect(await repository.history(), hasLength(2));
    },
  );

  test(
    'v4 восстанавливает содержимое корзины вместе с архивом и историей',
    () async {
      final deletedAt = DateTime(2026, 11, 16, 10);
      final habitId = await database
          .into(database.habits)
          .insert(
            HabitsCompanion.insert(
              title: 'Архивная привычка',
              isArchived: const Value(true),
              sortOrder: const Value(8),
              deletedAt: Value(deletedAt),
            ),
          );
      await database
          .into(database.habitScheduleDays)
          .insert(
            HabitScheduleDaysCompanion.insert(habitId: habitId, weekday: 2),
          );
      await database
          .into(database.habitEntries)
          .insert(
            HabitEntriesCompanion.insert(habitId: habitId, day: '2026-11-10'),
          );
      final taskId = await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Удалённая задача',
              sortOrder: const Value(-4),
              deletedAt: Value(deletedAt),
            ),
          );

      final backup = await BackupService(database).createBackup();
      final root = jsonDecode(utf8.decode(backup)) as Map<String, dynamic>;
      expect(root['formatVersion'], 4);
      await BackupService(database).restoreBackup(backup);

      final restoredHabit = await (database.select(
        database.habits,
      )..where((habit) => habit.id.equals(habitId))).getSingle();
      final restoredTask = await (database.select(
        database.tasks,
      )..where((task) => task.id.equals(taskId))).getSingle();
      expect(restoredHabit.deletedAt, deletedAt);
      expect(restoredHabit.isArchived, isTrue);
      expect(restoredHabit.sortOrder, 8);
      expect(restoredTask.deletedAt, deletedAt);
      expect(restoredTask.sortOrder, -4);
      expect(
        await database.select(database.habitScheduleDays).get(),
        hasLength(1),
      );
      expect(await database.select(database.habitEntries).get(), hasLength(1));
    },
  );

  test(
    'Импорт v3 задаёт null deletedAt и сохраняет порядок объектов',
    () async {
      await database
          .into(database.habits)
          .insert(
            HabitsCompanion.insert(
              title: 'Привычка v3',
              sortOrder: const Value(4),
            ),
          );
      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Задача v3',
              sortOrder: const Value(-2),
            ),
          );
      final root = jsonDecode(
        utf8.decode(await BackupService(database).createBackup()),
      ) as Map<String, dynamic>;
      root['formatVersion'] = 3;
      final data = root['data'] as Map<String, dynamic>;
      for (final key in ['habits', 'tasks']) {
        for (final row in data[key] as List<dynamic>) {
          (row as Map<String, dynamic>).remove('deletedAt');
        }
      }

      await BackupService(database)
          .restoreBackup(Uint8List.fromList(utf8.encode(jsonEncode(root))));

      final habit = (await database.select(database.habits).get()).single;
      final task = (await database.select(database.tasks).get()).single;
      expect(habit.deletedAt, isNull);
      expect(habit.sortOrder, 4);
      expect(task.deletedAt, isNull);
      expect(task.sortOrder, -2);
    },
  );

  test('Импортирует резервную копию v1 и задаёт прежний порядок', () async {
    final yogaId = await database
        .into(database.habits)
        .insert(
          HabitsCompanion.insert(
            title: 'Йога',
            createdAt: Value(DateTime(2026, 1, 2)),
            sortOrder: const Value(10),
          ),
        );

    await database
        .into(database.habits)
        .insert(
          HabitsCompanion.insert(
            title: 'Бег',
            createdAt: Value(DateTime(2026, 1, 1)),
            sortOrder: const Value(-10),
          ),
        );

    await database
        .into(database.habitScheduleDays)
        .insert(HabitScheduleDaysCompanion.insert(habitId: yogaId, weekday: 2));

    await database
        .into(database.habitEntries)
        .insert(
          HabitEntriesCompanion.insert(
            habitId: yogaId,
            day: '2026-01-06',
            note: const Value('Старая версия'),
          ),
        );

    await database.saveSetting('theme', 'dark');

    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Приоритетная старая задача',
            createdAt: Value(DateTime(2026, 1, 1)),
            priority: const Value(2),
            sortOrder: const Value(10),
          ),
        );
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Обычная старая задача',
            createdAt: Value(DateTime(2026, 1, 2)),
            priority: const Value(1),
            sortOrder: const Value(20),
          ),
        );
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Обычная новая задача',
            createdAt: Value(DateTime(2026, 1, 3)),
            priority: const Value(1),
            sortOrder: const Value(30),
          ),
        );

    final v1Backup = jsonDecode(
      utf8.decode(await BackupService(database).createBackup()),
    ) as Map<String, dynamic>;
    v1Backup['formatVersion'] = 1;

    final data = v1Backup['data'] as Map<String, dynamic>;
    for (final habit in data['habits'] as List<dynamic>) {
      (habit as Map<String, dynamic>).remove('sortOrder');
    }
    for (final task in data['tasks'] as List<dynamic>) {
      (task as Map<String, dynamic>).remove('sortOrder');
    }

    await database.transaction(() async {
      await database.delete(database.tasks).go();
      await database.delete(database.habitEntries).go();
      await database.delete(database.habitScheduleDays).go();
      await database.delete(database.habits).go();
      await database.delete(database.appSettings).go();
    });

    final summary = await BackupService(database)
        .restoreBackup(Uint8List.fromList(utf8.encode(jsonEncode(v1Backup))));

    expect(summary.settingsCount, 1);
    expect(summary.habitsCount, 2);
    expect(summary.entriesCount, 1);
    expect(summary.tasksCount, 3);

    final habits = await database.select(database.habits).get();
    habits.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(habits.map((habit) => habit.title), ['Бег', 'Йога']);
    expect(habits.map((habit) => habit.sortOrder), [0, 1]);

    final schedules = await database.select(database.habitScheduleDays).get();
    expect(schedules, hasLength(1));
    expect(schedules.single.habitId, yogaId);
    expect(schedules.single.weekday, 2);

    final entries = await database.select(database.habitEntries).get();
    expect(entries, hasLength(1));
    expect(entries.single.habitId, yogaId);
    expect(entries.single.day, '2026-01-06');
    expect(entries.single.note, 'Старая версия');
    expect(await database.getSetting('theme'), 'dark');

    final tasks = await database.select(database.tasks).get();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(tasks.map((task) => task.title), [
      'Приоритетная старая задача',
      'Обычная новая задача',
      'Обычная старая задача',
    ]);
    expect(tasks.map((task) => task.sortOrder), [0, 1, 2]);
  });

  test('Восстанавливает сохранённый порядок из резервной копии v2', () async {
    final habitIds = <int>[];
    for (final item in [
      ('Первая привычка', 5),
      ('Вторая привычка', -2),
      ('Третья привычка', 8),
    ]) {
      habitIds.add(
        await database
            .into(database.habits)
            .insert(
              HabitsCompanion.insert(title: item.$1, sortOrder: Value(item.$2)),
            ),
      );
    }

    final taskIds = <int>[];
    for (final item in [
      ('Первая задача', 9),
      ('Вторая задача', 0),
      ('Третья задача', 4),
    ]) {
      taskIds.add(
        await database
            .into(database.tasks)
            .insert(
              TasksCompanion.insert(title: item.$1, sortOrder: Value(item.$2)),
            ),
      );
    }

    final bytes = await BackupService(database).createBackup();

    for (var index = 0; index < habitIds.length; index++) {
      await (database.update(database.habits)
            ..where((habit) => habit.id.equals(habitIds[index])))
          .write(HabitsCompanion(sortOrder: Value(index + 20)));
    }
    for (var index = 0; index < taskIds.length; index++) {
      await (database.update(database.tasks)
            ..where((task) => task.id.equals(taskIds[index])))
          .write(TasksCompanion(sortOrder: Value(index + 20)));
    }

    await BackupService(database).restoreBackup(bytes);

    final habits = await database.select(database.habits).get();
    habits.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(habits.map((habit) => habit.title), [
      'Вторая привычка',
      'Первая привычка',
      'Третья привычка',
    ]);
    expect(habits.map((habit) => habit.sortOrder), [-2, 5, 8]);

    final tasks = await database.select(database.tasks).get();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(tasks.map((task) => task.title), [
      'Вторая задача',
      'Третья задача',
      'Первая задача',
    ]);
    expect(tasks.map((task) => task.sortOrder), [0, 4, 9]);
  });

  test('Некорректная резервная копия не изменяет текущие данные', () async {
    final existingTaskId = await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Сохранённая задача',
            createdAt: Value(DateTime(2026, 2, 1)),
          ),
        );
    final existingHabitId = await database
        .into(database.habits)
        .insert(HabitsCompanion.insert(title: 'Сохранённая привычка'));
    await database
        .into(database.habitScheduleDays)
        .insert(
          HabitScheduleDaysCompanion.insert(
            habitId: existingHabitId,
            weekday: 3,
          ),
        );
    await database
        .into(database.habitEntries)
        .insert(
          HabitEntriesCompanion.insert(
            habitId: existingHabitId,
            day: '2026-02-04',
            note: const Value('Сохранённая отметка'),
          ),
        );
    await database.saveSetting('theme', 'light');

    final malformedBackup = utf8.encode(
      jsonEncode({
        'format': BackupService.formatName,
        'formatVersion': BackupService.formatVersion,
        'data': {
          'appSettings': [
            {'key': 'theme', 'value': 'dark'},
          ],
          'habits': [],
          'habitScheduleDays': [],
          'habitEntries': [],
          'tasks': [
            {
              'id': 1,
              'title': 'Некорректный приоритет',
              'description': null,
              'createdAt': '2026-02-01T00:00:00.000',
              'dueDate': null,
              'priority': 9,
              'isCompleted': false,
              'sortOrder': 0,
            },
          ],
        },
      }),
    );

    await expectLater(
      BackupService(database).restoreBackup(malformedBackup),
      throwsFormatException,
    );

    final tasks = await database.select(database.tasks).get();
    expect(tasks, hasLength(1));
    expect(tasks.single.id, existingTaskId);
    expect(tasks.single.title, 'Сохранённая задача');

    final habits = await database.select(database.habits).get();
    expect(habits, hasLength(1));
    expect(habits.single.id, existingHabitId);
    expect(habits.single.title, 'Сохранённая привычка');

    final schedules = await database.select(database.habitScheduleDays).get();
    expect(schedules, hasLength(1));
    expect(schedules.single.habitId, existingHabitId);
    expect(schedules.single.weekday, 3);

    final entries = await database.select(database.habitEntries).get();
    expect(entries, hasLength(1));
    expect(entries.single.habitId, existingHabitId);
    expect(entries.single.day, '2026-02-04');
    expect(entries.single.note, 'Сохранённая отметка');
    expect(await database.getSetting('theme'), 'light');
  });
}
