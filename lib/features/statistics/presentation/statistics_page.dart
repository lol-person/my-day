// lib/features/statistics/presentation/statistics_page.dart

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<_StatisticsData> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _loadStatistics();
  }

  Future<_StatisticsData> _loadStatistics() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    final startKey = _dateKey(weekStart);
    final todayKey = _dateKey(today);

    final habits = await (widget.database.select(
      widget.database.habits,
    )..where((habit) => habit.isArchived.equals(false))).get();

    final tasks = await widget.database.select(widget.database.tasks).get();

    final schedules = await widget.database
        .select(widget.database.habitScheduleDays)
        .get();

    final allEntries = await widget.database
        .select(widget.database.habitEntries)
        .get();

    final activeHabitIds = habits.map((habit) => habit.id).toSet();

    final scheduleByHabit = <int, Set<int>>{};

    for (final schedule in schedules) {
      if (!activeHabitIds.contains(schedule.habitId)) {
        continue;
      }

      (scheduleByHabit[schedule.habitId] ??= <int>{}).add(schedule.weekday);
    }

    final completedEntries = <String>{};

    for (final entry in allEntries) {
      if (entry.day.compareTo(startKey) >= 0 &&
          entry.day.compareTo(todayKey) <= 0) {
        completedEntries.add('${entry.habitId}:${entry.day}');
      }
    }

    final days = List<_DayStatistics>.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dateKey = _dateKey(date);

      var scheduled = 0;
      var completed = 0;

      for (final habit in habits) {
        final weekdays = scheduleByHabit[habit.id] ?? const <int>{};

        if (!weekdays.contains(date.weekday)) {
          continue;
        }

        scheduled++;

        if (completedEntries.contains('${habit.id}:$dateKey')) {
          completed++;
        }
      }

      return _DayStatistics(
        date: date,
        scheduled: scheduled,
        completed: completed,
      );
    });

    final habitStatistics =
        habits.map((habit) {
          final weekdays = scheduleByHabit[habit.id] ?? const <int>{};

          var scheduled = 0;
          var completed = 0;

          for (var index = 0; index < 7; index++) {
            final date = weekStart.add(Duration(days: index));

            if (!weekdays.contains(date.weekday)) {
              continue;
            }

            scheduled++;

            if (completedEntries.contains('${habit.id}:${_dateKey(date)}')) {
              completed++;
            }
          }

          return _HabitStatistics(
            title: habit.title,
            scheduled: scheduled,
            completed: completed,
          );
        }).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

    final completedTasks = tasks.where((task) => task.isCompleted).length;

    final overdueTasks = tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) {
        return false;
      }

      final dueDate = task.dueDate!;
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

      return dueDay.isBefore(today);
    }).length;

    return _StatisticsData(
      totalTasks: tasks.length,
      completedTasks: completedTasks,
      overdueTasks: overdueTasks,
      days: days,
      habits: habitStatistics,
    );
  }

  Future<void> _refresh() async {
    final request = _loadStatistics();

    setState(() {
      _statisticsFuture = request;
    });

    try {
      await request;
    } catch (_) {
      // Ошибка отображается в FutureBuilder.
    }
  }

  static String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Статистика',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить статистику',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_StatisticsData>(
          future: _statisticsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: colors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Не удалось загрузить статистику',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    'Твой прогресс',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Обзор задач и привычек за последние семь дней.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    context,
                    'Задачи',
                    Icons.checklist_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTaskMetrics(context, data),
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    context,
                    'Привычки за неделю',
                    Icons.repeat_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklySummary(context, data),
                  const SizedBox(height: 16),
                  _buildWeeklyChart(context, data),
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    context,
                    'По каждой привычке',
                    Icons.insights_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildHabitList(context, data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskMetrics(BuildContext context, _StatisticsData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Всего задач',
                value: '${data.totalTasks}',
                subtitle: 'Все задачи',
                icon: Icons.list_alt_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Выполнено',
                value: '${data.completedTasks}',
                subtitle: data.totalTasks == 0
                    ? 'Пока нет задач'
                    : '${(data.completedTasks / data.totalTasks * 100).round()}% от всех',
                icon: Icons.task_alt_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Осталось',
                value: '${data.totalTasks - data.completedTasks}',
                subtitle: 'Активные задачи',
                icon: Icons.pending_actions_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Просрочено',
                value: '${data.overdueTasks}',
                subtitle: 'Срок уже прошёл',
                icon: Icons.event_busy_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeeklySummary(BuildContext context, _StatisticsData data) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final scheduled = data.days.fold<int>(
      0,
      (total, day) => total + day.scheduled,
    );

    final completed = data.days.fold<int>(
      0,
      (total, day) => total + day.completed,
    );

    final rate = scheduled == 0 ? 0.0 : completed / scheduled;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выполнено по расписанию',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$completed из $scheduled',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(rate * 100).round()}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 10,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              scheduled == 0 ? 'Нет запланированных привычек за этот период.' : 'Учитываются только дни, когда привычка была запланирована.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, _StatisticsData data) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    const weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'По дням недели',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < data.days.length; index++)
                  Expanded(
                    child: _buildDayBar(
                      context,
                      day: data.days[index],
                      weekdayLabel:
                          weekdayLabels[data.days[index].date.weekday - 1],
                      colors: colors,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBar(
    BuildContext context, {
    required _DayStatistics day,
    required String weekdayLabel,
    required ColorScheme colors,
    required ThemeData theme,
  }) {
    final hasScheduled = day.scheduled > 0;
    final barHeight = hasScheduled
        ? (72 * day.rate).clamp(5.0, 72.0).toDouble()
        : 4.0;

    final barColor = !hasScheduled
        ? colors.outlineVariant
        : day.completed == day.scheduled
        ? colors.primary
        : colors.primaryContainer;

    return Column(
      children: [
        SizedBox(
          height: 76,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 20,
              height: barHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          weekdayLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasScheduled ? '${day.completed}/${day.scheduled}' : '—',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${day.date.day}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitList(BuildContext context, _StatisticsData data) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (data.habits.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.repeat_rounded, size: 42, color: colors.primary),
              const SizedBox(height: 12),
              Text(
                'Пока нет активных привычек',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Создай привычку в трекере — здесь появится её недельный прогресс.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < data.habits.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: colors.outlineVariant,
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.habits[index].title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${data.habits[index].completed}/${data.habits[index].scheduled}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: data.habits[index].rate,
                      minHeight: 8,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(data.habits[index].rate * 100).round()}% выполнения',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsData {
  const _StatisticsData({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.days,
    required this.habits,
  });

  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final List<_DayStatistics> days;
  final List<_HabitStatistics> habits;
}

class _DayStatistics {
  const _DayStatistics({
    required this.date,
    required this.scheduled,
    required this.completed,
  });

  final DateTime date;
  final int scheduled;
  final int completed;

  double get rate => scheduled == 0 ? 0.0 : completed / scheduled;
}

class _HabitStatistics {
  const _HabitStatistics({
    required this.title,
    required this.scheduled,
    required this.completed,
  });

  final String title;
  final int scheduled;
  final int completed;

  double get rate => scheduled == 0 ? 0.0 : completed / scheduled;
}
