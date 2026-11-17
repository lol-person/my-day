import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/features/tasks/data/task_repository.dart';

void main() {
  late AppDatabase database;
  late TaskRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = TaskRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Создаёт задачу и сохраняет её данные', () async {
    final taskId = await repository.createTask(
      title: '  Купить продукты  ',
      description: 'Молоко и хлеб',
      dueDate: DateTime(2026, 11, 3, 15, 30),
      priority: 2,
    );

    final tasks = await repository.getTasks(filter: TaskFilter.all);

    expect(tasks, hasLength(1));
    expect(tasks.single.id, taskId);
    expect(tasks.single.title, 'Купить продукты');
    expect(tasks.single.description, 'Молоко и хлеб');
    expect(tasks.single.dueDate, DateTime(2026, 11, 3));
    expect(tasks.single.priority, 2);
    expect(tasks.single.isCompleted, isFalse);
  });

  test('Не позволяет создать задачу без названия', () async {
    await expectLater(repository.createTask(title: '   '), throwsArgumentError);

    expect(await repository.getTasks(filter: TaskFilter.all), isEmpty);
  });

  test('Фильтрует активные и выполненные задачи', () async {
    final activeId = await repository.createTask(title: 'Активная задача');

    final completedId = await repository.createTask(
      title: 'Выполненная задача',
    );

    expect(await repository.getTasks(filter: TaskFilter.all), hasLength(2));

    await repository.setCompleted(taskId: completedId, completed: true);

    final activeTasks = await repository.getTasks(filter: TaskFilter.active);

    final completedTasks = await repository.getTasks(
      filter: TaskFilter.completed,
    );

    final allTasks = await repository.getTasks(filter: TaskFilter.all);

    expect(activeTasks, hasLength(1));
    expect(activeTasks.single.id, activeId);

    expect(completedTasks, hasLength(1));
    expect(completedTasks.single.id, completedId);
    expect(completedTasks.single.isCompleted, isTrue);

    expect(allTasks, hasLength(2));
  });

  test('Редактирование сохраняет статус выполнения', () async {
    final taskId = await repository.createTask(
      title: 'Старая задача',
      description: 'Старое описание',
      dueDate: DateTime(2026, 11, 3),
      priority: 0,
    );

    await repository.setCompleted(taskId: taskId, completed: true);

    await repository.updateTask(
      taskId: taskId,
      title: 'Новая задача',
      description: 'Новое описание',
      dueDate: null,
      priority: 2,
    );

    final tasks = await repository.getTasks(filter: TaskFilter.all);

    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'Новая задача');
    expect(tasks.single.description, 'Новое описание');
    expect(tasks.single.dueDate, isNull);
    expect(tasks.single.priority, 2);
    expect(tasks.single.isCompleted, isTrue);
  });

  test('Перемещает задачу в корзину и восстанавливает исходные поля', () async {
    final taskId = await repository.createTask(
      title: 'Удаляемая задача',
      dueDate: DateTime(2026, 11, 20),
      priority: 2,
    );
    await repository.setCompleted(taskId: taskId, completed: true);

    await repository.moveTaskToTrash(taskId, deletedAt: DateTime(2026, 11, 16));

    expect(await repository.getTasks(filter: TaskFilter.all), isEmpty);
    final trashed = await repository.getDeletedTasks();
    expect(trashed, hasLength(1));
    expect(trashed.single.id, taskId);
    expect(trashed.single.isCompleted, isTrue);
    expect(trashed.single.priority, 2);
    expect(trashed.single.dueDate, DateTime(2026, 11, 20));

    await repository.restoreTask(taskId);

    final restored = await repository.getTasks(filter: TaskFilter.all);
    expect(restored, hasLength(1));
    expect(restored.single.deletedAt, isNull);
    expect(restored.single.isCompleted, isTrue);
    expect(restored.single.priority, 2);
  });

  test('Окончательно удаляет задачу из корзины', () async {
    final taskId = await repository.createTask(title: 'Удаляемая задача');
    await repository.moveTaskToTrash(taskId);
    await repository.permanentlyDeleteTask(taskId);

    expect(await repository.getDeletedTasks(), isEmpty);
    expect(await repository.getTasks(filter: TaskFilter.all), isEmpty);
  });

  test('Не принимает неправильный приоритет', () async {
    await expectLater(
      repository.createTask(title: 'Проверка', priority: 5),
      throwsArgumentError,
    );

    expect(await repository.getTasks(filter: TaskFilter.all), isEmpty);
  });
}
