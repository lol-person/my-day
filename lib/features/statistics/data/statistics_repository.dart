import '../../../core/database/app_database.dart';

class StatisticsRepository {
  StatisticsRepository(this._database);

  final AppDatabase _database;

  Future<StatisticsData> load({required int periodDays, DateTime? now}) async {
    if (![7, 30, 90].contains(periodDays)) {
      throw ArgumentError.value(periodDays, 'periodDays');
    }
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final start = today.subtract(Duration(days: periodDays - 1));
    final startKey = _dateKey(start);
    final endKey = _dateKey(today);

    final habits = await _database.select(_database.habits).get();
    final activeHabits = habits
        .where((habit) => !habit.isArchived && habit.deletedAt == null)
        .toList();
    final schedules = await _database.select(_database.habitScheduleDays).get();
    final entries = await _database.select(_database.habitEntries).get();
    final focusSessions = await _database.select(_database.focusSessions).get();
    final tasks = await (_database.select(
      _database.tasks,
    )..where((task) => task.deletedAt.isNull())).get();

    final schedulesByHabit = <int, Set<int>>{};
    for (final schedule in schedules) {
      (schedulesByHabit[schedule.habitId] ??= <int>{}).add(schedule.weekday);
    }

    final entriesByHabitAndDay = <String>{};
    final entriesByDay = <String, int>{};
    var allTimeHabitCompletions = 0;
    for (final entry in entries) {
      allTimeHabitCompletions++;
      entriesByHabitAndDay.add('${entry.habitId}:${entry.day}');
      if (_isInRange(entry.day, startKey, endKey)) {
        entriesByDay.update(entry.day, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    var scheduledOccurrences = 0;
    var completedScheduledOccurrences = 0;
    for (final habit in activeHabits) {
      final weekdays = schedulesByHabit[habit.id] ?? const <int>{};
      final createdDay = DateTime(
        habit.createdAt.year,
        habit.createdAt.month,
        habit.createdAt.day,
      );
      var day = createdDay.isAfter(start) ? createdDay : start;
      while (!day.isAfter(today)) {
        if (weekdays.contains(day.weekday)) {
          scheduledOccurrences++;
          if (entriesByHabitAndDay.contains('${habit.id}:${_dateKey(day)}')) {
            completedScheduledOccurrences++;
          }
        }
        day = day.add(const Duration(days: 1));
      }
    }

    final focusByDay = <String, List<int>>{};
    var allTimeFocusSeconds = 0;
    for (final session in focusSessions) {
      allTimeFocusSeconds += session.durationSeconds;
      final completedDay = _dateKey(session.completedAt);
      if (_isInRange(completedDay, startKey, endKey)) {
        final values = focusByDay.putIfAbsent(completedDay, () => [0, 0]);
        values[0]++;
        values[1] += session.durationSeconds;
      }
    }

    final days = List<DailyStatistics>.generate(periodDays, (index) {
      final date = start.add(Duration(days: index));
      final key = _dateKey(date);
      final focus = focusByDay[key] ?? const [0, 0];
      return DailyStatistics(
        date: date,
        habitCompletions: entriesByDay[key] ?? 0,
        focusSessions: focus[0],
        focusSeconds: focus[1],
      );
    });

    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final overdueTasks = tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;
      final dueDate = task.dueDate!;
      return DateTime(dueDate.year, dueDate.month, dueDate.day).isBefore(today);
    }).length;

    return StatisticsData(
      periodDays: periodDays,
      periodStart: start,
      periodEnd: today,
      scheduledHabitOccurrences: scheduledOccurrences,
      completedScheduledHabitOccurrences: completedScheduledOccurrences,
      periodHabitCompletions: entriesByDay.values.fold(0, (a, b) => a + b),
      allTimeHabitCompletions: allTimeHabitCompletions,
      periodFocusSessions: focusByDay.values.fold(0, (a, b) => a + b[0]),
      periodFocusSeconds: focusByDay.values.fold(0, (a, b) => a + b[1]),
      allTimeFocusSessions: focusSessions.length,
      allTimeFocusSeconds: allTimeFocusSeconds,
      totalTasks: tasks.length,
      completedTasks: completedTasks,
      openTasks: tasks.length - completedTasks,
      overdueTasks: overdueTasks,
      days: days,
    );
  }

  static bool _isInRange(String day, String start, String end) =>
      day.compareTo(start) >= 0 && day.compareTo(end) <= 0;

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class StatisticsData {
  const StatisticsData({
    required this.periodDays,
    required this.periodStart,
    required this.periodEnd,
    required this.scheduledHabitOccurrences,
    required this.completedScheduledHabitOccurrences,
    required this.periodHabitCompletions,
    required this.allTimeHabitCompletions,
    required this.periodFocusSessions,
    required this.periodFocusSeconds,
    required this.allTimeFocusSessions,
    required this.allTimeFocusSeconds,
    required this.totalTasks,
    required this.completedTasks,
    required this.openTasks,
    required this.overdueTasks,
    required this.days,
  });

  final int periodDays;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int scheduledHabitOccurrences;
  final int completedScheduledHabitOccurrences;
  final int periodHabitCompletions;
  final int allTimeHabitCompletions;
  final int periodFocusSessions;
  final int periodFocusSeconds;
  final int allTimeFocusSessions;
  final int allTimeFocusSeconds;
  final int totalTasks;
  final int completedTasks;
  final int openTasks;
  final int overdueTasks;
  final List<DailyStatistics> days;

  double get habitCompletionRate => scheduledHabitOccurrences == 0
      ? 0
      : completedScheduledHabitOccurrences / scheduledHabitOccurrences;
}

class DailyStatistics {
  const DailyStatistics({
    required this.date,
    required this.habitCompletions,
    required this.focusSessions,
    required this.focusSeconds,
  });

  final DateTime date;
  final int habitCompletions;
  final int focusSessions;
  final int focusSeconds;
}
