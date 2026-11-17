// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Мой день';

  @override
  String get settings => 'Настройки';

  @override
  String get retry => 'Повторить';

  @override
  String get cancel => 'Отмена';

  @override
  String get choose => 'Выбрать';

  @override
  String get save => 'Сохранить';

  @override
  String get create => 'Создать';

  @override
  String get delete => 'Удалить';

  @override
  String get restore => 'Восстановить';

  @override
  String get loading => 'Загрузка…';

  @override
  String get today => 'Сегодня';

  @override
  String get tasks => 'Задачи';

  @override
  String get habits => 'Привычки';

  @override
  String get archive => 'Архив';

  @override
  String get trash => 'Корзина';

  @override
  String get statistics => 'Статистика';

  @override
  String get reminders => 'Напоминания';

  @override
  String get calendar => 'Календарь';

  @override
  String get focusSession => 'Фокус-сессия';

  @override
  String get clock => 'Часы';

  @override
  String get backup => 'Экспорт и импорт';

  @override
  String get newTask => 'Новая задача';

  @override
  String get taskTitle => 'Название';

  @override
  String get editTask => 'Редактировать задачу';

  @override
  String get taskTitleRequired => 'Введи название задачи';

  @override
  String get taskTitleTooLong => 'Максимум 150 символов';

  @override
  String get taskDescription => 'Описание (необязательно)';

  @override
  String get taskHint => 'Например, купить продукты';

  @override
  String get taskDueDate => 'Срок выполнения';

  @override
  String get chooseDate => 'Выбрать дату';

  @override
  String get removeDueDate => 'Убрать срок';

  @override
  String get priority => 'Приоритет';

  @override
  String get lowPriority => 'Низкий';

  @override
  String get normalPriority => 'Обычный';

  @override
  String get highPriority => 'Высокий';

  @override
  String get activeFilter => 'Активные';

  @override
  String get completedFilter => 'Готовые';

  @override
  String get allFilter => 'Все';

  @override
  String get noTasksYet => 'Пока нет задач';

  @override
  String get addFirstTask =>
      'Добавь первую задачу, чтобы спланировать свой день.';

  @override
  String get tasksIntro => 'Планируй дела и отмечай выполненное.';

  @override
  String get allTasksComplete => 'Все задачи выполнены';

  @override
  String get noActiveTasks => 'В списке нет активных задач.';

  @override
  String get noCompletedTasks => 'Нет выполненных задач';

  @override
  String get completedTasksAppear => 'Завершённые задачи появятся здесь.';

  @override
  String get noResults => 'Нет результатов';

  @override
  String get changeFilters => 'Попробуй изменить условия фильтрации.';

  @override
  String get taskAdded => 'Задача добавлена';

  @override
  String get taskUpdated => 'Задача обновлена';

  @override
  String get taskSavedFailed =>
      'Не удалось сохранить задачу. Попробуй ещё раз.';

  @override
  String get taskLoadFailed => 'Не удалось загрузить задачи. Попробуй ещё раз.';

  @override
  String get taskOrderSaved => 'Порядок задач сохранён';

  @override
  String get taskOrderFailed =>
      'Не удалось сохранить порядок задач. Попробуй ещё раз.';

  @override
  String get taskDeleted => 'Задача перемещена в корзину';

  @override
  String get taskRestored => 'Задача восстановлена';

  @override
  String get taskUpdateFailed =>
      'Не удалось обновить задачу. Попробуй ещё раз.';

  @override
  String get taskDeleteFailed => 'Не удалось удалить задачу. Попробуй ещё раз.';

  @override
  String get taskRestoreFailed => 'Не удалось восстановить задачу.';

  @override
  String taskMovedToTrashTitle(String title) {
    return '«$title» перемещена в корзину';
  }

  @override
  String get taskOrderHint =>
      'Зажми значок с полосками справа, чтобы изменить порядок.';

  @override
  String get taskOverdue => 'Просрочена';

  @override
  String get taskActions => 'Действия с задачей';

  @override
  String get edit => 'Редактировать';

  @override
  String get moveToTrash => 'В корзину';

  @override
  String get undo => 'Отменить';

  @override
  String taskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задачи',
      many: '$count задач',
      few: '$count задачи',
      one: '$count задача',
      zero: 'Нет задач',
    );
    return '$_temp0';
  }

  @override
  String habitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count привычки',
      many: '$count привычек',
      few: '$count привычки',
      one: '$count привычка',
      zero: 'Нет привычек',
    );
    return '$_temp0';
  }

  @override
  String get newHabit => 'Новая привычка';

  @override
  String get addHabit => 'Добавить привычку';

  @override
  String get habitTitle => 'Название привычки';

  @override
  String get habitHint => 'Например, читать 15 минут';

  @override
  String get habitSchedule => 'В какие дни выполнять?';

  @override
  String get habitEmpty => 'Пока нет привычек';

  @override
  String get habitEmptyDescription =>
      'Добавь первую привычку и начни отслеживать свой прогресс.';

  @override
  String get noHabitsToday => 'На сегодня ничего не запланировано';

  @override
  String get noHabitsTodayDescription =>
      'Твои активные привычки запланированы на другие дни. Сегодня можно отдохнуть или создать новую привычку.';

  @override
  String get todayProgress => 'Прогресс за сегодня';

  @override
  String get habitsToday => 'Мои привычки на сегодня';

  @override
  String completedOfTotal(int completed, int total) {
    return 'Выполнено: $completed из $total';
  }

  @override
  String get noHabitsScheduledToday => 'Нет привычек на сегодня';

  @override
  String get dragToReorderHabit =>
      'Перетаскивай значок справа, чтобы изменить порядок.';

  @override
  String get habitActions => 'Действия с привычкой';

  @override
  String get editHabit => 'Редактировать привычку';

  @override
  String get archiveHabit => 'Архивировать';

  @override
  String get habitArchived => 'Привычка архивирована';

  @override
  String get habitRestored => 'Привычка восстановлена';

  @override
  String get habitMovedToTrash => 'Привычка перемещена в корзину';

  @override
  String habitMovedToTrashTitle(String title) {
    return '«$title» перемещена в корзину';
  }

  @override
  String habitRestoredTitle(String title) {
    return '«$title» восстановлена';
  }

  @override
  String get habitTrashUndo => 'Привычка восстановлена в архиве';

  @override
  String get habitTrashFailed => 'Не удалось переместить привычку в корзину.';

  @override
  String get habitRestoreFailed => 'Не удалось восстановить привычку.';

  @override
  String habitOrderFailed(String error) {
    return 'Не удалось сохранить порядок привычек: $error';
  }

  @override
  String get habitSaved => 'Привычка обновлена';

  @override
  String get habitCreated => 'Привычка добавлена';

  @override
  String habitSaveFailed(String error) {
    return 'Не удалось сохранить привычку: $error';
  }

  @override
  String habitCompletionFailed(String error) {
    return 'Не удалось сохранить выполнение: $error';
  }

  @override
  String get habitActionFailed =>
      'Не удалось обновить привычку. Попробуй ещё раз.';

  @override
  String get habitDataSaveFailed =>
      'Не удалось сохранить изменения. Попробуй ещё раз.';

  @override
  String get archiveConfirmTitle => 'Архивировать привычку?';

  @override
  String archiveConfirmBody(String title) {
    return '«$title» исчезнет из активного списка. История выполнения сохранится.';
  }

  @override
  String get habitDeleteConfirmTitle => 'Переместить привычку в корзину?';

  @override
  String habitDeleteConfirmBody(String title) {
    return '«$title» и её расписание будут перемещены в корзину. История выполнения сохранится.';
  }

  @override
  String get weekdayMon => 'Пн';

  @override
  String get weekdayTue => 'Вт';

  @override
  String get weekdayWed => 'Ср';

  @override
  String get weekdayThu => 'Чт';

  @override
  String get weekdayFri => 'Пт';

  @override
  String get weekdaySat => 'Сб';

  @override
  String get weekdaySun => 'Вс';

  @override
  String habitScheduleLabel(String days) {
    return 'Расписание: $days';
  }

  @override
  String habitCompletionProgress(int completed, int total) {
    return 'Выполнено: $completed из $total';
  }

  @override
  String get habitLoadFailed =>
      'Не удалось загрузить привычки. Попробуй ещё раз.';

  @override
  String get enterHabitName => 'Введи название привычки';

  @override
  String get chooseWeekday => 'Выбери хотя бы один день недели';

  @override
  String get archiveHabits => 'Архив привычек';

  @override
  String get emptyArchive => 'Архив пуст';

  @override
  String get emptyArchiveDescription =>
      'Здесь будут храниться привычки, которые ты временно убрал из активного списка.';

  @override
  String archivedHabitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'В архиве # привычки',
      many: 'В архиве # привычек',
      few: 'В архиве # привычки',
      one: 'В архиве # привычка',
    );
    return '$_temp0';
  }

  @override
  String get restoreHabit => 'Восстановить привычку';

  @override
  String get archiveLoadFailed =>
      'Не удалось загрузить архив. Попробуй ещё раз.';

  @override
  String get calendarPlan => 'План дня';

  @override
  String get selectDate => 'Выбрать дату';

  @override
  String get previousWeek => 'Предыдущая неделя';

  @override
  String get nextWeek => 'Следующая неделя';

  @override
  String get noHabitsScheduled => 'Нет запланированных привычек';

  @override
  String get noHabitsScheduledDescription =>
      'На выбранный день активные привычки не назначены.';

  @override
  String get openHabits => 'Открыть привычки';

  @override
  String get noTasksForDate => 'На этот день нет задач';

  @override
  String get noTasksForDateDescription =>
      'Здесь появятся задачи, у которых срок выполнения приходится на выбранную дату.';

  @override
  String get lowPriorityLong => 'Низкий приоритет';

  @override
  String get normalPriorityLong => 'Обычный приоритет';

  @override
  String get highPriorityLong => 'Высокий приоритет';

  @override
  String get statisticsPeriod => 'Период';

  @override
  String get days7 => '7 дней';

  @override
  String get days30 => '30 дней';

  @override
  String get days90 => '90 дней';

  @override
  String get selectedPeriod => 'За выбранный период';

  @override
  String get dailyTrend => 'Динамика по дням';

  @override
  String get allTime => 'За всё время';

  @override
  String get tasksNow => 'Задачи сейчас';

  @override
  String get scheduleCompletion => 'Выполнение расписания';

  @override
  String scheduleCompletionCount(int completed, int total) {
    return 'Выполнено: $completed из $total дней';
  }

  @override
  String habitCompletionCount(int count) {
    return 'Отметок привычек: $count';
  }

  @override
  String get completedPomodoros => 'Завершённые Pomodoro';

  @override
  String focusSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сессии',
      many: '$count сессий',
      few: '$count сессии',
      one: '$count сессия',
      zero: 'Нет сессий',
    );
    return '$_temp0';
  }

  @override
  String get noPeriodActivity =>
      'За этот период отметок и завершённых фокус-сессий нет.';

  @override
  String totalTasks(String tasks) {
    return 'Задачи: $tasks';
  }

  @override
  String completed(int count) {
    return 'Выполнено: $count';
  }

  @override
  String inProgress(int count) {
    return 'В работе: $count';
  }

  @override
  String overdueNow(int count) {
    return 'Просрочено сейчас: $count';
  }

  @override
  String get statisticsLoadFailed => 'Не удалось загрузить статистику.';

  @override
  String get focusWork => 'Работа';

  @override
  String get focusShortBreak => 'Короткий перерыв';

  @override
  String get focusLongBreak => 'Длинный перерыв';

  @override
  String get start => 'Начать';

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продолжить';

  @override
  String get finishEarly => 'Завершить досрочно';

  @override
  String get skipBreak => 'Пропустить перерыв';

  @override
  String get focusHistory => 'История';

  @override
  String get focusHistoryEmpty => 'Завершённые рабочие сессии появятся здесь.';

  @override
  String focusMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты фокусировки',
      many: '$count минут фокусировки',
      few: '$count минуты фокусировки',
      one: '$count минута фокусировки',
      zero: 'Нет времени фокусировки',
    );
    return '$_temp0';
  }

  @override
  String get focusLoadFailed => 'Не удалось загрузить состояние фокус-сессии.';

  @override
  String get notificationPermission =>
      'Разреши уведомления, чтобы получать сигнал.';

  @override
  String get notificationScheduleFailed =>
      'Не удалось запланировать уведомление.';

  @override
  String get clockNow => 'СЕЙЧАС';

  @override
  String clockSeconds(String seconds) {
    return 'СЕКУНДЫ $seconds';
  }

  @override
  String get trashEmpty => 'Корзина пуста';

  @override
  String get trashEmptyDescription =>
      'Удалённые задачи и привычки будут храниться здесь, пока ты не восстановишь их или не удалишь окончательно.';

  @override
  String get deletePermanentlyTitle => 'Удалить окончательно?';

  @override
  String get deletePermanently => 'Удалить окончательно';

  @override
  String habitPermanentDeleteConfirm(String title) {
    return 'Привычка «$title», её расписание и история выполнения будут удалены без возможности восстановления.';
  }

  @override
  String taskPermanentDeleteConfirm(String title) {
    return 'Задача «$title» будет удалена без возможности восстановления.';
  }

  @override
  String get trashUpdated => 'Корзина обновлена';

  @override
  String get actionFailed => 'Не удалось выполнить действие. Попробуй ещё раз.';

  @override
  String trashedDate(String date) {
    return 'Удалено $date';
  }

  @override
  String get archivedHabit => 'Архивная';

  @override
  String get activeHabit => 'Активная';

  @override
  String get backupRestore => 'Экспорт и импорт';

  @override
  String get backupTitle => 'Твои данные — под твоим контролем';

  @override
  String get backupDescription =>
      'Резервная копия хранится там, куда ты сам её сохранишь. Приложение не отправляет её на собственный сервер.';

  @override
  String get createBackup => 'Создать резервную копию';

  @override
  String get backupExportDescription =>
      'Сохрани задачи, привычки, расписания, историю выполнения и настройки в один JSON-файл.';

  @override
  String get restoreBackup => 'Восстановить из копии';

  @override
  String get backupImportDescription =>
      'Выбери ранее созданный файл. Его содержимое заменит данные на этом устройстве.';

  @override
  String get exportData => 'Экспортировать данные';

  @override
  String get chooseAndRestore => 'Выбрать файл и восстановить';

  @override
  String get processingData => 'Обрабатываем данные…';

  @override
  String get backupCreated => 'Резервная копия сохранена.';

  @override
  String get backupCanceled => 'Сохранение отменено.';

  @override
  String get backupCreateFailed =>
      'Не удалось создать резервную копию. Попробуй ещё раз.';

  @override
  String get restoreConfirmTitle => 'Восстановить данные?';

  @override
  String get restoreConfirmBody =>
      'Текущие задачи, привычки, история выполнения и настройки будут заменены содержимым резервной копии. Это действие нельзя отменить. Рекомендуется сначала создать копию текущих данных.';

  @override
  String restoreComplete(int tasks, int habits, int entries, int settings) {
    return 'Данные восстановлены. Задач: $tasks, привычек: $habits, отметок: $entries, настроек: $settings.';
  }

  @override
  String restoreCompleteWithWarning(
    int tasks,
    int habits,
    int entries,
    int settings,
  ) {
    return 'Данные восстановлены. Задач: $tasks, привычек: $habits, отметок: $entries, настроек: $settings. Не удалось обновить очередь напоминаний — проверь настройки напоминаний.';
  }

  @override
  String get restoreFailed =>
      'Не удалось восстановить копию. Проверь, что файл создан этим приложением и не повреждён.';

  @override
  String get backupPrivacy =>
      'Храни копию в безопасном месте. JSON-файл не зашифрован: любой, кто получит его, сможет прочитать данные. Для переноса на другое устройство скопируй файл и импортируй его там.';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get appearanceDescription =>
      'Выбери удобное оформление. Изменение применяется сразу.';

  @override
  String get appTheme => 'Тема приложения';

  @override
  String get appLanguage => 'Язык приложения';

  @override
  String get systemLanguage => 'Системный';

  @override
  String get russianLanguage => 'Русский';

  @override
  String get englishLanguage => 'Английский';

  @override
  String get systemTheme => 'Система';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get systemThemeDescription => 'Приложение следует настройкам Android.';

  @override
  String get lightThemeDescription => 'Всегда используется светлое оформление.';

  @override
  String get darkThemeDescription => 'Всегда используется тёмное оформление.';

  @override
  String get accentColor => 'Основной цвет';

  @override
  String get colorPurple => 'Фиолетовый';

  @override
  String get colorGreen => 'Зелёный';

  @override
  String get colorRed => 'Красный';

  @override
  String get colorBlue => 'Синий';

  @override
  String get colorOrange => 'Оранжевый';

  @override
  String get colorTeal => 'Бирюзовый';

  @override
  String get accentDescription =>
      'Меняет акцентный цвет кнопок, выделений и главного блока.';

  @override
  String get dataStorage => 'Хранение данных';

  @override
  String get localDatabase => 'Локальная база данных';

  @override
  String get localDatabaseDescription =>
      'Задачи, привычки и настройки хранятся на устройстве. Тема и цвет включаются в резервную копию при экспорте.';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get accentSaved => 'Цвет интерфейса сохранён';

  @override
  String get settingsSaveFailed =>
      'Не удалось сохранить настройки. Попробуй ещё раз.';

  @override
  String get accentSaveFailed => 'Не удалось сохранить цвет. Попробуй ещё раз.';

  @override
  String get remindersTitle => 'Напоминания';

  @override
  String get habitsReminder => 'Напоминания о привычках';

  @override
  String get tasksReminder => 'Напоминания о задачах';

  @override
  String get reminderTime => 'Время напоминания';

  @override
  String get saveReminderFailed =>
      'Не удалось сохранить настройки напоминаний.';

  @override
  String get notificationFocusTitle => 'Интервал завершён';

  @override
  String get notificationFocusBody =>
      'Можно перейти к следующему этапу фокус-сессии.';

  @override
  String get notificationHabitsTitle => 'Пора проверить привычки';

  @override
  String get notificationHabitsBody =>
      'Отметь привычки, запланированные на сегодня.';

  @override
  String get notificationTaskTomorrow => 'Завтра срок выполнения';

  @override
  String get notificationTaskToday => 'Срок выполнения сегодня';

  @override
  String get notificationChannelDescription =>
      'Напоминания о привычках и сроках задач';

  @override
  String get homeMorning => 'Доброе утро!';

  @override
  String get homeAfternoon => 'Добрый день!';

  @override
  String get homeEvening => 'Добрый вечер!';

  @override
  String get homeHeadline => 'Маленькие шаги.\nБольшие результаты.';

  @override
  String get homeMessage =>
      'Выбирай главное, двигайся вперёд и постепенно создавай полезные привычки.';

  @override
  String get openClock => 'Открыть часы Flip Clock';

  @override
  String get openFocus => 'Фокус-сессия Pomodoro';

  @override
  String get openCalendar => 'Открыть календарь и план дня';

  @override
  String get openHabitTracker => 'Открыть трекер привычек';

  @override
  String get openTaskList => 'Открыть задачник';

  @override
  String get openStatistics => 'Посмотреть статистику';

  @override
  String get openReminders => 'Настроить напоминания';

  @override
  String get openBackup => 'Экспорт и импорт данных';

  @override
  String get welcomeHeadline => 'Твой день —\nв твоих руках';

  @override
  String get restorePending =>
      'Не удалось обновить очередь напоминаний — проверь настройки напоминаний.';

  @override
  String get fileTooLarge => 'Файл превышает допустимый размер 25 МБ.';

  @override
  String timerSessionsUntilLongBreak(int count) {
    return 'Рабочих интервалов до длинного перерыва: $count';
  }

  @override
  String breakSessionsUntilLongBreak(int count) {
    return 'Рабочих интервалов до длинного перерыва: $count';
  }

  @override
  String get calendarPickHelp => 'Выбери дату';

  @override
  String calendarWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get calendarToday => 'Сегодня';

  @override
  String get calendarLoadFailed => 'Не удалось загрузить план дня.';

  @override
  String get habitUpdateFailed => 'Не удалось обновить привычку.';

  @override
  String get dailyPlanHabits => 'Привычки';

  @override
  String get dailyPlanTasks => 'Задачи со сроком на этот день';

  @override
  String get done => 'Выполнено';

  @override
  String get weekdayShortMon => 'ПН';

  @override
  String get weekdayShortTue => 'ВТ';

  @override
  String get weekdayShortWed => 'СР';

  @override
  String get weekdayShortThu => 'ЧТ';

  @override
  String get weekdayShortFri => 'ПТ';

  @override
  String get weekdayShortSat => 'СБ';

  @override
  String get weekdayShortSun => 'ВС';

  @override
  String periodRange(String start, String end) {
    return 'С $start по $end, включая сегодня';
  }

  @override
  String get statisticsRefresh => 'Обновить статистику';

  @override
  String habitCheckinsInPeriod(int count) {
    return 'Отметок привычек за период: $count';
  }

  @override
  String get statsScheduleNote =>
      'Для расчёта используется сохранённое сейчас расписание; история его изменений не ведётся.';

  @override
  String focusStatPeriod(String sessions, String duration) {
    return '$sessions · $duration фокуса';
  }

  @override
  String habitTrend(int count) {
    return 'Привычки: $count';
  }

  @override
  String allTimeHabitCheckins(int count) {
    return 'Отметок привычек: $count';
  }

  @override
  String allTimePomodoros(String sessions) {
    return 'Завершённые Pomodoro: $sessions';
  }

  @override
  String totalFocus(String duration) {
    return 'Суммарный фокус: $duration';
  }

  @override
  String get taskDateNote =>
      'Дата выполнения задач не сохраняется, поэтому здесь показаны текущие статусы без разбивки по периоду.';

  @override
  String get restoreFromTrash => 'Восстановить';

  @override
  String get deleteFromTrash => 'Удалить окончательно';

  @override
  String get trashLoadFailed => 'Не удалось загрузить корзину.';

  @override
  String trashDeletedDate(String date) {
    return 'Удалено $date';
  }

  @override
  String get trashNotDeletedYet => 'В корзине';

  @override
  String trashConfirmHabit(String title) {
    return 'Привычка «$title», её расписание и история выполнения будут удалены без возможности восстановления.';
  }

  @override
  String trashConfirmTask(String title) {
    return 'Задача «$title» будет удалена без возможности восстановления.';
  }

  @override
  String get clockThemeMinimal => 'Минимализм';

  @override
  String get clockFlipStyle => 'Flip Clock';

  @override
  String get clockDigitalStyle => 'Digital';

  @override
  String get clockFullscreenFailed =>
      'Не удалось включить полноэкранный режим часов.';

  @override
  String get remindersOnDevice => 'Напоминания на устройстве';

  @override
  String get remindersOffline =>
      'Расписание и настройки хранятся локально. Подключение к интернету не требуется.';

  @override
  String get dailyHabitReminder => 'Ежедневно проверить привычки';

  @override
  String get taskDueReminder => 'Накануне срока и в день выполнения';

  @override
  String get time => 'Время';

  @override
  String get remindersTaskTimingNote =>
      'У задач нет отдельного времени выполнения, поэтому напоминания приходят в выбранное время. Энергосбережение Android может задерживать доставку. Проверь разрешения уведомлений и фоновой работы приложения.';

  @override
  String get reminderLoadFailed =>
      'Не удалось загрузить настройки напоминаний.';

  @override
  String get reminderSaveFailed =>
      'Не удалось сохранить настройки напоминаний.';

  @override
  String get reminderPermissionSettings =>
      'Разреши уведомления для приложения в настройках Android.';

  @override
  String get reminderPermissionFailed =>
      'Не удалось запросить разрешение на уведомления.';

  @override
  String get habitReminderTime => 'Время напоминания о привычках';

  @override
  String get taskReminderTime => 'Время напоминания о задачах';

  @override
  String get reminderPermissionTitle => 'Разреши уведомления';

  @override
  String get taskUpdatedFailed => 'Не удалось обновить задачу.';

  @override
  String get archiveMoveFailed => 'Не удалось архивировать привычку.';

  @override
  String focusBreaksRemaining(int count) {
    return 'Рабочих интервалов до длинного перерыва: $count';
  }

  @override
  String get habitPeriod => 'Период';

  @override
  String get notificationHabitAction => 'Открыть привычки';

  @override
  String get notificationTaskAction => 'Открыть задачи';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин',
      many: '$count мин',
      few: '$count мин',
      one: '$count мин',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ч',
      many: '$count ч',
      few: '$count ч',
      one: '$count ч',
    );
    return '$_temp0';
  }
}
