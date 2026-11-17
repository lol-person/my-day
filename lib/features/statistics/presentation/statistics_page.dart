import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/l10n.dart';
import '../data/statistics_repository.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late final StatisticsRepository _repository;
  late Future<StatisticsData> _statisticsFuture;
  int _selectedPeriod = 7;

  @override
  void initState() {
    super.initState();
    _repository = StatisticsRepository(widget.database);
    _statisticsFuture = _loadStatistics(_selectedPeriod);
  }

  Future<StatisticsData> _loadStatistics(int days) =>
      _repository.load(periodDays: days);

  Future<void> _refresh() async {
    final request = _loadStatistics(_selectedPeriod);
    setState(() => _statisticsFuture = request);
    try {
      await request;
    } catch (_) {}
  }

  void _selectPeriod(int days) {
    if (days == _selectedPeriod) return;
    setState(() {
      _selectedPeriod = days;
      _statisticsFuture = _loadStatistics(days);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.statistics),
        actions: [
          IconButton(
            tooltip: context.l10n.statisticsRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<StatisticsData>(
          future: _statisticsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _refresh);
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    context.l10n.habitPeriod,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 7, label: Text(context.l10n.days7)),
                      ButtonSegment(
                        value: 30,
                        label: Text(context.l10n.days30),
                      ),
                      ButtonSegment(
                        value: 90,
                        label: Text(context.l10n.days90),
                      ),
                    ],
                    selected: {_selectedPeriod},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      _selectPeriod(selection.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.periodRange(
                      MaterialLocalizations.of(context)
                          .formatMediumDate(data.periodStart),
                      MaterialLocalizations.of(context)
                          .formatMediumDate(data.periodEnd),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: context.l10n.selectedPeriod),
                  const SizedBox(height: 12),
                  _HabitPeriodCard(data: data),
                  const SizedBox(height: 12),
                  _FocusPeriodCard(data: data),
                  const SizedBox(height: 24),
                  _SectionTitle(title: context.l10n.dailyTrend),
                  const SizedBox(height: 12),
                  _DailyActivityCard(days: data.days),
                  const SizedBox(height: 24),
                  _SectionTitle(title: context.l10n.allTime),
                  const SizedBox(height: 12),
                  _AllTimeCard(data: data),
                  const SizedBox(height: 24),
                  _SectionTitle(title: context.l10n.tasksNow),
                  const SizedBox(height: 12),
                  _TasksCard(data: data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: colors.error),
            const SizedBox(height: 12),
            Text(
              context.l10n.statisticsLoadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

class _HabitPeriodCard extends StatelessWidget {
  const _HabitPeriodCard({required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rate = data.habitCompletionRate;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.scheduleCompletion,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    context.l10n.scheduleCompletionCount(
                      data.completedScheduledHabitOccurrences,
                      data.scheduledHabitOccurrences,
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '${(rate * 100).round()}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.habitCheckinsInPeriod(data.periodHabitCompletions),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.statsScheduleNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusPeriodCard extends StatelessWidget {
  const _FocusPeriodCard({required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.completedPomodoros,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.focusStatPeriod(
                      context.l10n.focusSessionCount(data.periodFocusSessions),
                      _formatDuration(context, data.periodFocusSeconds),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyActivityCard extends StatelessWidget {
  const _DailyActivityCard({required this.days});

  final List<DailyStatistics> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasActivity = days.any(
      (day) => day.habitCompletions > 0 || day.focusSessions > 0,
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: !hasActivity
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.l10n.noPeriodActivity,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < days.length; index++) ...[
                  if (index > 0)
                    Divider(height: 1, color: colors.outlineVariant),
                  ListTile(
                    dense: true,
                    title: Text(_formatDate(context, days[index].date)),
                    subtitle: Text(
                      '${context.l10n.habitTrend(days[index].habitCompletions)} · '
                      '${context.l10n.focusSessionCount(days[index].focusSessions)} · '
                      '${_formatDuration(context, days[index].focusSeconds)}',
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _AllTimeCard extends StatelessWidget {
  const _AllTimeCard({required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.allTimeHabitCheckins(data.allTimeHabitCompletions),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.allTimePomodoros(
                context.l10n.focusSessionCount(data.allTimeFocusSessions),
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.totalFocus(
                _formatDuration(context, data.allTimeFocusSeconds),
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.totalTasks(context.l10n.taskCount(data.totalTasks)),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.completed(data.completedTasks)),
            Text(context.l10n.inProgress(data.openTasks)),
            Text(context.l10n.overdueNow(data.overdueTasks)),
            const SizedBox(height: 8),
            Text(
              context.l10n.taskDateNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatMediumDate(date);

String _formatDuration(BuildContext context, int seconds) {
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours == 0) return context.l10n.durationMinutes(minutes);
  return '${context.l10n.durationHours(hours)} ${context.l10n.durationMinutes(remainingMinutes)}';
}
