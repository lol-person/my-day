// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Day';

  @override
  String get settings => 'Settings';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get choose => 'Choose';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get restore => 'Restore';

  @override
  String get loading => 'Loading…';

  @override
  String get today => 'Today';

  @override
  String get tasks => 'Tasks';

  @override
  String get habits => 'Habits';

  @override
  String get archive => 'Archive';

  @override
  String get trash => 'Trash';

  @override
  String get statistics => 'Statistics';

  @override
  String get reminders => 'Reminders';

  @override
  String get calendar => 'Calendar';

  @override
  String get focusSession => 'Focus session';

  @override
  String get clock => 'Clock';

  @override
  String get backup => 'Backup and restore';

  @override
  String get newTask => 'New task';

  @override
  String get taskTitle => 'Task name';

  @override
  String get editTask => 'Edit task';

  @override
  String get taskTitleRequired => 'Enter a task name';

  @override
  String get taskTitleTooLong => 'Maximum 150 characters';

  @override
  String get taskDescription => 'Description (optional)';

  @override
  String get taskHint => 'For example, buy groceries';

  @override
  String get taskDueDate => 'Due date';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get removeDueDate => 'Remove due date';

  @override
  String get priority => 'Priority';

  @override
  String get lowPriority => 'Low';

  @override
  String get normalPriority => 'Normal';

  @override
  String get highPriority => 'High';

  @override
  String get activeFilter => 'Active';

  @override
  String get completedFilter => 'Completed';

  @override
  String get allFilter => 'All';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get addFirstTask => 'Add your first task to plan your day.';

  @override
  String get tasksIntro => 'Plan your day and check things off.';

  @override
  String get allTasksComplete => 'All tasks are complete';

  @override
  String get noActiveTasks => 'There are no active tasks.';

  @override
  String get noCompletedTasks => 'No completed tasks';

  @override
  String get completedTasksAppear => 'Completed tasks will appear here.';

  @override
  String get noResults => 'No results';

  @override
  String get changeFilters => 'Try changing the filters.';

  @override
  String get taskAdded => 'Task added';

  @override
  String get taskUpdated => 'Task updated';

  @override
  String get taskSavedFailed => 'Couldn\'t save the task. Try again.';

  @override
  String get taskLoadFailed => 'Couldn\'t load tasks. Try again.';

  @override
  String get taskOrderSaved => 'Task order saved';

  @override
  String get taskOrderFailed => 'Couldn\'t save the task order. Try again.';

  @override
  String get taskDeleted => 'Task moved to Trash';

  @override
  String get taskRestored => 'Task restored';

  @override
  String get taskUpdateFailed => 'Couldn\'t update the task. Try again.';

  @override
  String get taskDeleteFailed => 'Couldn\'t delete the task. Try again.';

  @override
  String get taskRestoreFailed => 'Couldn\'t restore the task.';

  @override
  String taskMovedToTrashTitle(String title) {
    return '“$title” moved to Trash';
  }

  @override
  String get taskOrderHint =>
      'Drag the handle on the right to change the order.';

  @override
  String get taskOverdue => 'Overdue';

  @override
  String get taskActions => 'Task actions';

  @override
  String get edit => 'Edit';

  @override
  String get moveToTrash => 'Move to Trash';

  @override
  String get undo => 'Undo';

  @override
  String taskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '$count task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String habitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits',
      one: '$count habit',
      zero: 'No habits',
    );
    return '$_temp0';
  }

  @override
  String get newHabit => 'New habit';

  @override
  String get addHabit => 'Add habit';

  @override
  String get habitTitle => 'Habit name';

  @override
  String get habitHint => 'For example, read for 15 minutes';

  @override
  String get habitSchedule => 'Which days will you do this?';

  @override
  String get habitEmpty => 'No habits yet';

  @override
  String get habitEmptyDescription =>
      'Add your first habit to start tracking your progress.';

  @override
  String get noHabitsToday => 'Nothing planned for today';

  @override
  String get noHabitsTodayDescription =>
      'Your active habits are scheduled for other days. Take a break or add a new habit.';

  @override
  String get todayProgress => 'Today\'s progress';

  @override
  String get habitsToday => 'My habits for today';

  @override
  String completedOfTotal(int completed, int total) {
    return '$completed of $total completed';
  }

  @override
  String get noHabitsScheduledToday => 'No habits scheduled for today';

  @override
  String get dragToReorderHabit => 'Drag the handle to reorder habits.';

  @override
  String get habitActions => 'Habit actions';

  @override
  String get editHabit => 'Edit habit';

  @override
  String get archiveHabit => 'Archive habit';

  @override
  String get habitArchived => 'Habit archived';

  @override
  String get habitRestored => 'Habit restored';

  @override
  String get habitMovedToTrash => 'Habit moved to Trash';

  @override
  String habitMovedToTrashTitle(String title) {
    return '“$title” moved to Trash';
  }

  @override
  String habitRestoredTitle(String title) {
    return '“$title” restored';
  }

  @override
  String get habitTrashUndo => 'Habit restored to the archive';

  @override
  String get habitTrashFailed => 'Couldn\'t move the habit to Trash.';

  @override
  String get habitRestoreFailed => 'Couldn\'t restore the habit.';

  @override
  String habitOrderFailed(String error) {
    return 'Couldn\'t save the habit order: $error';
  }

  @override
  String get habitSaved => 'Habit saved';

  @override
  String get habitCreated => 'Habit added';

  @override
  String habitSaveFailed(String error) {
    return 'Couldn\'t save the habit: $error';
  }

  @override
  String habitCompletionFailed(String error) {
    return 'Couldn\'t update the habit: $error';
  }

  @override
  String get habitActionFailed => 'Couldn\'t update the habit. Try again.';

  @override
  String get habitDataSaveFailed => 'Couldn\'t save changes. Try again.';

  @override
  String get archiveConfirmTitle => 'Archive this habit?';

  @override
  String archiveConfirmBody(String title) {
    return '“$title” will leave your active list. Its completion history will be kept.';
  }

  @override
  String get habitDeleteConfirmTitle => 'Move this habit to Trash?';

  @override
  String habitDeleteConfirmBody(String title) {
    return '“$title” and its schedule will be moved to Trash. Its history will be kept.';
  }

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String habitScheduleLabel(String days) {
    return 'Schedule: $days';
  }

  @override
  String habitCompletionProgress(int completed, int total) {
    return '$completed of $total completed';
  }

  @override
  String get habitLoadFailed => 'Couldn\'t load habits. Try again.';

  @override
  String get enterHabitName => 'Enter a habit name';

  @override
  String get chooseWeekday => 'Choose at least one day of the week';

  @override
  String get archiveHabits => 'Archived habits';

  @override
  String get emptyArchive => 'Your archive is empty';

  @override
  String get emptyArchiveDescription =>
      'Habits you temporarily remove from your active list will be kept here.';

  @override
  String archivedHabitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# habits in the archive',
      one: '# habit in the archive',
    );
    return '$_temp0';
  }

  @override
  String get restoreHabit => 'Restore habit';

  @override
  String get archiveLoadFailed => 'Couldn\'t load the archive. Try again.';

  @override
  String get calendarPlan => 'Daily plan';

  @override
  String get selectDate => 'Select date';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get noHabitsScheduled => 'No habits scheduled';

  @override
  String get noHabitsScheduledDescription =>
      'No active habits are scheduled for this date.';

  @override
  String get openHabits => 'Open habits';

  @override
  String get noTasksForDate => 'No tasks due on this date';

  @override
  String get noTasksForDateDescription =>
      'Tasks due on this date will appear here.';

  @override
  String get lowPriorityLong => 'Low priority';

  @override
  String get normalPriorityLong => 'Normal priority';

  @override
  String get highPriorityLong => 'High priority';

  @override
  String get statisticsPeriod => 'Period';

  @override
  String get days7 => '7 days';

  @override
  String get days30 => '30 days';

  @override
  String get days90 => '90 days';

  @override
  String get selectedPeriod => 'Selected period';

  @override
  String get dailyTrend => 'Daily trend';

  @override
  String get allTime => 'All time';

  @override
  String get tasksNow => 'Tasks now';

  @override
  String get scheduleCompletion => 'Schedule completion';

  @override
  String scheduleCompletionCount(int completed, int total) {
    return '$completed of $total days completed';
  }

  @override
  String habitCompletionCount(int count) {
    return 'Habit check-ins: $count';
  }

  @override
  String get completedPomodoros => 'Completed Pomodoro sessions';

  @override
  String focusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '$count session',
      zero: 'No sessions',
    );
    return '$_temp0';
  }

  @override
  String get noPeriodActivity =>
      'No habit check-ins or completed focus sessions in this period.';

  @override
  String totalTasks(String tasks) {
    return 'Tasks: $tasks';
  }

  @override
  String completed(int count) {
    return 'Completed: $count';
  }

  @override
  String inProgress(int count) {
    return 'In progress: $count';
  }

  @override
  String overdueNow(int count) {
    return 'Overdue now: $count';
  }

  @override
  String get statisticsLoadFailed => 'Couldn\'t load statistics.';

  @override
  String get focusWork => 'Work';

  @override
  String get focusShortBreak => 'Short break';

  @override
  String get focusLongBreak => 'Long break';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get finishEarly => 'End early';

  @override
  String get skipBreak => 'Skip break';

  @override
  String get focusHistory => 'History';

  @override
  String get focusHistoryEmpty => 'Completed work sessions will appear here.';

  @override
  String focusMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes focused',
      one: '$count minute focused',
      zero: 'No focus time',
    );
    return '$_temp0';
  }

  @override
  String get focusLoadFailed => 'Couldn\'t load the focus session.';

  @override
  String get notificationPermission =>
      'Allow notifications to receive the timer alert.';

  @override
  String get notificationScheduleFailed =>
      'Couldn\'t schedule the notification.';

  @override
  String get clockNow => 'NOW';

  @override
  String clockSeconds(String seconds) {
    return 'SECONDS $seconds';
  }

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get trashEmptyDescription =>
      'Deleted tasks and habits stay here until you restore or permanently delete them.';

  @override
  String get deletePermanentlyTitle => 'Delete permanently?';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String habitPermanentDeleteConfirm(String title) {
    return 'Habit “$title”, its schedule, and completion history will be permanently deleted.';
  }

  @override
  String taskPermanentDeleteConfirm(String title) {
    return 'Task “$title” will be permanently deleted.';
  }

  @override
  String get trashUpdated => 'Trash updated';

  @override
  String get actionFailed => 'Couldn\'t complete that action. Try again.';

  @override
  String trashedDate(String date) {
    return 'Deleted $date';
  }

  @override
  String get archivedHabit => 'Archived';

  @override
  String get activeHabit => 'Active';

  @override
  String get backupRestore => 'Backup and restore';

  @override
  String get backupTitle => 'Your data stays in your hands';

  @override
  String get backupDescription =>
      'Your backup is saved wherever you choose. The app never sends it to a server.';

  @override
  String get createBackup => 'Create a backup';

  @override
  String get backupExportDescription =>
      'Save your tasks, habits, schedules, completion history, and settings in one JSON file.';

  @override
  String get restoreBackup => 'Restore from backup';

  @override
  String get backupImportDescription =>
      'Choose a backup file. Its contents will replace the data currently on this device.';

  @override
  String get exportData => 'Export data';

  @override
  String get chooseAndRestore => 'Choose a file and restore';

  @override
  String get processingData => 'Processing data…';

  @override
  String get backupCreated => 'Backup saved.';

  @override
  String get backupCanceled => 'Saving canceled.';

  @override
  String get backupCreateFailed => 'Couldn\'t create the backup. Try again.';

  @override
  String get restoreConfirmTitle => 'Restore data?';

  @override
  String get restoreConfirmBody =>
      'Your current tasks, habits, completion history, and settings will be replaced with the contents of this backup. This can\'t be undone. Create a backup of your current data first.';

  @override
  String restoreComplete(int tasks, int habits, int entries, int settings) {
    return 'Data restored. Tasks: $tasks, habits: $habits, check-ins: $entries, settings: $settings.';
  }

  @override
  String restoreCompleteWithWarning(
    int tasks,
    int habits,
    int entries,
    int settings,
  ) {
    return 'Data restored. Tasks: $tasks, habits: $habits, check-ins: $entries, settings: $settings. Couldn\'t refresh reminder schedules—check your reminder settings.';
  }

  @override
  String get restoreFailed =>
      'Couldn\'t restore the backup. Check that the file is a valid app backup and try again.';

  @override
  String get backupPrivacy =>
      'Keep the file somewhere safe. JSON backups aren\'t encrypted, so anyone with the file can read its contents. To move your data to another device, copy the file and import it there.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceDescription =>
      'Choose the look that works for you. Changes take effect right away.';

  @override
  String get appTheme => 'App theme';

  @override
  String get appLanguage => 'App language';

  @override
  String get systemLanguage => 'System';

  @override
  String get russianLanguage => 'Russian';

  @override
  String get englishLanguage => 'English';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemThemeDescription => 'Follows your Android settings.';

  @override
  String get lightThemeDescription => 'Always use the light theme.';

  @override
  String get darkThemeDescription => 'Always use the dark theme.';

  @override
  String get accentColor => 'Accent color';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorRed => 'Red';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorTeal => 'Teal';

  @override
  String get accentDescription =>
      'Changes the accent color of buttons, highlights, and the main panel.';

  @override
  String get dataStorage => 'Data storage';

  @override
  String get localDatabase => 'Local database';

  @override
  String get localDatabaseDescription =>
      'Tasks, habits, and settings stay on this device. Your theme and selected color are included when you export settings.';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get accentSaved => 'Accent color saved';

  @override
  String get settingsSaveFailed => 'Couldn\'t save settings. Try again.';

  @override
  String get accentSaveFailed => 'Couldn\'t save the accent color. Try again.';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get habitsReminder => 'Habit reminders';

  @override
  String get tasksReminder => 'Task reminders';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get saveReminderFailed => 'Couldn\'t save reminder settings.';

  @override
  String get notificationFocusTitle => 'Interval complete';

  @override
  String get notificationFocusBody =>
      'You can move on to the next part of your focus session.';

  @override
  String get notificationHabitsTitle => 'Time to check your habits';

  @override
  String get notificationHabitsBody =>
      'Check off the habits scheduled for today.';

  @override
  String get notificationTaskTomorrow => 'Due tomorrow';

  @override
  String get notificationTaskToday => 'Due today';

  @override
  String get notificationChannelDescription =>
      'Habit reminders and task due dates';

  @override
  String get homeMorning => 'Good morning!';

  @override
  String get homeAfternoon => 'Good afternoon!';

  @override
  String get homeEvening => 'Good evening!';

  @override
  String get homeHeadline => 'Small steps.\nBig results.';

  @override
  String get homeMessage =>
      'Choose what matters, make steady progress, and build habits that last.';

  @override
  String get openClock => 'Open Flip Clock';

  @override
  String get openFocus => 'Start a Pomodoro session';

  @override
  String get openCalendar => 'Open calendar and daily plan';

  @override
  String get openHabitTracker => 'Open habit tracker';

  @override
  String get openTaskList => 'Open task list';

  @override
  String get openStatistics => 'View statistics';

  @override
  String get openReminders => 'Manage reminders';

  @override
  String get openBackup => 'Backup and restore data';

  @override
  String get welcomeHeadline => 'Make today count.';

  @override
  String get restorePending =>
      'Couldn\'t refresh reminder schedules. Check your reminder settings.';

  @override
  String get fileTooLarge => 'The file is larger than 25 MB.';

  @override
  String timerSessionsUntilLongBreak(int count) {
    return 'Work sessions until a long break: $count';
  }

  @override
  String breakSessionsUntilLongBreak(int count) {
    return 'Work sessions until a long break: $count';
  }

  @override
  String get calendarPickHelp => 'Choose a date';

  @override
  String calendarWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarLoadFailed => 'Couldn\'t load the daily plan.';

  @override
  String get habitUpdateFailed => 'Couldn\'t update the habit.';

  @override
  String get dailyPlanHabits => 'Habits';

  @override
  String get dailyPlanTasks => 'Tasks due on this date';

  @override
  String get done => 'Done';

  @override
  String get weekdayShortMon => 'MON';

  @override
  String get weekdayShortTue => 'TUE';

  @override
  String get weekdayShortWed => 'WED';

  @override
  String get weekdayShortThu => 'THU';

  @override
  String get weekdayShortFri => 'FRI';

  @override
  String get weekdayShortSat => 'SAT';

  @override
  String get weekdayShortSun => 'SUN';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get statisticsRefresh => 'Refresh statistics';

  @override
  String habitCheckinsInPeriod(int count) {
    return 'Habit check-ins this period: $count';
  }

  @override
  String get statsScheduleNote =>
      'Uses the current schedule; schedule changes aren\'t tracked historically.';

  @override
  String focusStatPeriod(String sessions, String duration) {
    return '$sessions · $duration focused';
  }

  @override
  String habitTrend(int count) {
    return 'Habits: $count';
  }

  @override
  String allTimeHabitCheckins(int count) {
    return 'Habit check-ins: $count';
  }

  @override
  String allTimePomodoros(String sessions) {
    return 'Completed Pomodoro: $sessions';
  }

  @override
  String totalFocus(String duration) {
    return 'Total focus time: $duration';
  }

  @override
  String get taskDateNote =>
      'Task completion dates aren\'t stored, so these are current totals rather than period results.';

  @override
  String get restoreFromTrash => 'Restore';

  @override
  String get deleteFromTrash => 'Delete permanently';

  @override
  String get trashLoadFailed => 'Couldn\'t load Trash.';

  @override
  String trashDeletedDate(String date) {
    return 'Deleted $date';
  }

  @override
  String get trashNotDeletedYet => 'In Trash';

  @override
  String trashConfirmHabit(String title) {
    return 'Habit “$title”, its schedule, and completion history will be permanently deleted.';
  }

  @override
  String trashConfirmTask(String title) {
    return 'Task “$title” will be permanently deleted.';
  }

  @override
  String get clockThemeMinimal => 'Minimal';

  @override
  String get clockFlipStyle => 'Flip Clock';

  @override
  String get clockDigitalStyle => 'Digital';

  @override
  String get clockFullscreenFailed =>
      'Couldn\'t enable full-screen clock mode.';

  @override
  String get remindersOnDevice => 'On-device reminders';

  @override
  String get remindersOffline =>
      'Schedules and settings stay on this device. No internet connection is needed.';

  @override
  String get dailyHabitReminder => 'Check your habits each day';

  @override
  String get taskDueReminder => 'The day before and on the due date';

  @override
  String get time => 'Time';

  @override
  String get remindersTaskTimingNote =>
      'Tasks don\'t have a time of day, so reminders arrive at the selected time. Android power-saving settings may delay delivery. Check notification and background activity permissions.';

  @override
  String get reminderLoadFailed => 'Couldn\'t load reminder settings.';

  @override
  String get reminderSaveFailed => 'Couldn\'t save reminder settings.';

  @override
  String get reminderPermissionSettings =>
      'Allow notifications for this app in Android settings.';

  @override
  String get reminderPermissionFailed =>
      'Couldn\'t request notification permission.';

  @override
  String get habitReminderTime => 'Habit reminder time';

  @override
  String get taskReminderTime => 'Task reminder time';

  @override
  String get reminderPermissionTitle => 'Allow notifications';

  @override
  String get taskUpdatedFailed => 'Couldn\'t update the task.';

  @override
  String get archiveMoveFailed => 'Couldn\'t archive the habit.';

  @override
  String focusBreaksRemaining(int count) {
    return 'Work sessions until a long break: $count';
  }

  @override
  String get habitPeriod => 'Period';

  @override
  String get notificationHabitAction => 'Open habits';

  @override
  String get notificationTaskAction => 'Open tasks';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '$count min',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hr',
      one: '$count hr',
    );
    return '$_temp0';
  }
}
