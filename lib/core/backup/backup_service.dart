import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../widgets/today_widget_service.dart';

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  static const String formatName = 'productivity_app_backup';
  static const int formatVersion = 4;
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

  Future<Uint8List> createBackup() async {
    final settings = await _database.select(_database.appSettings).get();
    final habits = await _database.select(_database.habits).get();
    final schedules = await _database.select(_database.habitScheduleDays).get();
    final entries = await _database.select(_database.habitEntries).get();
    final tasks = await _database.select(_database.tasks).get();
    final focusTimerState = await _database
        .select(_database.focusTimerState)
        .get();
    final focusSessions = await _database.select(_database.focusSessions).get();

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
                'deletedAt': habit.deletedAt?.toIso8601String(),
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
                'deletedAt': task.deletedAt?.toIso8601String(),
              },
            )
            .toList(),
        'focusTimerState': focusTimerState
            .map(
              (state) => <String, dynamic>{
                'id': state.id,
                'phase': state.phase,
                'status': state.status,
                'completedWorkSessions': state.completedWorkSessions,
                'sessionStartedAt': state.sessionStartedAt?.toIso8601String(),
                'deadline': state.deadline?.toIso8601String(),
                'segmentStartedAt': state.segmentStartedAt?.toIso8601String(),
                'remainingSeconds': state.remainingSeconds,
                'elapsedSeconds': state.elapsedSeconds,
              },
            )
            .toList(),
        'focusSessions': focusSessions
            .map(
              (session) => <String, dynamic>{
                'id': session.id,
                'startedAt': session.startedAt.toIso8601String(),
                'completedAt': session.completedAt.toIso8601String(),
                'durationSeconds': session.durationSeconds,
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

    await _database.transaction(() async {
      await _database.delete(_database.tasks).go();
      await _database.delete(_database.focusSessions).go();
      await _database.delete(_database.focusTimerState).go();
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
                deletedAt: Value(habit.deletedAt),
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
                deletedAt: Value(task.deletedAt),
              ),
            );
      }

      final focusState = parsed.focusTimerState;
      if (focusState != null) {
        await _database
            .into(_database.focusTimerState)
            .insert(
              FocusTimerStateCompanion.insert(
                id: Value(focusState.id),
                phase: focusState.phase,
                status: focusState.status,
                completedWorkSessions: focusState.completedWorkSessions,
                sessionStartedAt: Value(focusState.sessionStartedAt),
                deadline: Value(focusState.deadline),
                segmentStartedAt: Value(focusState.segmentStartedAt),
                remainingSeconds: Value(focusState.remainingSeconds),
                elapsedSeconds: focusState.elapsedSeconds,
              ),
            );
      }

      for (final session in parsed.focusSessions) {
        await _database
            .into(_database.focusSessions)
            .insert(
              FocusSessionsCompanion.insert(
                id: Value(session.id),
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                durationSeconds: session.durationSeconds,
              ),
            );
      }
    });

    try {
      await TodayWidgetService.update(_database);
    } catch (_) {}

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

    if (version < 1 || version > formatVersion || version == 0) {
      throw FormatException(
        'Версия резервной копии $version не поддерживается. '
        'Поддерживаются версии 1, 2, 3 и $formatVersion.',
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
          deletedAt: version >= 4
              ? _readNullableDate(row, 'deletedAt', path)
              : null,
        );
      },
    ).toList();

    _checkUniqueIds(habits.map((habit) => habit.id), 'идентификаторы привычек');

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
        deletedAt: version >= 4
            ? _readNullableDate(row, 'deletedAt', path)
            : null,
      );
    }).toList();

    _checkUniqueIds(tasks.map((task) => task.id), 'идентификаторы задач');

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

    final focusStateRows = version >= 3
        ? _readList(data['focusTimerState'], 'data.focusTimerState')
        : <dynamic>[];
    if (focusStateRows.length > 1) {
      throw const FormatException(
        'В копии может быть только один таймер фокуса.',
      );
    }
    final focusState = focusStateRows.isEmpty
        ? null
        : _parseFocusState(focusStateRows.single);
    final focusSessions = version >= 3
        ? _readList(data['focusSessions'], 'data.focusSessions')
              .asMap()
              .entries
              .map((item) => _parseFocusSession(item.value, item.key))
              .toList()
        : <_FocusSessionRecord>[];
    _checkUniqueIds(focusSessions.map((session) => session.id), 'фокус-сессии');

    return _ParsedBackup(
      settings: settings,
      habits: habits,
      schedules: schedules,
      entries: entries,
      tasks: tasks,
      focusTimerState: focusState,
      focusSessions: focusSessions,
    );
  }

  _FocusStateRecord _parseFocusState(dynamic value) {
    final row = _readObject(value, 'data.focusTimerState[0]');
    final phase = _readString(row, 'phase', 'data.focusTimerState[0]');
    final status = _readString(row, 'status', 'data.focusTimerState[0]');
    if (!const {'work', 'shortBreak', 'longBreak'}.contains(phase) ||
        !const {'ready', 'running', 'paused'}.contains(status)) {
      throw const FormatException('Состояние таймера фокуса некорректно.');
    }
    final remainingValue = row['remainingSeconds'];
    final maxRemainingSeconds = switch (phase) {
      'work' => 25 * 60,
      'shortBreak' => 5 * 60,
      'longBreak' => 15 * 60,
      _ => 0,
    };
    if (remainingValue != null &&
        (remainingValue is! int ||
            remainingValue < 0 ||
            remainingValue > maxRemainingSeconds)) {
      throw const FormatException('Остаток времени таймера некорректен.');
    }
    final completed = _readInt(
      row,
      'completedWorkSessions',
      'data.focusTimerState[0]',
    );
    final elapsed = _readInt(row, 'elapsedSeconds', 'data.focusTimerState[0]');
    if (completed < 0 || completed > 3 || elapsed < 0 || elapsed > 1500) {
      throw const FormatException('Показатели фокус-сессии некорректны.');
    }
    final id = _readPositiveInt(row, 'id', 'data.focusTimerState[0]');
    if (id != 1) {
      throw const FormatException(
        'Идентификатор таймера фокуса должен быть равен 1.',
      );
    }
    return _FocusStateRecord(
      id: id,
      phase: phase,
      status: status,
      completedWorkSessions: completed,
      sessionStartedAt: _readNullableDate(
        row,
        'sessionStartedAt',
        'data.focusTimerState[0]',
      ),
      deadline: _readNullableDate(row, 'deadline', 'data.focusTimerState[0]'),
      segmentStartedAt: _readNullableDate(
        row,
        'segmentStartedAt',
        'data.focusTimerState[0]',
      ),
      remainingSeconds: remainingValue as int?,
      elapsedSeconds: elapsed,
    );
  }

  _FocusSessionRecord _parseFocusSession(dynamic value, int index) {
    final path = 'data.focusSessions[$index]';
    final row = _readObject(value, path);
    final duration = _readPositiveInt(row, 'durationSeconds', path);
    if (duration > 1500) {
      throw FormatException('$path.durationSeconds превышает 25 минут.');
    }
    return _FocusSessionRecord(
      id: _readPositiveInt(row, 'id', path),
      startedAt: _readDate(row, 'startedAt', path),
      completedAt: _readDate(row, 'completedAt', path),
      durationSeconds: duration,
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
    required this.focusTimerState,
    required this.focusSessions,
  });

  final List<_SettingRecord> settings;
  final List<_HabitRecord> habits;
  final List<_ScheduleRecord> schedules;
  final List<_EntryRecord> entries;
  final List<_TaskRecord> tasks;
  final _FocusStateRecord? focusTimerState;
  final List<_FocusSessionRecord> focusSessions;
}

class _FocusStateRecord {
  const _FocusStateRecord({
    required this.id,
    required this.phase,
    required this.status,
    required this.completedWorkSessions,
    required this.sessionStartedAt,
    required this.deadline,
    required this.segmentStartedAt,
    required this.remainingSeconds,
    required this.elapsedSeconds,
  });

  final int id;
  final String phase;
  final String status;
  final int completedWorkSessions;
  final DateTime? sessionStartedAt;
  final DateTime? deadline;
  final DateTime? segmentStartedAt;
  final int? remainingSeconds;
  final int elapsedSeconds;
}

class _FocusSessionRecord {
  const _FocusSessionRecord({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
  });

  final int id;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;
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
    required this.deletedAt,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final bool isArchived;
  final int sortOrder;
  final DateTime? deletedAt;

  _HabitRecord withSortOrder(int value) {
    return _HabitRecord(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      isArchived: isArchived,
      sortOrder: value,
      deletedAt: deletedAt,
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
    required this.deletedAt,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int priority;
  final bool isCompleted;
  final int sortOrder;
  final DateTime? deletedAt;

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
      deletedAt: deletedAt,
    );
  }
}
