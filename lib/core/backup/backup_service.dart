// lib/core/backup/backup_service.dart

import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  static const String formatName = 'productivity_app_backup';
  static const int formatVersion = 2;
  static const int maxBackupBytes = 25 * 1024 * 1024;

  static String suggestedFileName() {
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return 'productivity_backup_$year$month${day}_'
        '$hour$minute$second.json';
  }

  /// Создаёт JSON-копию всех пользовательских данных и настроек.
  /// Пользовательский порядок привычек и задач включается в копию.
  Future<Uint8List> createBackup() async {
    final settings = await _database.select(_database.appSettings).get();
    final habits = await _database.select(_database.habits).get();
    final schedules = await _database.select(_database.habitScheduleDays).get();
    final entries = await _database.select(_database.habitEntries).get();
    final tasks = await _database.select(_database.tasks).get();

    final backup = <String, dynamic>{
      'format': formatName,
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': <String, dynamic>{
        'appSettings': settings
            .map(
              (setting) => <String, dynamic>{
                'key': setting.key,
                'value': setting.value,
              },
            )
            .toList(),
        'habits': habits
            .map(
              (habit) => <String, dynamic>{
                'id': habit.id,
                'title': habit.title,
                'description': habit.description,
                'createdAt': habit.createdAt.toIso8601String(),
                'isArchived': habit.isArchived,
                'sortOrder': habit.sortOrder,
              },
            )
            .toList(),
        'habitScheduleDays': schedules
            .map(
              (schedule) => <String, dynamic>{
                'habitId': schedule.habitId,
                'weekday': schedule.weekday,
              },
            )
            .toList(),
        'habitEntries': entries
            .map(
              (entry) => <String, dynamic>{
                'habitId': entry.habitId,
                'day': entry.day,
                'completedAt': entry.completedAt.toIso8601String(),
                'note': entry.note,
              },
            )
            .toList(),
        'tasks': tasks
            .map(
              (task) => <String, dynamic>{
                'id': task.id,
                'title': task.title,
                'description': task.description,
                'createdAt': task.createdAt.toIso8601String(),
                'dueDate': task.dueDate?.toIso8601String(),
                'priority': task.priority,
                'isCompleted': task.isCompleted,
                'sortOrder': task.sortOrder,
              },
            )
            .toList(),
      },
    };

    final json = const JsonEncoder.withIndent('  ').convert(backup);
    final bytes = Uint8List.fromList(utf8.encode(json));

    if (bytes.length > maxBackupBytes) {
      throw const FormatException(
        'Резервная копия превышает допустимый размер 25 МБ.',
      );
    }

    return bytes;
  }

  /// Проверяет копию и заменяет текущие данные в одной транзакции.
  Future<BackupSummary> restoreBackup(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const FormatException('Файл резервной копии пуст.');
    }

    if (bytes.length > maxBackupBytes) {
      throw const FormatException('Файл превышает допустимый размер 25 МБ.');
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const FormatException('Файл не является корректным JSON.');
    }

    final parsed = _parseBackup(decoded);

    // Все данные проверены до начала транзакции.
    // При ошибке вставки SQLite отменит всю транзакцию.
    await _database.transaction(() async {
      await _database.delete(_database.tasks).go();
      await _database.delete(_database.habitEntries).go();
      await _database.delete(_database.habitScheduleDays).go();
      await _database.delete(_database.habits).go();
      await _database.delete(_database.appSettings).go();

      for (final setting in parsed.settings) {
        await _database
            .into(_database.appSettings)
            .insert(
              AppSettingsCompanion.insert(
                key: setting.key,
                value: setting.value,
              ),
            );
      }

      for (final habit in parsed.habits) {
        await _database
            .into(_database.habits)
            .insert(
              HabitsCompanion(
                id: Value(habit.id),
                title: Value(habit.title),
                description: Value(habit.description),
                createdAt: Value(habit.createdAt),
                isArchived: Value(habit.isArchived),
                sortOrder: Value(habit.sortOrder),
              ),
            );
      }

      for (final schedule in parsed.schedules) {
        await _database
            .into(_database.habitScheduleDays)
            .insert(
              HabitScheduleDaysCompanion.insert(
                habitId: schedule.habitId,
                weekday: schedule.weekday,
              ),
            );
      }

      for (final entry in parsed.entries) {
        await _database
            .into(_database.habitEntries)
            .insert(
              HabitEntriesCompanion.insert(
                habitId: entry.habitId,
                day: entry.day,
                completedAt: Value(entry.completedAt),
                note: Value(entry.note),
              ),
            );
      }

      for (final task in parsed.tasks) {
        await _database
            .into(_database.tasks)
            .insert(
              TasksCompanion(
                id: Value(task.id),
                title: Value(task.title),
                description: Value(task.description),
                createdAt: Value(task.createdAt),
                dueDate: Value(task.dueDate),
                priority: Value(task.priority),
                isCompleted: Value(task.isCompleted),
                sortOrder: Value(task.sortOrder),
              ),
            );
      }
    });

    return BackupSummary(
      settingsCount: parsed.settings.length,
      habitsCount: parsed.habits.length,
      entriesCount: parsed.entries.length,
      tasksCount: parsed.tasks.length,
    );
  }

  _ParsedBackup _parseBackup(dynamic decoded) {
    final root = _readObject(decoded, 'корень');

    if (_readString(root, 'format', 'корень') != formatName) {
      throw const FormatException(
        'Это не резервная копия приложения «Мой день».',
      );
    }

    final version = _readInt(root, 'formatVersion', 'корень');

    // Версия 1 поддерживается для совместимости со старыми копиями.
    if (version != 1 && version != formatVersion) {
      throw FormatException(
        'Версия резервной копии $version не поддерживается. '
        'Поддерживаются версии 1 и $formatVersion.',
      );
    }

    final data = _readObject(root['data'], 'data');

    final settings = _readList(data['appSettings'], 'data.appSettings')
        .asMap()
        .entries
        .map((item) {
          final path = 'data.appSettings[${item.key}]';
          final row = _readObject(item.value, path);

          return _SettingRecord(
            key: _readString(row, 'key', path, maxLength: 512),
            value: _readString(row, 'value', path, maxLength: 10 * 1024 * 1024),
          );
        })
        .toList();

    final settingKeys = <String>{};

    for (final setting in settings) {
      if (setting.key.isEmpty || !settingKeys.add(setting.key)) {
        throw FormatException(
          'В копии есть пустой или повторяющийся ключ настройки: '
          '${setting.key}',
        );
      }
    }

    final habits = _readList(data['habits'], 'data.habits').asMap().entries.map(
      (item) {
        final path = 'data.habits[${item.key}]';
        final row = _readObject(item.value, path);
        final title = _readString(row, 'title', path, maxLength: 100);

        if (title.trim().isEmpty) {
          throw FormatException('$path.title не может быть пустым.');
        }

        return _HabitRecord(
          id: _readPositiveInt(row, 'id', path),
          title: title,
          description: _readNullableString(
            row,
            'description',
            path,
            maxLength: 10 * 1024 * 1024,
          ),
          createdAt: _readDate(row, 'createdAt', path),
          isArchived: _readBool(row, 'isArchived', path),
          sortOrder: version >= 2 ? _readInt(row, 'sortOrder', path) : 0,
        );
      },
    ).toList();

    _checkUniqueIds(habits.map((habit) => habit.id), 'идентификаторы привычек');

    // Старые копии не содержали пользовательского порядка.
    // Для них восстанавливаем прежнюю сортировку по названию.
    if (version == 1) {
      habits.sort((a, b) {
        final titleComparison = a.title.compareTo(b.title);
        if (titleComparison != 0) return titleComparison;
        return a.id.compareTo(b.id);
      });

      for (var index = 0; index < habits.length; index++) {
        habits[index] = habits[index].withSortOrder(index);
      }
    }

    final habitIds = habits.map((habit) => habit.id).toSet();

    final schedules =
        _readList(
          data['habitScheduleDays'],
          'data.habitScheduleDays',
        ).asMap().entries.map((item) {
          final path = 'data.habitScheduleDays[${item.key}]';
          final row = _readObject(item.value, path);
          final weekday = _readInt(row, 'weekday', path);

          if (weekday < 1 || weekday > 7) {
            throw FormatException('$path.weekday должен быть от 1 до 7.');
          }

          return _ScheduleRecord(
            habitId: _readPositiveInt(row, 'habitId', path),
            weekday: weekday,
          );
        }).toList();

    final scheduleKeys = <String>{};

    for (final schedule in schedules) {
      if (!habitIds.contains(schedule.habitId)) {
        throw FormatException(
          'Расписание ссылается на отсутствующую привычку '
          '${schedule.habitId}.',
        );
      }

      final key = '${schedule.habitId}:${schedule.weekday}';

      if (!scheduleKeys.add(key)) {
        throw FormatException('Повтор расписания: $key.');
      }
    }

    final entries = _readList(data['habitEntries'], 'data.habitEntries')
        .asMap()
        .entries
        .map((item) {
          final path = 'data.habitEntries[${item.key}]';
          final row = _readObject(item.value, path);
          final day = _readString(row, 'day', path);

          _validateDayKey(day, '$path.day');

          return _EntryRecord(
            habitId: _readPositiveInt(row, 'habitId', path),
            day: day,
            completedAt: _readDate(row, 'completedAt', path),
            note: _readNullableString(
              row,
              'note',
              path,
              maxLength: 10 * 1024 * 1024,
            ),
          );
        })
        .toList();

    final entryKeys = <String>{};

    for (final entry in entries) {
      if (!habitIds.contains(entry.habitId)) {
        throw FormatException(
          'Отметка ссылается на отсутствующую привычку '
          '${entry.habitId}.',
        );
      }

      final key = '${entry.habitId}:${entry.day}';

      if (!entryKeys.add(key)) {
        throw FormatException('Повтор отметки выполнения: $key.');
      }
    }

    final tasks = _readList(data['tasks'], 'data.tasks').asMap().entries.map((
      item,
    ) {
      final path = 'data.tasks[${item.key}]';
      final row = _readObject(item.value, path);
      final title = _readString(row, 'title', path, maxLength: 150);
      final priority = _readInt(row, 'priority', path);

      if (title.trim().isEmpty) {
        throw FormatException('$path.title не может быть пустым.');
      }

      if (priority < 0 || priority > 2) {
        throw FormatException('$path.priority должен быть 0, 1 или 2.');
      }

      return _TaskRecord(
        id: _readPositiveInt(row, 'id', path),
        title: title,
        description: _readNullableString(
          row,
          'description',
          path,
          maxLength: 10 * 1024 * 1024,
        ),
        createdAt: _readDate(row, 'createdAt', path),
        dueDate: _readNullableDate(row, 'dueDate', path),
        priority: priority,
        isCompleted: _readBool(row, 'isCompleted', path),
        sortOrder: version >= 2 ? _readInt(row, 'sortOrder', path) : 0,
      );
    }).toList();

    _checkUniqueIds(tasks.map((task) => task.id), 'идентификаторы задач');

    // Для старых резервных копий сохраняем прежний порядок:
    // высокий приоритет выше, внутри приоритета — новые задачи выше.
    if (version == 1) {
      tasks.sort((a, b) {
        final priorityComparison = b.priority.compareTo(a.priority);
        if (priorityComparison != 0) return priorityComparison;

        final createdComparison = b.createdAt.compareTo(a.createdAt);
        if (createdComparison != 0) return createdComparison;

        return a.id.compareTo(b.id);
      });

      for (var index = 0; index < tasks.length; index++) {
        tasks[index] = tasks[index].withSortOrder(index);
      }
    }

    return _ParsedBackup(
      settings: settings,
      habits: habits,
      schedules: schedules,
      entries: entries,
      tasks: tasks,
    );
  }

  Map<String, dynamic> _readObject(dynamic value, String path) {
    if (value is! Map) {
      throw FormatException('$path должен быть JSON-объектом.');
    }

    final result = <String, dynamic>{};

    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('$path содержит ключ не в формате строки.');
      }

      result[entry.key as String] = entry.value;
    }

    return result;
  }

  List<dynamic> _readList(dynamic value, String path) {
    if (value is! List) {
      throw FormatException('$path должен быть JSON-массивом.');
    }

    return value;
  }

  String _readString(
    Map<String, dynamic> row,
    String key,
    String path, {
    int? maxLength,
  }) {
    final value = row[key];

    if (value is! String) {
      throw FormatException('$path.$key должен быть строкой.');
    }

    if (maxLength != null && value.length > maxLength) {
      throw FormatException('$path.$key слишком длинный.');
    }

    return value;
  }

  String? _readNullableString(
    Map<String, dynamic> row,
    String key,
    String path, {
    int? maxLength,
  }) {
    final value = row[key];

    if (value == null) return null;

    if (value is! String) {
      throw FormatException('$path.$key должен быть строкой или null.');
    }

    if (maxLength != null && value.length > maxLength) {
      throw FormatException('$path.$key слишком длинный.');
    }

    return value;
  }

  int _readInt(Map<String, dynamic> row, String key, String path) {
    final value = row[key];

    if (value is! int) {
      throw FormatException('$path.$key должен быть целым числом.');
    }

    return value;
  }

  int _readPositiveInt(Map<String, dynamic> row, String key, String path) {
    final value = _readInt(row, key, path);

    if (value <= 0) {
      throw FormatException('$path.$key должен быть больше нуля.');
    }

    return value;
  }

  bool _readBool(Map<String, dynamic> row, String key, String path) {
    final value = row[key];

    if (value is! bool) {
      throw FormatException('$path.$key должен быть true или false.');
    }

    return value;
  }

  DateTime _readDate(Map<String, dynamic> row, String key, String path) {
    final value = _readString(row, key, path);
    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      throw FormatException('$path.$key содержит неверную дату.');
    }

    return parsed;
  }

  DateTime? _readNullableDate(
    Map<String, dynamic> row,
    String key,
    String path,
  ) {
    final value = row[key];

    if (value == null) return null;

    if (value is! String) {
      throw FormatException('$path.$key должен быть датой или null.');
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      throw FormatException('$path.$key содержит неверную дату.');
    }

    return parsed;
  }

  void _validateDayKey(String value, String path) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('$path должен иметь формат ГГГГ-ММ-ДД.');
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null || _dayKey(parsed) != value) {
      throw FormatException('$path содержит неверную календарную дату.');
    }
  }

  String _dayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  void _checkUniqueIds(Iterable<int> ids, String label) {
    final seen = <int>{};

    for (final id in ids) {
      if (!seen.add(id)) {
        throw FormatException('В резервной копии повторяются $label: $id.');
      }
    }
  }
}

