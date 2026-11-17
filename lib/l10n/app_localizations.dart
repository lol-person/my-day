import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Day'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @focusSession.
  ///
  /// In en, this message translates to:
  /// **'Focus session'**
  String get focusSession;

  /// No description provided for @clock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get clock;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backup;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskTitle;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a task name'**
  String get taskTitleRequired;

  /// No description provided for @taskTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Maximum 150 characters'**
  String get taskTitleTooLong;

  /// No description provided for @taskDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get taskDescription;

  /// No description provided for @taskHint.
  ///
  /// In en, this message translates to:
  /// **'For example, buy groceries'**
  String get taskHint;

  /// No description provided for @taskDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskDueDate;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @removeDueDate.
  ///
  /// In en, this message translates to:
  /// **'Remove due date'**
  String get removeDueDate;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @lowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowPriority;

  /// No description provided for @normalPriority.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalPriority;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highPriority;

  /// No description provided for @activeFilter.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeFilter;

  /// No description provided for @completedFilter.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedFilter;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @addFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Add your first task to plan your day.'**
  String get addFirstTask;

  /// No description provided for @tasksIntro.
  ///
  /// In en, this message translates to:
  /// **'Plan your day and check things off.'**
  String get tasksIntro;

  /// No description provided for @allTasksComplete.
  ///
  /// In en, this message translates to:
  /// **'All tasks are complete'**
  String get allTasksComplete;

  /// No description provided for @noActiveTasks.
  ///
  /// In en, this message translates to:
  /// **'There are no active tasks.'**
  String get noActiveTasks;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks'**
  String get noCompletedTasks;

  /// No description provided for @completedTasksAppear.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks will appear here.'**
  String get completedTasksAppear;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @changeFilters.
  ///
  /// In en, this message translates to:
  /// **'Try changing the filters.'**
  String get changeFilters;

  /// No description provided for @taskAdded.
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get taskAdded;

  /// No description provided for @taskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdated;

  /// No description provided for @taskSavedFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the task. Try again.'**
  String get taskSavedFailed;

  /// No description provided for @taskLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load tasks. Try again.'**
  String get taskLoadFailed;

  /// No description provided for @taskOrderSaved.
  ///
  /// In en, this message translates to:
  /// **'Task order saved'**
  String get taskOrderSaved;

  /// No description provided for @taskOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the task order. Try again.'**
  String get taskOrderFailed;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task moved to Trash'**
  String get taskDeleted;

  /// No description provided for @taskRestored.
  ///
  /// In en, this message translates to:
  /// **'Task restored'**
  String get taskRestored;

  /// No description provided for @taskUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the task. Try again.'**
  String get taskUpdateFailed;

  /// No description provided for @taskDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the task. Try again.'**
  String get taskDeleteFailed;

  /// No description provided for @taskRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore the task.'**
  String get taskRestoreFailed;

  /// No description provided for @taskMovedToTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'“{title}” moved to Trash'**
  String taskMovedToTrashTitle(String title);

  /// No description provided for @taskOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle on the right to change the order.'**
  String get taskOrderHint;

  /// No description provided for @taskOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskOverdue;

  /// No description provided for @taskActions.
  ///
  /// In en, this message translates to:
  /// **'Task actions'**
  String get taskActions;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @moveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash'**
  String get moveToTrash;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @taskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tasks} one{{count} task} other{{count} tasks}}'**
  String taskCount(int count);

  /// No description provided for @habitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No habits} one{{count} habit} other{{count} habits}}'**
  String habitCount(int count);

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get newHabit;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add habit'**
  String get addHabit;

  /// No description provided for @habitTitle.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitTitle;

  /// No description provided for @habitHint.
  ///
  /// In en, this message translates to:
  /// **'For example, read for 15 minutes'**
  String get habitHint;

  /// No description provided for @habitSchedule.
  ///
  /// In en, this message translates to:
  /// **'Which days will you do this?'**
  String get habitSchedule;

  /// No description provided for @habitEmpty.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get habitEmpty;

  /// No description provided for @habitEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first habit to start tracking your progress.'**
  String get habitEmptyDescription;

  /// No description provided for @noHabitsToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for today'**
  String get noHabitsToday;

  /// No description provided for @noHabitsTodayDescription.
  ///
  /// In en, this message translates to:
  /// **'Your active habits are scheduled for other days. Take a break or add a new habit.'**
  String get noHabitsTodayDescription;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s progress'**
  String get todayProgress;

  /// No description provided for @habitsToday.
  ///
  /// In en, this message translates to:
  /// **'My habits for today'**
  String get habitsToday;

  /// No description provided for @completedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} completed'**
  String completedOfTotal(int completed, int total);

  /// No description provided for @noHabitsScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'No habits scheduled for today'**
  String get noHabitsScheduledToday;

  /// No description provided for @dragToReorderHabit.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle to reorder habits.'**
  String get dragToReorderHabit;

  /// No description provided for @habitActions.
  ///
  /// In en, this message translates to:
  /// **'Habit actions'**
  String get habitActions;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get editHabit;

  /// No description provided for @archiveHabit.
  ///
  /// In en, this message translates to:
  /// **'Archive habit'**
  String get archiveHabit;

  /// No description provided for @habitArchived.
  ///
  /// In en, this message translates to:
  /// **'Habit archived'**
  String get habitArchived;

  /// No description provided for @habitRestored.
  ///
  /// In en, this message translates to:
  /// **'Habit restored'**
  String get habitRestored;

  /// No description provided for @habitMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Habit moved to Trash'**
  String get habitMovedToTrash;

  /// No description provided for @habitMovedToTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'“{title}” moved to Trash'**
  String habitMovedToTrashTitle(String title);

  /// No description provided for @habitRestoredTitle.
  ///
  /// In en, this message translates to:
  /// **'“{title}” restored'**
  String habitRestoredTitle(String title);

  /// No description provided for @habitTrashUndo.
  ///
  /// In en, this message translates to:
  /// **'Habit restored to the archive'**
  String get habitTrashUndo;

  /// No description provided for @habitTrashFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move the habit to Trash.'**
  String get habitTrashFailed;

  /// No description provided for @habitRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore the habit.'**
  String get habitRestoreFailed;

  /// No description provided for @habitOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the habit order: {error}'**
  String habitOrderFailed(String error);

  /// No description provided for @habitSaved.
  ///
  /// In en, this message translates to:
  /// **'Habit saved'**
  String get habitSaved;

  /// No description provided for @habitCreated.
  ///
  /// In en, this message translates to:
  /// **'Habit added'**
  String get habitCreated;

  /// No description provided for @habitSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the habit: {error}'**
  String habitSaveFailed(String error);

  /// No description provided for @habitCompletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the habit: {error}'**
  String habitCompletionFailed(String error);

  /// No description provided for @habitActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the habit. Try again.'**
  String get habitActionFailed;

  /// No description provided for @habitDataSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save changes. Try again.'**
  String get habitDataSaveFailed;

  /// No description provided for @archiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this habit?'**
  String get archiveConfirmTitle;

  /// No description provided for @archiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will leave your active list. Its completion history will be kept.'**
  String archiveConfirmBody(String title);

  /// No description provided for @habitDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Move this habit to Trash?'**
  String get habitDeleteConfirmTitle;

  /// No description provided for @habitDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” and its schedule will be moved to Trash. Its history will be kept.'**
  String habitDeleteConfirmBody(String title);

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @habitScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule: {days}'**
  String habitScheduleLabel(String days);

  /// No description provided for @habitCompletionProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} completed'**
  String habitCompletionProgress(int completed, int total);

  /// No description provided for @habitLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load habits. Try again.'**
  String get habitLoadFailed;

  /// No description provided for @enterHabitName.
  ///
  /// In en, this message translates to:
  /// **'Enter a habit name'**
  String get enterHabitName;

  /// No description provided for @chooseWeekday.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one day of the week'**
  String get chooseWeekday;

  /// No description provided for @archiveHabits.
  ///
  /// In en, this message translates to:
  /// **'Archived habits'**
  String get archiveHabits;

  /// No description provided for @emptyArchive.
  ///
  /// In en, this message translates to:
  /// **'Your archive is empty'**
  String get emptyArchive;

  /// No description provided for @emptyArchiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Habits you temporarily remove from your active list will be kept here.'**
  String get emptyArchiveDescription;

  /// No description provided for @archivedHabitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# habit in the archive} other{# habits in the archive}}'**
  String archivedHabitCount(int count);

  /// No description provided for @restoreHabit.
  ///
  /// In en, this message translates to:
  /// **'Restore habit'**
  String get restoreHabit;

  /// No description provided for @archiveLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the archive. Try again.'**
  String get archiveLoadFailed;

  /// No description provided for @calendarPlan.
  ///
  /// In en, this message translates to:
  /// **'Daily plan'**
  String get calendarPlan;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @noHabitsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No habits scheduled'**
  String get noHabitsScheduled;

  /// No description provided for @noHabitsScheduledDescription.
  ///
  /// In en, this message translates to:
  /// **'No active habits are scheduled for this date.'**
  String get noHabitsScheduledDescription;

  /// No description provided for @openHabits.
  ///
  /// In en, this message translates to:
  /// **'Open habits'**
  String get openHabits;

  /// No description provided for @noTasksForDate.
  ///
  /// In en, this message translates to:
  /// **'No tasks due on this date'**
  String get noTasksForDate;

  /// No description provided for @noTasksForDateDescription.
  ///
  /// In en, this message translates to:
  /// **'Tasks due on this date will appear here.'**
  String get noTasksForDateDescription;

  /// No description provided for @lowPriorityLong.
  ///
  /// In en, this message translates to:
  /// **'Low priority'**
  String get lowPriorityLong;

  /// No description provided for @normalPriorityLong.
  ///
  /// In en, this message translates to:
  /// **'Normal priority'**
  String get normalPriorityLong;

  /// No description provided for @highPriorityLong.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get highPriorityLong;

  /// No description provided for @statisticsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get statisticsPeriod;

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get days7;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get days30;

  /// No description provided for @days90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get days90;

  /// No description provided for @selectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Selected period'**
  String get selectedPeriod;

  /// No description provided for @dailyTrend.
  ///
  /// In en, this message translates to:
  /// **'Daily trend'**
  String get dailyTrend;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @tasksNow.
  ///
  /// In en, this message translates to:
  /// **'Tasks now'**
  String get tasksNow;

  /// No description provided for @scheduleCompletion.
  ///
  /// In en, this message translates to:
  /// **'Schedule completion'**
  String get scheduleCompletion;

  /// No description provided for @scheduleCompletionCount.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} days completed'**
  String scheduleCompletionCount(int completed, int total);

  /// No description provided for @habitCompletionCount.
  ///
  /// In en, this message translates to:
  /// **'Habit check-ins: {count}'**
  String habitCompletionCount(int count);

  /// No description provided for @completedPomodoros.
  ///
  /// In en, this message translates to:
  /// **'Completed Pomodoro sessions'**
  String get completedPomodoros;

  /// No description provided for @focusSessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions} one{{count} session} other{{count} sessions}}'**
  String focusSessionCount(int count);

  /// No description provided for @noPeriodActivity.
  ///
  /// In en, this message translates to:
  /// **'No habit check-ins or completed focus sessions in this period.'**
  String get noPeriodActivity;

  /// No description provided for @totalTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks: {tasks}'**
  String totalTasks(String tasks);

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed: {count}'**
  String completed(int count);

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress: {count}'**
  String inProgress(int count);

  /// No description provided for @overdueNow.
  ///
  /// In en, this message translates to:
  /// **'Overdue now: {count}'**
  String overdueNow(int count);

  /// No description provided for @statisticsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load statistics.'**
  String get statisticsLoadFailed;

  /// No description provided for @focusWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get focusWork;

  /// No description provided for @focusShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short break'**
  String get focusShortBreak;

  /// No description provided for @focusLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get focusLongBreak;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @finishEarly.
  ///
  /// In en, this message translates to:
  /// **'End early'**
  String get finishEarly;

  /// No description provided for @skipBreak.
  ///
  /// In en, this message translates to:
  /// **'Skip break'**
  String get skipBreak;

  /// No description provided for @focusHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get focusHistory;

  /// No description provided for @focusHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Completed work sessions will appear here.'**
  String get focusHistoryEmpty;

  /// No description provided for @focusMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No focus time} one{{count} minute focused} other{{count} minutes focused}}'**
  String focusMinutes(int count);

  /// No description provided for @focusLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the focus session.'**
  String get focusLoadFailed;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to receive the timer alert.'**
  String get notificationPermission;

  /// No description provided for @notificationScheduleFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t schedule the notification.'**
  String get notificationScheduleFailed;

  /// No description provided for @clockNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get clockNow;

  /// No description provided for @clockSeconds.
  ///
  /// In en, this message translates to:
  /// **'SECONDS {seconds}'**
  String clockSeconds(String seconds);

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// No description provided for @trashEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Deleted tasks and habits stay here until you restore or permanently delete them.'**
  String get trashEmptyDescription;

  /// No description provided for @deletePermanentlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get deletePermanentlyTitle;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @habitPermanentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Habit “{title}”, its schedule, and completion history will be permanently deleted.'**
  String habitPermanentDeleteConfirm(String title);

  /// No description provided for @taskPermanentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Task “{title}” will be permanently deleted.'**
  String taskPermanentDeleteConfirm(String title);

  /// No description provided for @trashUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trash updated'**
  String get trashUpdated;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete that action. Try again.'**
  String get actionFailed;

  /// No description provided for @trashedDate.
  ///
  /// In en, this message translates to:
  /// **'Deleted {date}'**
  String trashedDate(String date);

  /// No description provided for @archivedHabit.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedHabit;

  /// No description provided for @activeHabit.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeHabit;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backupRestore;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data stays in your hands'**
  String get backupTitle;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Your backup is saved wherever you choose. The app never sends it to a server.'**
  String get backupDescription;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create a backup'**
  String get createBackup;

  /// No description provided for @backupExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Save your tasks, habits, schedules, completion history, and settings in one JSON file.'**
  String get backupExportDescription;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreBackup;

  /// No description provided for @backupImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file. Its contents will replace the data currently on this device.'**
  String get backupImportDescription;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @chooseAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Choose a file and restore'**
  String get chooseAndRestore;

  /// No description provided for @processingData.
  ///
  /// In en, this message translates to:
  /// **'Processing data…'**
  String get processingData;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup saved.'**
  String get backupCreated;

  /// No description provided for @backupCanceled.
  ///
  /// In en, this message translates to:
  /// **'Saving canceled.'**
  String get backupCanceled;

  /// No description provided for @backupCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the backup. Try again.'**
  String get backupCreateFailed;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore data?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your current tasks, habits, completion history, and settings will be replaced with the contents of this backup. This can\'t be undone. Create a backup of your current data first.'**
  String get restoreConfirmBody;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Data restored. Tasks: {tasks}, habits: {habits}, check-ins: {entries}, settings: {settings}.'**
  String restoreComplete(int tasks, int habits, int entries, int settings);

  /// No description provided for @restoreCompleteWithWarning.
  ///
  /// In en, this message translates to:
  /// **'Data restored. Tasks: {tasks}, habits: {habits}, check-ins: {entries}, settings: {settings}. Couldn\'t refresh reminder schedules—check your reminder settings.'**
  String restoreCompleteWithWarning(
    int tasks,
    int habits,
    int entries,
    int settings,
  );

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore the backup. Check that the file is a valid app backup and try again.'**
  String get restoreFailed;

  /// No description provided for @backupPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Keep the file somewhere safe. JSON backups aren\'t encrypted, so anyone with the file can read its contents. To move your data to another device, copy the file and import it there.'**
  String get backupPrivacy;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @appearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the look that works for you. Changes take effect right away.'**
  String get appearanceDescription;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get appTheme;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// No description provided for @russianLanguage.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russianLanguage;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Follows your Android settings.'**
  String get systemThemeDescription;

  /// No description provided for @lightThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use the light theme.'**
  String get lightThemeDescription;

  /// No description provided for @darkThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use the dark theme.'**
  String get darkThemeDescription;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @accentDescription.
  ///
  /// In en, this message translates to:
  /// **'Changes the accent color of buttons, highlights, and the main panel.'**
  String get accentDescription;

  /// No description provided for @dataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data storage'**
  String get dataStorage;

  /// No description provided for @localDatabase.
  ///
  /// In en, this message translates to:
  /// **'Local database'**
  String get localDatabase;

  /// No description provided for @localDatabaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Tasks, habits, and settings stay on this device. Your theme and selected color are included when you export settings.'**
  String get localDatabaseDescription;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @accentSaved.
  ///
  /// In en, this message translates to:
  /// **'Accent color saved'**
  String get accentSaved;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save settings. Try again.'**
  String get settingsSaveFailed;

  /// No description provided for @accentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the accent color. Try again.'**
  String get accentSaveFailed;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @habitsReminder.
  ///
  /// In en, this message translates to:
  /// **'Habit reminders'**
  String get habitsReminder;

  /// No description provided for @tasksReminder.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get tasksReminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @saveReminderFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save reminder settings.'**
  String get saveReminderFailed;

  /// No description provided for @notificationFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Interval complete'**
  String get notificationFocusTitle;

  /// No description provided for @notificationFocusBody.
  ///
  /// In en, this message translates to:
  /// **'You can move on to the next part of your focus session.'**
  String get notificationFocusBody;

  /// No description provided for @notificationHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to check your habits'**
  String get notificationHabitsTitle;

  /// No description provided for @notificationHabitsBody.
  ///
  /// In en, this message translates to:
  /// **'Check off the habits scheduled for today.'**
  String get notificationHabitsBody;

  /// No description provided for @notificationTaskTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get notificationTaskTomorrow;

  /// No description provided for @notificationTaskToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get notificationTaskToday;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Habit reminders and task due dates'**
  String get notificationChannelDescription;

  /// No description provided for @homeMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get homeMorning;

  /// No description provided for @homeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get homeAfternoon;

  /// No description provided for @homeEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get homeEvening;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Small steps.\nBig results.'**
  String get homeHeadline;

  /// No description provided for @homeMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose what matters, make steady progress, and build habits that last.'**
  String get homeMessage;

  /// No description provided for @openClock.
  ///
  /// In en, this message translates to:
  /// **'Open Flip Clock'**
  String get openClock;

  /// No description provided for @openFocus.
  ///
  /// In en, this message translates to:
  /// **'Start a Pomodoro session'**
  String get openFocus;

  /// No description provided for @openCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar and daily plan'**
  String get openCalendar;

  /// No description provided for @openHabitTracker.
  ///
  /// In en, this message translates to:
  /// **'Open habit tracker'**
  String get openHabitTracker;

  /// No description provided for @openTaskList.
  ///
  /// In en, this message translates to:
  /// **'Open task list'**
  String get openTaskList;

  /// No description provided for @openStatistics.
  ///
  /// In en, this message translates to:
  /// **'View statistics'**
  String get openStatistics;

  /// No description provided for @openReminders.
  ///
  /// In en, this message translates to:
  /// **'Manage reminders'**
  String get openReminders;

  /// No description provided for @openBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore data'**
  String get openBackup;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Make today count.'**
  String get welcomeHeadline;

  /// No description provided for @restorePending.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh reminder schedules. Check your reminder settings.'**
  String get restorePending;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is larger than 25 MB.'**
  String get fileTooLarge;

  /// No description provided for @timerSessionsUntilLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Work sessions until a long break: {count}'**
  String timerSessionsUntilLongBreak(int count);

  /// No description provided for @breakSessionsUntilLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Work sessions until a long break: {count}'**
  String breakSessionsUntilLongBreak(int count);

  /// No description provided for @calendarPickHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get calendarPickHelp;

  /// No description provided for @calendarWeekRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String calendarWeekRange(String start, String end);

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the daily plan.'**
  String get calendarLoadFailed;

  /// No description provided for @habitUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the habit.'**
  String get habitUpdateFailed;

  /// No description provided for @dailyPlanHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get dailyPlanHabits;

  /// No description provided for @dailyPlanTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks due on this date'**
  String get dailyPlanTasks;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @weekdayShortMon.
  ///
  /// In en, this message translates to:
  /// **'MON'**
  String get weekdayShortMon;

  /// No description provided for @weekdayShortTue.
  ///
  /// In en, this message translates to:
  /// **'TUE'**
  String get weekdayShortTue;

  /// No description provided for @weekdayShortWed.
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get weekdayShortWed;

  /// No description provided for @weekdayShortThu.
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get weekdayShortThu;

  /// No description provided for @weekdayShortFri.
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get weekdayShortFri;

  /// No description provided for @weekdayShortSat.
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get weekdayShortSat;

  /// No description provided for @weekdayShortSun.
  ///
  /// In en, this message translates to:
  /// **'SUN'**
  String get weekdayShortSun;

  /// No description provided for @periodRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String periodRange(String start, String end);

  /// No description provided for @statisticsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh statistics'**
  String get statisticsRefresh;

  /// No description provided for @habitCheckinsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Habit check-ins this period: {count}'**
  String habitCheckinsInPeriod(int count);

  /// No description provided for @statsScheduleNote.
  ///
  /// In en, this message translates to:
  /// **'Uses the current schedule; schedule changes aren\'t tracked historically.'**
  String get statsScheduleNote;

  /// No description provided for @focusStatPeriod.
  ///
  /// In en, this message translates to:
  /// **'{sessions} · {duration} focused'**
  String focusStatPeriod(String sessions, String duration);

  /// No description provided for @habitTrend.
  ///
  /// In en, this message translates to:
  /// **'Habits: {count}'**
  String habitTrend(int count);

  /// No description provided for @allTimeHabitCheckins.
  ///
  /// In en, this message translates to:
  /// **'Habit check-ins: {count}'**
  String allTimeHabitCheckins(int count);

  /// No description provided for @allTimePomodoros.
  ///
  /// In en, this message translates to:
  /// **'Completed Pomodoro: {sessions}'**
  String allTimePomodoros(String sessions);

  /// No description provided for @totalFocus.
  ///
  /// In en, this message translates to:
  /// **'Total focus time: {duration}'**
  String totalFocus(String duration);

  /// No description provided for @taskDateNote.
  ///
  /// In en, this message translates to:
  /// **'Task completion dates aren\'t stored, so these are current totals rather than period results.'**
  String get taskDateNote;

  /// No description provided for @restoreFromTrash.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreFromTrash;

  /// No description provided for @deleteFromTrash.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteFromTrash;

  /// No description provided for @trashLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load Trash.'**
  String get trashLoadFailed;

  /// No description provided for @trashDeletedDate.
  ///
  /// In en, this message translates to:
  /// **'Deleted {date}'**
  String trashDeletedDate(String date);

  /// No description provided for @trashNotDeletedYet.
  ///
  /// In en, this message translates to:
  /// **'In Trash'**
  String get trashNotDeletedYet;

  /// No description provided for @trashConfirmHabit.
  ///
  /// In en, this message translates to:
  /// **'Habit “{title}”, its schedule, and completion history will be permanently deleted.'**
  String trashConfirmHabit(String title);

  /// No description provided for @trashConfirmTask.
  ///
  /// In en, this message translates to:
  /// **'Task “{title}” will be permanently deleted.'**
  String trashConfirmTask(String title);

  /// No description provided for @clockThemeMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get clockThemeMinimal;

  /// No description provided for @clockFlipStyle.
  ///
  /// In en, this message translates to:
  /// **'Flip Clock'**
  String get clockFlipStyle;

  /// No description provided for @clockDigitalStyle.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get clockDigitalStyle;

  /// No description provided for @clockFullscreenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t enable full-screen clock mode.'**
  String get clockFullscreenFailed;

  /// No description provided for @remindersOnDevice.
  ///
  /// In en, this message translates to:
  /// **'On-device reminders'**
  String get remindersOnDevice;

  /// No description provided for @remindersOffline.
  ///
  /// In en, this message translates to:
  /// **'Schedules and settings stay on this device. No internet connection is needed.'**
  String get remindersOffline;

  /// No description provided for @dailyHabitReminder.
  ///
  /// In en, this message translates to:
  /// **'Check your habits each day'**
  String get dailyHabitReminder;

  /// No description provided for @taskDueReminder.
  ///
  /// In en, this message translates to:
  /// **'The day before and on the due date'**
  String get taskDueReminder;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @remindersTaskTimingNote.
  ///
  /// In en, this message translates to:
  /// **'Tasks don\'t have a time of day, so reminders arrive at the selected time. Android power-saving settings may delay delivery. Check notification and background activity permissions.'**
  String get remindersTaskTimingNote;

  /// No description provided for @reminderLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load reminder settings.'**
  String get reminderLoadFailed;

  /// No description provided for @reminderSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save reminder settings.'**
  String get reminderSaveFailed;

  /// No description provided for @reminderPermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for this app in Android settings.'**
  String get reminderPermissionSettings;

  /// No description provided for @reminderPermissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t request notification permission.'**
  String get reminderPermissionFailed;

  /// No description provided for @habitReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Habit reminder time'**
  String get habitReminderTime;

  /// No description provided for @taskReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Task reminder time'**
  String get taskReminderTime;

  /// No description provided for @reminderPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get reminderPermissionTitle;

  /// No description provided for @taskUpdatedFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the task.'**
  String get taskUpdatedFailed;

  /// No description provided for @archiveMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t archive the habit.'**
  String get archiveMoveFailed;

  /// No description provided for @focusBreaksRemaining.
  ///
  /// In en, this message translates to:
  /// **'Work sessions until a long break: {count}'**
  String focusBreaksRemaining(int count);

  /// No description provided for @habitPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get habitPeriod;

  /// No description provided for @notificationHabitAction.
  ///
  /// In en, this message translates to:
  /// **'Open habits'**
  String get notificationHabitAction;

  /// No description provided for @notificationTaskAction.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get notificationTaskAction;

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String dayCount(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} min} other{{count} min}}'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hr} other{{count} hr}}'**
  String durationHours(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
