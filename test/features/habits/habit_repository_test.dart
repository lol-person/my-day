// test/features/habits/habit_repository_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/features/habits/data/habit_repository.dart';

void main() {
  late AppDatabase database;
  late HabitRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = HabitRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Создаёт привычку и сохраняет расписание', () async {
    final habitId = await repository.createHabit(
      title: '  Пить воду  ',
      description: 'Пить воду каждый день',
      weekdays: {1, 3, 5},
    );

    final habits = await repository.getActiveHabits();
    final weekdays = await repository.getScheduledWeekdays(habitId);

    expect(habits, hasLength(1));
    expect(habits.single.id, habitId);
    expect(habits.single.title, 'Пить воду');
    expect(habits.single.description, 'Пить воду каждый день');
    expect(weekdays, {1, 3, 5});
  });

  test('Не позволяет создать привычку без названия', () async {
    expect(
      () => repository.createHabit(title: '   ', weekdays: {1, 2, 3}),
      throwsArgumentError,
    );

    expect(await repository.getActiveHabits(), isEmpty);
  });

  test('Можно отметить выполнение и снять отметку', () async {
    final habitId = await repository.createHabit(
      title: 'Читать',
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );

    final date = DateTime(2026, 10, 23);

    expect(await repository.isCompleted(habitId: habitId, date: date), isFalse);

    await repository.setCompleted(
      habitId: habitId,
      date: date,
      completed: true,
    );

    expect(await repository.isCompleted(habitId: habitId, date: date), isTrue);

    await repository.setCompleted(
      habitId: habitId,
      date: date,
      completed: false,
    );

    expect(await repository.isCompleted(habitId: habitId, date: date), isFalse);
  });

  test('Архивирование скрывает привычку из активного списка', () async {
    final habitId = await repository.createHabit(
      title: 'Медитация',
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );

    await repository.archiveHabit(habitId);

    expect(await repository.getActiveHabits(), isEmpty);
  });

  test('Редактирование сохраняет историю выполнения', () async {
    final habitId = await repository.createHabit(
      title: 'Пить воду',
      description: 'Старая заметка',
      weekdays: {1, 3, 5},
    );

    final date = DateTime(2026, 10, 23);

    await repository.setCompleted(
      habitId: habitId,
      date: date,
      completed: true,
    );

    await repository.updateHabit(
      habitId: habitId,
      title: 'Пить больше воды',
      description: 'Новая заметка',
      weekdays: {2, 4, 6},
    );

    final habits = await repository.getActiveHabits();
    final weekdays = await repository.getScheduledWeekdays(habitId);

    expect(habits, hasLength(1));
    expect(habits.single.title, 'Пить больше воды');
    expect(habits.single.description, 'Новая заметка');
    expect(weekdays, {2, 4, 6});

    expect(await repository.isCompleted(habitId: habitId, date: date), isTrue);
  });

  test('Архивную привычку можно найти и восстановить', () async {
    final habitId = await repository.createHabit(
      title: 'Читать',
      weekdays: {1, 3, 5},
    );

    final date = DateTime(2026, 10, 23);

    await repository.setCompleted(
      habitId: habitId,
      date: date,
      completed: true,
    );

    await repository.archiveHabit(habitId);

    final archived = await repository.getArchivedHabits();

    expect(archived, hasLength(1));
    expect(archived.single.id, habitId);
    expect(await repository.getActiveHabits(), isEmpty);

    await repository.restoreHabit(habitId);

    expect(await repository.getArchivedHabits(), isEmpty);
    expect(await repository.getActiveHabits(), hasLength(1));

    expect(await repository.isCompleted(habitId: habitId, date: date), isTrue);

    expect(await repository.getScheduledWeekdays(habitId), {1, 3, 5});
  });
}
