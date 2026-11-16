// lib/features/habits/data/habit_repository.dart

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';

class HabitRepository {
  HabitRepository(this._database);

  final AppDatabase _database;

  Future<void> _syncRemindersSafely() async {
    try {
      await LocalNotificationService.instance.syncAll(_database);
    } catch (_) {
      // Ошибка уведомлений не должна отменять изменение привычки.
    }
  }

  void _validateHabit({required String title, required Set<int> weekdays}) {
    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError('Название привычки не может быть пустым.');
    }

    if (normalizedTitle.length > 100) {
      throw ArgumentError(
        'Название привычки не должно превышать 100 символов.',
      );
    }

    if (weekdays.isEmpty) {
      throw ArgumentError('Выбери хотя бы один день недели для привычки.');
    }

    if (weekdays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError('Дни недели должны быть числами от 1 до 7.');
    }
  }

  Future<int> createHabit({
    required String title,
    String? description,
    required Set<int> weekdays,
  }) async {
    _validateHabit(title: title, weekdays: weekdays);

    final normalizedDescription = description?.trim();

    final habitId = await _database.transaction(() async {
      final lastHabit =
          await (_database.select(_database.habits)
                ..orderBy([(habit) => OrderingTerm.desc(habit.sortOrder)])
                ..limit(1))
              .getSingleOrNull();

      final nextSortOrder = (lastHabit?.sortOrder ?? -1) + 1;

      final id = await _database
          .into(_database.habits)
          .insert(
            HabitsCompanion.insert(
              title: title.trim(),
              description: Value(
                normalizedDescription == null || normalizedDescription.isEmpty
                    ? null
                    : normalizedDescription,
              ),
              sortOrder: Value(nextSortOrder),
            ),
          );

      await _database.batch((batch) {
        batch.insertAll(
          _database.habitScheduleDays,
          weekdays
              .map(
                (weekday) => HabitScheduleDaysCompanion.insert(
                  habitId: id,
                  weekday: weekday,
                ),
              )
              .toList(),
        );
      });

      return id;
    });

    await _syncRemindersSafely();

    return habitId;
  }

  Future<void> updateHabit({
    required int habitId,
    required String title,
    required String? description,
    required Set<int> weekdays,
  }) async {
    _validateHabit(title: title, weekdays: weekdays);

    final normalizedDescription = description?.trim();

    await _database.transaction(() async {
      final existingHabit = await (_database.select(
        _database.habits,
      )..where((habit) => habit.id.equals(habitId))).getSingleOrNull();

      if (existingHabit == null) {
        throw StateError('Привычка с ID $habitId не найдена.');
      }

      await (_database.update(
        _database.habits,
      )..where((habit) => habit.id.equals(habitId))).write(
        HabitsCompanion(
          title: Value(title.trim()),
          description: Value(
            normalizedDescription == null || normalizedDescription.isEmpty
                ? null
                : normalizedDescription,
          ),
        ),
      );

      await (_database.delete(
        _database.habitScheduleDays,
      )..where((day) => day.habitId.equals(habitId))).go();

      await _database.batch((batch) {
        batch.insertAll(
          _database.habitScheduleDays,
          weekdays
              .map(
                (weekday) => HabitScheduleDaysCompanion.insert(
                  habitId: habitId,
                  weekday: weekday,
                ),
              )
              .toList(),
        );
      });
    });

    await _syncRemindersSafely();
  }

  /// Возвращает активные привычки в сохранённом порядке.
  Future<List<Habit>> getActiveHabits() {
    return (_database.select(_database.habits)
          ..where((habit) => habit.isArchived.equals(false))
          ..orderBy([
            (habit) => OrderingTerm.asc(habit.sortOrder),
            (habit) => OrderingTerm.asc(habit.title),
            (habit) => OrderingTerm.asc(habit.id),
          ]))
        .get();
  }

  /// Возвращает архивные привычки в сохранённом порядке.
  Future<List<Habit>> getArchivedHabits() {
    return (_database.select(_database.habits)
          ..where((habit) => habit.isArchived.equals(true))
          ..orderBy([
            (habit) => OrderingTerm.asc(habit.sortOrder),
            (habit) => OrderingTerm.asc(habit.title),
            (habit) => OrderingTerm.asc(habit.id),
          ]))
        .get();
  }

  /// Сохраняет порядок привычек внутри активного списка или архива.
  ///
  /// orderedHabitIds должен содержать все ID соответствующего списка
  /// в новом порядке, сверху вниз.
  ///
  /// Порядок второго списка сохраняется.
  Future<void> reorderHabits({
    required List<int> orderedHabitIds,
    required bool archived,
  }) async {
    await _database.transaction(() async {
      final allHabits =
          await (_database.select(_database.habits)..orderBy([
                (habit) => OrderingTerm.asc(habit.sortOrder),
                (habit) => OrderingTerm.asc(habit.title),
                (habit) => OrderingTerm.asc(habit.id),
              ]))
              .get();

      final selectedHabits = allHabits
          .where((habit) => habit.isArchived == archived)
          .toList();

      final requestedIds = orderedHabitIds.toSet();
      final currentIds = selectedHabits.map((habit) => habit.id).toSet();

      if (orderedHabitIds.length != requestedIds.length ||
          requestedIds.length != currentIds.length ||
          !requestedIds.containsAll(currentIds) ||
          !currentIds.containsAll(requestedIds)) {
        throw ArgumentError(
          'Список привычек изменился. Обнови список перед сортировкой.',
        );
      }

      final habitsById = {for (final habit in selectedHabits) habit.id: habit};

      final reorderedHabits = List<Habit>.of(allHabits);
      var nextSelectedIndex = 0;

      // Меняем выбранные элементы местами, не меняя позиции
      // элементов из другого списка.
      for (var index = 0; index < reorderedHabits.length; index++) {
        if (reorderedHabits[index].isArchived == archived) {
          reorderedHabits[index] =
              habitsById[orderedHabitIds[nextSelectedIndex]]!;
          nextSelectedIndex++;
        }
      }

      // Фиксируем уникальные позиции в базе данных.
      for (var index = 0; index < reorderedHabits.length; index++) {
        final habit = reorderedHabits[index];

        await (_database.update(_database.habits)
              ..where((item) => item.id.equals(habit.id)))
            .write(HabitsCompanion(sortOrder: Value(index)));
      }
    });
  }

  /// Восстанавливает привычку из архива.
  Future<void> restoreHabit(int habitId) async {
    final existingHabit = await (_database.select(
      _database.habits,
    )..where((habit) => habit.id.equals(habitId))).getSingleOrNull();

    if (existingHabit == null) {
      throw StateError('Привычка с ID $habitId не найдена.');
    }

    await (_database.update(_database.habits)
          ..where((habit) => habit.id.equals(habitId)))
        .write(const HabitsCompanion(isArchived: Value(false)));

    await _syncRemindersSafely();
  }

  Future<Set<int>> getScheduledWeekdays(int habitId) async {
    final rows = await (_database.select(
      _database.habitScheduleDays,
    )..where((day) => day.habitId.equals(habitId))).get();

    return rows.map((row) => row.weekday).toSet();
  }

  Future<bool> isCompleted({
    required int habitId,
    required DateTime date,
  }) async {
    final entry =
        await (_database.select(_database.habitEntries)..where(
              (entry) =>
                  entry.habitId.equals(habitId) &
                  entry.day.equals(_formatDate(date)),
            ))
            .getSingleOrNull();

    return entry != null;
  }

  Future<void> setCompleted({
    required int habitId,
    required DateTime date,
    required bool completed,
  }) async {
    final day = _formatDate(date);

    if (completed) {
      await _database
          .into(_database.habitEntries)
          .insertOnConflictUpdate(
            HabitEntriesCompanion.insert(habitId: habitId, day: day),
          );
    } else {
      await (_database.delete(_database.habitEntries)..where(
            (entry) => entry.habitId.equals(habitId) & entry.day.equals(day),
          ))
          .go();
    }
  }

  Future<void> archiveHabit(int habitId) async {
    await (_database.update(_database.habits)
          ..where((habit) => habit.id.equals(habitId)))
        .write(const HabitsCompanion(isArchived: Value(true)));

    await _syncRemindersSafely();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
