import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';

class TodayWidgetService {
  TodayWidgetService._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.productivity_app/today_widget',
  );

  static Future<TodayWidgetSnapshot> readSnapshot(
    AppDatabase database, {
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final todayKey = _dateKey(current);
    final habits =
        await (database.select(database.habits)..where(
              (habit) =>
                  habit.isArchived.equals(false) & habit.deletedAt.isNull(),
            ))
            .get();
    final habitIds = habits.map((habit) => habit.id).toSet();
    final schedules =
        await (database.select(database.habitScheduleDays)..where(
              (schedule) =>
                  schedule.weekday.equals(current.weekday) &
                  schedule.habitId.isIn(habitIds),
            ))
            .get();
    final scheduledIds = schedules.map((schedule) => schedule.habitId).toSet();
    final entries = await (database.select(
      database.habitEntries,
    )..where((entry) => entry.day.equals(todayKey))).get();
    final completedIds = entries.map((entry) => entry.habitId).toSet();
    final completedHabits = scheduledIds.intersection(completedIds).length;
    final activeTasks =
        await (database.select(database.tasks)..where(
              (task) =>
                  task.isCompleted.equals(false) & task.deletedAt.isNull(),
            ))
            .get();
    final totalHabits = scheduledIds.length;
    final progressPercent = totalHabits == 0
        ? 0
        : (completedHabits * 100 / totalHabits).round();

    return TodayWidgetSnapshot(
      completedHabits: completedHabits,
      totalHabits: totalHabits,
      activeTasks: activeTasks.length,
      progressPercent: progressPercent,
    );
  }

  static Future<void> update(AppDatabase database) async {
    try {
      final snapshot = await readSnapshot(database);
      await _channel.invokeMethod<void>('updateToday', snapshot.toMap());
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<String?> getInitialTarget() async {
    try {
      return await _channel.invokeMethod<String>('getInitialTarget');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static void setTargetHandler(ValueChanged<String> onTarget) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'openTarget' || call.arguments is! String) return;
      onTarget(call.arguments as String);
    });
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class TodayWidgetSnapshot {
  const TodayWidgetSnapshot({
    required this.completedHabits,
    required this.totalHabits,
    required this.activeTasks,
    required this.progressPercent,
  });

  final int completedHabits;
  final int totalHabits;
  final int activeTasks;
  final int progressPercent;

  Map<String, int> toMap() => {
    'completedHabits': completedHabits,
    'totalHabits': totalHabits,
    'activeTasks': activeTasks,
  };
}
