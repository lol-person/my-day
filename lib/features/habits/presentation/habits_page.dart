// lib/features/habits/presentation/habits_page.dart

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../data/habit_repository.dart';
import 'archived_habits_page.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  late final HabitRepository _repository;

  List<Habit> _activeHabits = [];
  List<_HabitListItem> _items = [];

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _hasActiveHabits = false;

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
    _loadHabits();
  }

  Future<void> _loadHabits({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final habits = await _repository.getActiveHabits();
      final today = DateTime.now();

      final loadedItems = <_HabitListItem>[];

      for (final habit in habits) {
        final weekdays = await _repository.getScheduledWeekdays(habit.id);

        if (!weekdays.contains(today.weekday)) {
          continue;
        }

        final isCompleted = await _repository.isCompleted(
          habitId: habit.id,
          date: today,
        );

        loadedItems.add(
          _HabitListItem(
            habit: habit,
            weekdays: weekdays,
            isCompleted: isCompleted,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _activeHabits = habits;
        _items = loadedItems;
        _hasActiveHabits = habits.isNotEmpty;
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

  /// Изменяет порядок привычек и сохраняет его в локальной базе.
  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_isUpdating ||
        oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= _items.length ||
        newIndex < 0 ||
        newIndex >= _items.length) {
      return;
    }

    final previousItems = List<_HabitListItem>.of(_items);
    final reorderedItems = List<_HabitListItem>.of(_items);

    final movedItem = reorderedItems.removeAt(oldIndex);
    reorderedItems.insert(newIndex, movedItem);

    final visibleIds = previousItems.map((item) => item.habit.id).toSet();

    final reorderedActiveHabits = List<Habit>.of(_activeHabits);
    var visibleIndex = 0;

    for (var index = 0; index < reorderedActiveHabits.length; index++) {
      if (visibleIds.contains(reorderedActiveHabits[index].id)) {
        reorderedActiveHabits[index] = reorderedItems[visibleIndex].habit;
        visibleIndex++;
      }
    }

    final orderedHabitIds = reorderedActiveHabits
        .map((habit) => habit.id)
        .toList();

    setState(() {
      _items = reorderedItems;
      _activeHabits = reorderedActiveHabits;
      _isUpdating = true;
    });

    try {
      await _repository.reorderHabits(
        orderedHabitIds: orderedHabitIds,
        archived: false,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _items = previousItems;
      });

      _showMessage('Не удалось сохранить порядок привычек: $error');

      await _loadHabits();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _openArchive() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return ArchivedHabitsPage(database: widget.database);
        },
      ),
    );

    if (!mounted) return;

    await _loadHabits();
  }

  Future<void> _showCreateHabitDialog() async {
    await _openHabitEditor();
  }

  Future<void> _showEditHabitDialog(_HabitListItem item) async {
    await _openHabitEditor(item: item);
  }

  Future<void> _openHabitEditor({_HabitListItem? item}) async {
    final isEditing = item != null;

    final draft = await showDialog<_HabitDraft>(
      context: context,
      builder: (dialogContext) {
        return _HabitEditorDialog(
          isEditing: isEditing,
          initialTitle: item?.habit.title ?? '',
          initialDescription: item?.habit.description ?? '',
          initialWeekdays: item?.weekdays,
        );
      },
    );

    if (!mounted || draft == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      if (item == null) {
        await _repository.createHabit(
          title: draft.title,
          description: draft.description,
          weekdays: draft.weekdays,
        );
      } else {
        await _repository.updateHabit(
          habitId: item.habit.id,
          title: draft.title,
          description: draft.description,
          weekdays: draft.weekdays,
        );
      }

      await _loadHabits();

      if (!mounted) return;

      _showMessage(isEditing ? 'Привычка обновлена' : 'Привычка добавлена');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        isEditing
            ? 'Не удалось изменить привычку: $error'
            : 'Не удалось создать привычку: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _toggleCompletion(_HabitListItem item, bool completed) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _repository.setCompleted(
        habitId: item.habit.id,
        date: DateTime.now(),
        completed: completed,
      );

      await _loadHabits();
    } catch (error) {
      if (!mounted) return;

      _showMessage('Не удалось сохранить выполнение: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _archiveHabit(_HabitListItem item) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Архивировать привычку?'),
          content: Text(
            '«${item.habit.title}» исчезнет из активного списка. '
            'История выполнения сохранится.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Архивировать'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldArchive != true || _isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _repository.archiveHabit(item.habit.id);
      await _loadHabits();

      if (!mounted) return;

      _showMessage('Привычка перемещена в архив');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Не удалось архивировать привычку: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
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

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.repeat_rounded,
              size: 38,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Пока нет привычек',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавь первую привычку и начни '
            'отслеживать свой прогресс.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isUpdating ? null : _showCreateHabitDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Добавить привычку'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoHabitsToday(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 64, color: colors.primary),
          const SizedBox(height: 16),
          Text(
            'На сегодня ничего не запланировано',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Твои активные привычки запланированы на другие дни. '
            'Сегодня можно отдохнуть или создать новую привычку.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isUpdating ? null : _showCreateHabitDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Добавить привычку'),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(_HabitListItem item, {required int index}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final sortedWeekdays = item.weekdays.toList()..sort();

    final scheduleText = sortedWeekdays
        .map((day) => _weekdayNames[day - 1])
        .join(' · ');

    return Card(
      key: ValueKey<int>(item.habit.id),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: _isUpdating
              ? null
              : (value) {
                  _toggleCompletion(item, value ?? false);
                },
        ),
        title: Text(
          item.habit.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: item.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.isCompleted
                ? colors.onSurfaceVariant
                : colors.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.habit.description != null &&
                  item.habit.description!.isNotEmpty) ...[
                Text(item.habit.description!),
                const SizedBox(height: 4),
              ],
              Text(
                scheduleText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              enabled: !_isUpdating,
              child: Semantics(
                label: 'Перетащить привычку',
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: _isUpdating
                        ? colors.onSurfaceVariant.withValues(alpha: 0.4)
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              enabled: !_isUpdating,
              tooltip: 'Действия с привычкой',
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditHabitDialog(item);
                } else if (value == 'archive') {
                  _archiveHabit(item);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 12),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined),
                      SizedBox(width: 12),
                      Text('Архивировать'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 42, color: colors.error),
              const SizedBox(height: 12),
              Text(
                'Не удалось загрузить привычки',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
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
                  _loadHabits(showLoading: true);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final completedCount = _items.where((item) => item.isCompleted).length;

    final progressText = _items.isEmpty
        ? 'Нет привычек на сегодня'
        : '$completedCount из ${_items.length} выполнено';

    return RefreshIndicator(
      onRefresh: _loadHabits,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Сегодня',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(DateTime.now()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        size: 32,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Прогресс за сегодня',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              progressText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Мои привычки на сегодня',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (_items.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Перетаскивай значок справа, чтобы изменить порядок.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          if (_items.isEmpty)
            SliverToBoxAdapter(
              child: _hasActiveHabits
                  ? _buildNoHabitsToday(context)
                  : _buildEmptyState(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverReorderableList(
                itemCount: _items.length,
                onReorderItem: _onReorder,
                itemBuilder: (context, index) {
                  return _buildHabitCard(_items[index], index: index);
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Привычки',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Архив привычек',
            onPressed: _isUpdating ? null : _openArchive,
            icon: const Icon(Icons.archive_outlined),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUpdating ? null : _showCreateHabitDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Новая привычка'),
      ),
    );
  }
}

class _HabitEditorDialog extends StatefulWidget {
  const _HabitEditorDialog({
    required this.isEditing,
    required this.initialTitle,
    required this.initialDescription,
    this.initialWeekdays,
  });

  final bool isEditing;
  final String initialTitle;
  final String initialDescription;
  final Set<int>? initialWeekdays;

  @override
  State<_HabitEditorDialog> createState() => _HabitEditorDialogState();
}

class _HabitEditorDialogState extends State<_HabitEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  final Set<int> _selectedWeekdays = {};

  String? _titleError;
  String? _scheduleError;

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

    _titleController = TextEditingController(text: widget.initialTitle);

    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );

    _selectedWeekdays.addAll(
      widget.initialWeekdays ?? const <int>{1, 2, 3, 4, 5, 6, 7},
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _titleError = 'Введи название привычки';
      });
      return;
    }

    if (_selectedWeekdays.isEmpty) {
      setState(() {
        _scheduleError = 'Выбери хотя бы один день недели';
      });
      return;
    }

    Navigator.of(context).pop(
      _HabitDraft(
        title: title,
        description: _descriptionController.text.trim(),
        weekdays: Set<int>.from(_selectedWeekdays),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Редактировать привычку' : 'Новая привычка',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: !widget.isEditing,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Название',
                hintText: 'Например, читать 15 минут',
                errorText: _titleError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() {
                    _titleError = null;
                  });
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'В какие дни выполнять?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(7, (index) {
                final weekday = index + 1;

                return FilterChip(
                  label: Text(_weekdayNames[index]),
                  selected: _selectedWeekdays.contains(weekday),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedWeekdays.add(weekday);
                      } else {
                        _selectedWeekdays.remove(weekday);
                      }

                      _scheduleError = null;
                    });
                  },
                );
              }),
            ),
            if (_scheduleError != null) ...[
              const SizedBox(height: 8),
              Text(
                _scheduleError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isEditing ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}

class _HabitListItem {
  const _HabitListItem({
    required this.habit,
    required this.weekdays,
    required this.isCompleted,
  });

  final Habit habit;
  final Set<int> weekdays;
  final bool isCompleted;
}

class _HabitDraft {
  const _HabitDraft({
    required this.title,
    required this.description,
    required this.weekdays,
  });

  final String title;
  final String description;
  final Set<int> weekdays;
}
