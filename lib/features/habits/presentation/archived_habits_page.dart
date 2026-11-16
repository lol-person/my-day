// lib/features/habits/presentation/archived_habits_page.dart

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
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

  static const List<String> _weekdayNames = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
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
          content: Text('«${item.habit.title}» восстановлена'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось восстановить привычку: $error'),
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

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.archive_outlined, size: 72, color: colors.primary),
        const SizedBox(height: 20),
        Text(
          'Архив пуст',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Здесь будут храниться привычки, '
          'которые ты временно убрал из активного списка.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
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
              'Не удалось загрузить архив',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
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
              label: const Text('Повторить'),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.archive_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.habit.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                        'Расписание: $scheduleText',
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
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _isRestoring ? null : () => _restoreHabit(item),
                icon: const Icon(Icons.unarchive_outlined),
                label: const Text('Восстановить'),
              ),
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
              'Архив привычек',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Архивных привычек: ${_items.length}',
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
      appBar: AppBar(title: const Text('Архив привычек')),
      body: SafeArea(child: body),
    );
  }
}

class _ArchivedHabitItem {
  const _ArchivedHabitItem({required this.habit, required this.weekdays});

  final Habit habit;
  final Set<int> weekdays;
}
