// lib/features/calendar/presentation/calendar_page.dart

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/presentation/habits_page.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/presentation/tasks_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final HabitRepository _habitRepository;
  late final TaskRepository _taskRepository;

  late DateTime _selectedDate;
  late Future<_DayPlanData> _planFuture;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    _habitRepository = HabitRepository(widget.database);
    _taskRepository = TaskRepository(widget.database);

    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _planFuture = _loadPlan(_selectedDate);
  }

  Future<_DayPlanData> _loadPlan(DateTime date) async {
    final selectedDay = DateUtils.dateOnly(date);
    final activeHabits = await _habitRepository.getActiveHabits();
    final plannedHabits = <_PlannedHabit>[];

    for (final habit in activeHabits) {
      final weekdays = await _habitRepository.getScheduledWeekdays(habit.id);

      if (!weekdays.contains(selectedDay.weekday)) continue;

      final completed = await _habitRepository.isCompleted(
        habitId: habit.id,
        date: selectedDay,
      );

      plannedHabits.add(_PlannedHabit(habit: habit, isCompleted: completed));
    }

    final allTasks = await _taskRepository.getTasks(filter: TaskFilter.all);

    final tasksForDay = allTasks.where((task) {
      final dueDate = task.dueDate;
      return dueDate != null && DateUtils.isSameDay(dueDate, selectedDay);
    }).toList();

    return _DayPlanData(habits: plannedHabits, tasks: tasksForDay);
  }

  Future<void> _reload() async {
    final request = _loadPlan(_selectedDate);

    if (!mounted) return;

    setState(() {
      _planFuture = request;
    });

    try {
      await request;
    } catch (_) {
      // Ошибку покажет FutureBuilder.
    }
  }

  void _selectDate(DateTime date) {
    final normalizedDate = DateUtils.dateOnly(date);

    setState(() {
      _selectedDate = normalizedDate;
      _planFuture = _loadPlan(normalizedDate);
    });
  }

  void _changeWeek(int offset) {
    _selectDate(_selectedDate.add(Duration(days: offset * 7)));
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Выбери дату',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (!mounted || selected == null) return;
    _selectDate(selected);
  }

  bool get _isFutureDate {
    final today = DateUtils.dateOnly(DateTime.now());
    return _selectedDate.isAfter(today);
  }

  Future<void> _toggleHabit(_PlannedHabit plannedHabit, bool completed) async {
    if (_isUpdating || _isFutureDate) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _habitRepository.setCompleted(
        habitId: plannedHabit.habit.id,
        date: _selectedDate,
        completed: completed,
      );

      await _reload();
    } catch (error) {
      if (mounted) {
        _showMessage('Не удалось обновить привычку: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _toggleTask(Task task, bool completed) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _taskRepository.setCompleted(taskId: task.id, completed: completed);

      await _reload();
    } catch (error) {
      if (mounted) {
        _showMessage('Не удалось обновить задачу: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _openHabits() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => HabitsPage(database: widget.database),
      ),
    );

    if (mounted) await _reload();
  }

  Future<void> _openTasks() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TasksPage(database: widget.database),
      ),
    );

    if (mounted) await _reload();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  DateTime _weekStart(DateTime date) {
    return DateUtils.dateOnly(date.subtract(Duration(days: date.weekday - 1)));
  }

  String _formatLongDate(DateTime date) {
    const weekdays = [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье',
    ];

    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]}';
  }

  String _formatWeekRange(DateTime start) {
    const months = [
      'янв.',
      'фев.',
      'мар.',
      'апр.',
      'мая',
      'июн.',
      'июл.',
      'авг.',
      'сен.',
      'окт.',
      'ноя.',
      'дек.',
    ];

    final end = start.add(const Duration(days: 6));

    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${end.day} ${months[end.month - 1]} ${end.year}';
    }

    return '${start.day} ${months[start.month - 1]} – '
        '${end.day} ${months[end.month - 1]} ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Календарь',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Выбрать дату',
            onPressed: _isUpdating ? null : _chooseDate,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          IconButton(
            tooltip: 'Сегодня',
            onPressed: _isUpdating ? null : () => _selectDate(DateTime.now()),
            icon: const Icon(Icons.today_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_DayPlanData>(
          future: _planFuture,
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
                        'Не удалось загрузить план дня',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _reload,
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
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    'План дня',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatLongDate(_selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildWeekNavigation(context),
                  const SizedBox(height: 12),
                  _buildWeekSelector(context),
                  const SizedBox(height: 20),
                  _buildSummary(context, data),
                  const SizedBox(height: 28),
                  _buildSectionHeader(
                    context,
                    title: 'Привычки',
                    icon: Icons.repeat_rounded,
                    count: '${data.completedHabits}/${data.habits.length}',
                  ),
                  const SizedBox(height: 10),
                  _buildHabits(context, data),
                  const SizedBox(height: 28),
                  _buildSectionHeader(
                    context,
                    title: 'Задачи со сроком на этот день',
                    icon: Icons.checklist_rounded,
                    count: '${data.completedTasks}/${data.tasks.length}',
                  ),
                  const SizedBox(height: 10),
                  _buildTasks(context, data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final weekStart = _weekStart(_selectedDate);

    return Row(
      children: [
        IconButton(
          tooltip: 'Предыдущая неделя',
          onPressed: _isUpdating ? null : () => _changeWeek(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            _formatWeekRange(weekStart),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Следующая неделя',
          onPressed: _isUpdating ? null : () => _changeWeek(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _buildWeekSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    const weekdayLabels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    final start = _weekStart(_selectedDate);
    final today = DateUtils.dateOnly(DateTime.now());

    return Row(
      children: List.generate(7, (index) {
        final date = start.add(Duration(days: index));
        final isSelected = DateUtils.isSameDay(date, _selectedDate);
        final isToday = DateUtils.isSameDay(date, today);

        final backgroundColor = isSelected ? colors.primary : colors.surface;
        final foregroundColor = isSelected
            ? colors.onPrimary
            : colors.onSurface;
        final borderColor = isSelected
            ? colors.primary
            : isToday
            ? colors.primary
            : colors.outlineVariant;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _isUpdating ? null : () => _selectDate(date),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 1,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekdayLabels[index],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${date.day}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummary(BuildContext context, _DayPlanData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Привычки',
                value: '${data.completedHabits}/${data.habits.length}',
                subtitle: 'Выполнено',
                icon: Icons.repeat_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Задачи',
                value: '${data.completedTasks}/${data.tasks.length}',
                subtitle: 'Выполнено',
                icon: Icons.task_alt_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String count,
  }) {
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
        Text(
          count,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildHabits(BuildContext context, _DayPlanData data) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (data.habits.isEmpty) {
      return _EmptyPlanCard(
        icon: Icons.repeat_rounded,
        title: 'Нет запланированных привычек',
        description: 'На выбранный день активные привычки не назначены.',
        buttonLabel: 'Открыть привычки',
        onPressed: _openHabits,
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
                indent: 16,
                endIndent: 16,
                color: colors.outlineVariant,
              ),
            CheckboxListTile(
              value: data.habits[index].isCompleted,
              onChanged: _isUpdating || _isFutureDate
                  ? null
                  : (value) {
                      _toggleHabit(data.habits[index], value ?? false);
                    },
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                data.habits[index].habit.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: data.habits[index].isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle:
                  data.habits[index].habit.description == null ||
                      data.habits[index].habit.description!.isEmpty
                  ? null
                  : Text(data.habits[index].habit.description!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTasks(BuildContext context, _DayPlanData data) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (data.tasks.isEmpty) {
      return _EmptyPlanCard(
        icon: Icons.checklist_rounded,
        title: 'На этот день нет задач',
        description: 'Здесь появятся задачи, у которых срок выполнения приходится на выбранную дату.',
        buttonLabel: 'Открыть задачник',
        onPressed: _openTasks,
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < data.tasks.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colors.outlineVariant,
              ),
            CheckboxListTile(
              value: data.tasks[index].isCompleted,
              onChanged: _isUpdating
                  ? null
                  : (value) {
                      _toggleTask(data.tasks[index], value ?? false);
                    },
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                data.tasks[index].title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: data.tasks[index].isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: data.tasks[index].isCompleted
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                ),
              ),
              subtitle: _buildTaskSubtitle(context, data.tasks[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskSubtitle(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    const priorityNames = [
      'Низкий приоритет',
      'Обычный приоритет',
      'Высокий приоритет',
    ];

    final details = <String>[];

    if (task.description != null && task.description!.isNotEmpty) {
      details.add(task.description!);
    }

    details.add(priorityNames[task.priority.clamp(0, 2).toInt()]);

    return Text(
      details.join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

class _DayPlanData {
  const _DayPlanData({required this.habits, required this.tasks});

  final List<_PlannedHabit> habits;
  final List<Task> tasks;

  int get completedHabits => habits.where((habit) => habit.isCompleted).length;

  int get completedTasks => tasks.where((task) => task.isCompleted).length;
}

class _PlannedHabit {
  const _PlannedHabit({required this.habit, required this.isCompleted});

  final Habit habit;
  final bool isCompleted;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
          const SizedBox(height: 12),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 42, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