class BackupSummary {
  const BackupSummary({
    required this.settingsCount,
    required this.habitsCount,
    required this.entriesCount,
    required this.tasksCount,
  });

  final int settingsCount;
  final int habitsCount;
  final int entriesCount;
  final int tasksCount;
}

class _ParsedBackup {
  const _ParsedBackup({
    required this.settings,
    required this.habits,
    required this.schedules,
    required this.entries,
    required this.tasks,
  });

  final List<_SettingRecord> settings;
  final List<_HabitRecord> habits;
  final List<_ScheduleRecord> schedules;
  final List<_EntryRecord> entries;
  final List<_TaskRecord> tasks;
}

class _SettingRecord {
  const _SettingRecord({required this.key, required this.value});

  final String key;
  final String value;
}

class _HabitRecord {
  const _HabitRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.isArchived,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final bool isArchived;
  final int sortOrder;

  _HabitRecord withSortOrder(int value) {
    return _HabitRecord(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      isArchived: isArchived,
      sortOrder: value,
    );
  }
}

class _ScheduleRecord {
  const _ScheduleRecord({required this.habitId, required this.weekday});

  final int habitId;
  final int weekday;
}

class _EntryRecord {
  const _EntryRecord({
    required this.habitId,
    required this.day,
    required this.completedAt,
    required this.note,
  });

  final int habitId;
  final String day;
  final DateTime completedAt;
  final String? note;
}

class _TaskRecord {
  const _TaskRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int priority;
  final bool isCompleted;
  final int sortOrder;

  _TaskRecord withSortOrder(int value) {
    return _TaskRecord(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      dueDate: dueDate,
      priority: priority,
      isCompleted: isCompleted,
      sortOrder: value,
    );
  }
}
