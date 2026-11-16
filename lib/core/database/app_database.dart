// lib/core/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get key => text().unique()();

  TextColumn get value => text()();
}

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 100)();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  /// Положение привычки в пользовательском списке.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

class HabitScheduleDays extends Table {
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  IntColumn get weekday => integer()();

  @override
  Set<Column> get primaryKey => {habitId, weekday};
}

class HabitEntries extends Table {
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  TextColumn get day => text()();

  DateTimeColumn get completedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {habitId, day};
}

/// Таблица задач.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 150)();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  /// Необязательный срок выполнения.
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// 0 — низкий, 1 — обычный, 2 — высокий.
  IntColumn get priority => integer().withDefault(const Constant(1))();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Положение задачи в пользовательском списке.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DriftDatabase(
  tables: [AppSettings, Habits, HabitScheduleDays, HabitEntries, Tasks],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'productivity_app'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(habits);
        await migrator.createTable(habitScheduleDays);
        await migrator.createTable(habitEntries);
      }

      if (from < 3) {
        await migrator.createTable(tasks);
      }

      if (from < 4) {
        await migrator.addColumn(habits, habits.sortOrder);
        await migrator.addColumn(tasks, tasks.sortOrder);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> saveSetting(String key, String value) {
    return transaction(() async {
      final existing = await (select(
        appSettings,
      )..where((setting) => setting.key.equals(key))).getSingleOrNull();

      if (existing == null) {
        await into(appSettings)
            .insert(AppSettingsCompanion.insert(key: key, value: value));
      } else {
        await (update(appSettings)..where((setting) => setting.key.equals(key)))
            .write(AppSettingsCompanion(value: Value(value)));
      }
    });
  }

  Future<String?> getSetting(String key) async {
    final setting = await (select(
      appSettings,
    )..where((setting) => setting.key.equals(key))).getSingleOrNull();

    return setting?.value;
  }
}
