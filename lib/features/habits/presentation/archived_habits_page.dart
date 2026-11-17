import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/l10n.dart';
import '../data/habit_repository.dart';

class ArchivedHabitsPage extends StatefulWidget {
  const ArchivedHabitsPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<ArchivedHabitsPage> createState() => _ArchivedHabitsPageState();
}

class _ArchivedHabitsPageState extends State<ArchivedHabitsPage> {
  late final HabitRepository _repository;

  List<_ArchivedHabitItem> _items = [];

  bool _isLoading = true;
  bool _isRestoring = false;

  String? _errorMessage;

  List<String> get _weekdayNames => [
    context.l10n.weekdayMon,
    context.l10n.weekdayTue,
    context.l10n.weekdayWed,
    context.l10n.weekdayThu,
    context.l10n.weekdayFri,
    context.l10n.weekdaySat,
    context.l10n.weekdaySun,
  ];

  @override
  void initState() {
    super.initState();

    _repository = HabitRepository(widget.database);
    _loadArchivedHabits();
  }

  Future<void> _loadArchivedHabits() async {
    try {
      final habits = await _repository.getArchivedHabits();
      final loadedItems = <_ArchivedHabitItem>[];

      for (final habit in habits) {
        final weekdays = await _repository.getScheduledWeekdays(habit.id);

        loadedItems.add(_ArchivedHabitItem(habit: habit, weekdays: weekdays));
      }

      if (!mounted) return;

      setState(() {
        _items = loadedItems;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreHabit(_ArchivedHabitItem item) async {
    if (_isRestoring) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      await _repository.restoreHabit(item.habit.id);
      await _loadArchivedHabits();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.habitRestoredTitle(item.habit.title)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.habitRestoreFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _moveToTrash(_ArchivedHabitItem item) async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    try {
      await _repository.moveHabitToTrash(item.habit.id);
      await _loadArchivedHabits();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.habitMovedToTrashTitle(item.habit.title),
            ),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: context.l10n.undo,
              onPressed: () => _undoTrash(item.habit),
            ),
          ),
        );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.habitTrashFailed)));
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _undoTrash(Habit habit) async {
    try {
      await _repository.restoreHabitFromTrash(habit.id);
      await _loadArchivedHabits();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.habitTrashUndo)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.habitRestoreFailed)),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.archive_outlined, size: 56, color: colors.primary),
        const SizedBox(height: 16),
        Text(
          context.l10n.emptyArchive,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.emptyArchiveDescription,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              context.l10n.archiveHabits,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.archiveLoadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadArchivedHabits();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(_ArchivedHabitItem item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final sortedWeekdays = item.weekdays.toList()..sort();

    final scheduleText = sortedWeekdays
        .map((day) => _weekdayNames[day - 1])
        .join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.archive_outlined, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.habit.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (item.habit.description != null &&
                          item.habit.description!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.habit.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      Text(
                        context.l10n.habitScheduleLabel(scheduleText),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _isRestoring ? null : () => _moveToTrash(item),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(context.l10n.moveToTrash),
                ),
                OutlinedButton.icon(
                  onPressed: _isRestoring ? null : () => _restoreHabit(item),
                  icon: const Icon(Icons.unarchive_outlined),
                  label: Text(context.l10n.restoreHabit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = _buildErrorState(context);
    } else if (_items.isEmpty) {
      body = _buildEmptyState(context);
    } else {
      body = RefreshIndicator(
        onRefresh: _loadArchivedHabits,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              context.l10n.archiveHabits,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.archivedHabitCount(_items.length),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ..._items.map(_buildHabitCard),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.archiveHabits)),
      body: SafeArea(child: body),
    );
  }
}

class _ArchivedHabitItem {
  const _ArchivedHabitItem({required this.habit, required this.weekdays});

  final Habit habit;
  final Set<int> weekdays;
}
