import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/features/statistics/presentation/statistics_page.dart';
import 'package:productivity_app/l10n/app_localizations.dart';
import 'package:productivity_app/features/statistics/data/statistics_repository.dart';

void main() {
  late AppDatabase database;
  late StatisticsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = StatisticsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'переключение 7/30/90 дней пересчитывает период по SQLite данным',
    () async {
      final now = DateTime(2026, 11, 16, 12);
      final habitId = await database
          .into(database.habits)
          .insert(
            HabitsCompanion.insert(
              title: 'Читать',
              createdAt: Value(now.subtract(const Duration(days: 100))),
            ),
          );
      await database.batch((batch) {
        batch.insertAll(
          database.habitScheduleDays,
          List.generate(
            7,
            (index) => HabitScheduleDaysCompanion.insert(
              habitId: habitId,
              weekday: index + 1,
            ),
          ),
        );
      });

      for (final daysAgo in [0, 6, 20, 31]) {
        final date = now.subtract(Duration(days: daysAgo));
        await database
            .into(database.habitEntries)
            .insert(
              HabitEntriesCompanion.insert(
                habitId: habitId,
                day: _dateKey(date),
                completedAt: Value(date),
              ),
            );
        await database
            .into(database.focusSessions)
            .insert(
              FocusSessionsCompanion.insert(
                startedAt: date.subtract(const Duration(minutes: 25)),
                completedAt: date,
                durationSeconds: 1500,
              ),
            );
      }

      final sevenDays = await repository.load(periodDays: 7, now: now);
      final thirtyDays = await repository.load(periodDays: 30, now: now);
      final ninetyDays = await repository.load(periodDays: 90, now: now);

      expect(sevenDays.days, hasLength(7));
      expect(sevenDays.periodHabitCompletions, 2);
      expect(sevenDays.periodFocusSessions, 2);
      expect(sevenDays.scheduledHabitOccurrences, 7);
      expect(sevenDays.completedScheduledHabitOccurrences, 2);
      expect(thirtyDays.days, hasLength(30));
      expect(thirtyDays.periodHabitCompletions, 3);
      expect(thirtyDays.periodFocusSessions, 3);
      expect(ninetyDays.days, hasLength(90));
      expect(ninetyDays.periodHabitCompletions, 4);
      expect(ninetyDays.allTimeHabitCompletions, 4);
      expect(ninetyDays.allTimeFocusSessions, 4);
      expect(ninetyDays.allTimeFocusSeconds, 4 * 1500);
    },
  );

  test('учитывает только завершённые сессии и текущие статусы задач', () async {
    final now = DateTime(2026, 11, 16, 12);
    await database
        .into(database.focusTimerState)
        .insert(
          FocusTimerStateCompanion.insert(
            id: const Value(1),
            phase: 'work',
            status: 'running',
            completedWorkSessions: 0,
            deadline: Value(now.add(const Duration(minutes: 10))),
            elapsedSeconds: 15 * 60,
          ),
        );
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Просроченная задача',
            dueDate: Value(now.subtract(const Duration(days: 1))),
          ),
        );
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Готовая задача',
            isCompleted: const Value(true),
          ),
        );

    final data = await repository.load(periodDays: 7, now: now);

    expect(data.periodFocusSessions, 0);
    expect(data.allTimeFocusSessions, 0);
    expect(data.totalTasks, 2);
    expect(data.completedTasks, 1);
    expect(data.openTasks, 1);
    expect(data.overdueTasks, 1);
  });

  testWidgets('переключатель экрана меняет выбранный период', (tester) async {
    final now = DateTime.now();
    final habitId = await database
        .into(database.habits)
        .insert(HabitsCompanion.insert(title: 'Растяжка'));
    final oldDate = now.subtract(const Duration(days: 20));
    await database
        .into(database.habitEntries)
        .insert(
          HabitEntriesCompanion.insert(
            habitId: habitId,
            day: _dateKey(oldDate),
            completedAt: Value(oldDate),
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsPage(database: database),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Отметок привычек за период: 0'), findsOneWidget);

    await tester.tap(find.text('30 дней'));
    await tester.pumpAndSettle();

    expect(find.text('Отметок привычек за период: 1'), findsOneWidget);
  });
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
