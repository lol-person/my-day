import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../../l10n/app_localizations.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const String habitsEnabledKey = 'reminders.habits.enabled';
  static const String habitsHourKey = 'reminders.habits.hour';
  static const String habitsMinuteKey = 'reminders.habits.minute';

  static const String tasksEnabledKey = 'reminders.tasks.enabled';
  static const String tasksHourKey = 'reminders.tasks.hour';
  static const String tasksMinuteKey = 'reminders.tasks.minute';

  static const int habitsReminderId = 42;
  static const int taskReminderIdBase = 100000;
  static const int focusTimerReminderId = 50000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notification'),
    );

    await _plugin.initialize(settings: initializationSettings);

    _initialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final granted = await androidPlugin?.requestNotificationsPermission();

    return granted ?? true;
  }

  Future<void> syncAll(AppDatabase database) async {
    if (!_initialized) return;

    await _syncHabitReminder(database);
    await _syncTaskReminders(database);
  }

  Future<bool> scheduleFocusCompletion(DateTime deadline) async {
    await initialize();
    final granted = await requestNotificationPermission();
    if (!granted) return false;
    final l10n = await _appLocalizations();
    await _plugin.zonedSchedule(
      id: focusTimerReminderId,
      title: l10n.notificationFocusTitle,
      body: l10n.notificationFocusBody,
      scheduledDate: tz.TZDateTime.from(deadline, tz.local),
      notificationDetails: _notificationDetails(l10n),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  Future<void> cancelFocusCompletion() async {
    await initialize();
    await _plugin.cancel(id: focusTimerReminderId);
  }

  Future<void> _syncHabitReminder(AppDatabase database) async {
    await _plugin.cancel(id: habitsReminderId);

    final enabled = await database.getSetting(habitsEnabledKey) == 'true';

    if (!enabled) return;

    final activeHabits =
        await (database.select(database.habits)
              ..where((habit) => habit.isArchived.equals(false))
              ..where((habit) => habit.deletedAt.isNull()))
            .get();

    if (activeHabits.isEmpty) return;
    final l10n = await _appLocalizations();

    final hour = await _readTimePart(
      database,
      habitsHourKey,
      fallback: 8,
      maximum: 23,
    );

    final minute = await _readTimePart(
      database,
      habitsMinuteKey,
      fallback: 30,
      maximum: 59,
    );

    final now = tz.TZDateTime.now(tz.local);

    var firstReminder = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!firstReminder.isAfter(now)) {
      firstReminder = firstReminder.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: habitsReminderId,
      title: l10n.notificationHabitsTitle,
      body: l10n.notificationHabitsBody,
      scheduledDate: firstReminder,
      notificationDetails: _notificationDetails(l10n),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _syncTaskReminders(AppDatabase database) async {
    final pending = await _plugin.pendingNotificationRequests();

    for (final request in pending) {
      if (request.id >= taskReminderIdBase) {
        await _plugin.cancel(id: request.id);
      }
    }

    final enabled = await database.getSetting(tasksEnabledKey) == 'true';

    if (!enabled) return;

    final hour = await _readTimePart(
      database,
      tasksHourKey,
      fallback: 9,
      maximum: 23,
    );

    final minute = await _readTimePart(
      database,
      tasksMinuteKey,
      fallback: 0,
      maximum: 59,
    );

    final now = tz.TZDateTime.now(tz.local);

    final tasks = await database.select(database.tasks).get();

    final tasksWithDeadlines =
        tasks
            .where(
              (task) =>
                  task.deletedAt == null &&
                  !task.isCompleted &&
                  task.dueDate != null,
            )
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final l10n = await _appLocalizations();

    for (final task in tasksWithDeadlines) {
      final dueDate = task.dueDate!;

      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

      final dueReminder = _atTime(dueDay, hour, minute);

      final dayBeforeReminder = _atTime(
        dueDay.subtract(const Duration(days: 1)),
        hour,
        minute,
      );

      final dayBeforeId = taskReminderIdBase + task.id * 2 + 1;

      if (dayBeforeReminder.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: dayBeforeId,
          title: l10n.notificationTaskTomorrow,
          body: task.title,
          scheduledDate: dayBeforeReminder,
          notificationDetails: _notificationDetails(l10n),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      final dueReminderId = taskReminderIdBase + task.id * 2;

      if (dueReminder.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: dueReminderId,
          title: l10n.notificationTaskToday,
          body: task.title,
          scheduledDate: dueReminder,
          notificationDetails: _notificationDetails(l10n),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  Future<int> _readTimePart(
    AppDatabase database,
    String key, {
    required int fallback,
    required int maximum,
  }) async {
    final rawValue = await database.getSetting(key);
    final value = int.tryParse(rawValue ?? '');

    if (value == null || value < 0 || value > maximum) {
      return fallback;
    }

    return value;
  }

  tz.TZDateTime _atTime(DateTime date, int hour, int minute) {
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  Future<AppLocalizations> _appLocalizations() {
    final languageCode = PlatformDispatcher.instance.locale.languageCode;
    return AppLocalizations.delegate.load(
      Locale(languageCode == 'en' ? 'en' : 'ru'),
    );
  }

  NotificationDetails _notificationDetails(AppLocalizations l10n) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'productivity_reminders',
          l10n.remindersTitle,
          channelDescription: l10n.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
}
