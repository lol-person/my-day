// lib/features/tasks/data/task_repository.dart

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';

enum TaskFilter { active, completed, all }

class TaskRepository {
  TaskRepository(this._database);

  final AppDatabase _database;

  Future<void> _syncRemindersSafely() async {
    try {
      await LocalNotificationService.instance.syncAll(_database);
    } catch (_) {
      // Ошибка уведомлений не должна отменять операцию с задачей.
    }
  }

  void _validateTask({required String title, required int priority}) {
    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError('Название задачи не может быть пустым.');
    }

    if (normalizedTitle.length > 150) {
      throw ArgumentError('Название задачи не должно превышать 150 символов.');
    }

    if (priority < 0 || priority > 2) {
      throw ArgumentError('Приоритет должен быть от 0 до 2.');
    }
  }

  DateTime? _normalizeDate(DateTime? date) {
    if (date == null) return null;

    return DateTime(date.year, date.month, date.day);
  }

  String? _normalizeDescription(String? description) {
    final normalized = description?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  bool _matchesFilter(Task task, TaskFilter filter) {
    switch (filter) {
      case TaskFilter.active:
        return !task.isCompleted;
      case TaskFilter.completed:
        return task.isCompleted;
      case TaskFilter.all:
        return true;
    }
  }

  Future<int> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    int priority = 1,
  }) async {
    _validateTask(title: title, priority: priority);

    final id = await _database.transaction(() async {
      final firstTask =
          await (_database.select(_database.tasks)
                ..orderBy([
                  (task) => OrderingTerm.asc(task.sortOrder),
                  (task) => OrderingTerm.desc(task.priority),
                  (task) => OrderingTerm.desc(task.createdAt),
                  (task) => OrderingTerm.asc(task.id),
                ])
                ..limit(1))
              .getSingleOrNull();

      // Новые задачи появляются вверху списка.
      final nextSortOrder = firstTask == null ? 0 : firstTask.sortOrder - 1;

      return _database
          .into(_database.tasks)
          .insert(
            TasksCompanion.insert(
              title: title.trim(),
              description: Value(_normalizeDescription(description)),
              dueDate: Value(_normalizeDate(dueDate)),
              priority: Value(priority),
              sortOrder: Value(nextSortOrder),
            ),
          );
    });

    await _syncRemindersSafely();

    return id;
  }

  Future<void> updateTask({
    required int taskId,
    required String title,
    String? description,
    DateTime? dueDate,
    required int priority,
  }) async {
    _validateTask(title: title, priority: priority);

    final existingTask = await (_database.select(
      _database.tasks,
    )..where((task) => task.id.equals(taskId))).getSingleOrNull();

    if (existingTask == null) {
      throw StateError('Задача с ID $taskId не найдена.');
    }

    // Редактирование задачи не меняет её положение в списке.
    await (_database.update(
      _database.tasks,
    )..where((task) => task.id.equals(taskId))).write(
      TasksCompanion(
        title: Value(title.trim()),
        description: Value(_normalizeDescription(description)),
        dueDate: Value(_normalizeDate(dueDate)),
        priority: Value(priority),
      ),
    );

    await _syncRemindersSafely();
  }

  Future<List<Task>> getTasks({TaskFilter filter = TaskFilter.active}) async {
    final query = _database.select(_database.tasks);

    if (filter == TaskFilter.active) {
      query.where((task) => task.isCompleted.equals(false));
    } else if (filter == TaskFilter.completed) {
      query.where((task) => task.isCompleted.equals(true));
    }

    query.orderBy([
      (task) => OrderingTerm.asc(task.sortOrder),
      // Дополнительная сортировка нужна для старых записей,
      // у которых до миграции не было индивидуального порядка.
      (task) => OrderingTerm.desc(task.priority),
      (task) => OrderingTerm.desc(task.createdAt),
      (task) => OrderingTerm.asc(task.id),
    ]);

    return query.get();
  }

  /// Сохраняет порядок задач сверху вниз.
  ///
  /// Передай все ID задач текущего фильтра в новом порядке.
  /// Порядок задач, не входящих в этот фильтр, сохраняется.
  Future<void> reorderTasks({
    required List<int> orderedTaskIds,
    TaskFilter filter = TaskFilter.active,
  }) async {
    await _database.transaction(() async {
      final allTasks =
          await (_database.select(_database.tasks)..orderBy([
                (task) => OrderingTerm.asc(task.sortOrder),
                (task) => OrderingTerm.desc(task.priority),
                (task) => OrderingTerm.desc(task.createdAt),
                (task) => OrderingTerm.asc(task.id),
              ]))
              .get();

      final selectedTasks = allTasks
          .where((task) => _matchesFilter(task, filter))
          .toList();

      final requestedIds = orderedTaskIds.toSet();
      final currentIds = selectedTasks.map((task) => task.id).toSet();

      if (orderedTaskIds.length != requestedIds.length ||
          requestedIds.length != currentIds.length ||
          !requestedIds.containsAll(currentIds) ||
          !currentIds.containsAll(requestedIds)) {
        throw ArgumentError(
          'Список задач изменился. Обнови список перед сортировкой.',
        );
      }

      final tasksById = {for (final task in selectedTasks) task.id: task};

      final reorderedTasks = List<Task>.of(allTasks);
      final selectedPositions = <int>[];

      // Запоминаем позиции задач выбранного фильтра.
      for (var index = 0; index < reorderedTasks.length; index++) {
        if (_matchesFilter(reorderedTasks[index], filter)) {
          selectedPositions.add(index);
        }
      }

      // Меняем местами только выбранные задачи, сохраняя
      // относительный порядок элементов других фильтров.
      for (var index = 0; index < selectedPositions.length; index++) {
        reorderedTasks[selectedPositions[index]] =
            tasksById[orderedTaskIds[index]]!;
      }

      // Перезаписываем порядок всех задач в одной транзакции.
      for (var index = 0; index < reorderedTasks.length; index++) {
        final task = reorderedTasks[index];

        await (_database.update(_database.tasks)
              ..where((item) => item.id.equals(task.id)))
            .write(TasksCompanion(sortOrder: Value(index)));
      }
    });
  }

  Future<void> setCompleted({
    required int taskId,
    required bool completed,
  }) async {
    final updatedRows =
        await (_database.update(_database.tasks)
              ..where((task) => task.id.equals(taskId)))
            .write(TasksCompanion(isCompleted: Value(completed)));

    if (updatedRows == 0) {
      throw StateError('Задача с ID $taskId не найдена.');
    }

    await _syncRemindersSafely();
  }

  Future<void> deleteTask(int taskId) async {
    await (_database.delete(
      _database.tasks,
    )..where((task) => task.id.equals(taskId))).go();

    await _syncRemindersSafely();
  }
}
