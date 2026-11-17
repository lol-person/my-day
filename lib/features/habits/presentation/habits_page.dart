import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/l10n.dart';
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

      _showMessage(context.l10n.habitDataSaveFailed);

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

      _showMessage(
        isEditing ? context.l10n.habitSaved : context.l10n.habitCreated,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(context.l10n.habitDataSaveFailed);
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

      _showMessage(context.l10n.habitActionFailed);
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
          title: Text(context.l10n.archiveConfirmTitle),
          content: Text(context.l10n.archiveConfirmBody(item.habit.title)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(context.l10n.archiveHabit),
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

      _showMessage(context.l10n.habitArchived);
    } catch (error) {
      if (!mounted) return;

      _showMessage(context.l10n.habitActionFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _moveHabitToTrash(_HabitListItem item) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await _repository.moveHabitToTrash(item.habit.id);
      await _loadHabits();
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
              onPressed: () => _restoreTrashedHabit(item.habit),
            ),
          ),
        );
    } catch (_) {
      if (mounted) _showMessage(context.l10n.habitTrashFailed);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _restoreTrashedHabit(Habit habit) async {
    try {
      await _repository.restoreHabitFromTrash(habit.id);
      await _loadHabits();
      if (mounted) _showMessage(context.l10n.habitRestored);
    } catch (_) {
      if (mounted) _showMessage(context.l10n.habitRestoreFailed);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatFullDate(date);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.repeat_rounded, size: 56, color: colors.primary),
          const SizedBox(height: 16),
          Text(context.l10n.habitEmpty, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            context.l10n.habitEmptyDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isUpdating ? null : _showCreateHabitDialog,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.addHabit),
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
          Icon(Icons.event_available_rounded, size: 56, color: colors.primary),
          const SizedBox(height: 16),
          Text(
            context.l10n.noHabitsToday,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.noHabitsTodayDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isUpdating ? null : _showCreateHabitDialog,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.addHabit),
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
          semanticLabel: item.habit.title,
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
                label: context.l10n.dragToReorderHabit,
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
              tooltip: context.l10n.habitActions,
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditHabitDialog(item);
                } else if (value == 'archive') {
                  _archiveHabit(item);
                } else if (value == 'trash') {
                  _moveHabitToTrash(item);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 12),
                      Text(context.l10n.edit),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined),
                      SizedBox(width: 12),
                      Text(context.l10n.archiveHabit),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'trash',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded),
                      SizedBox(width: 12),
                      Text(context.l10n.moveToTrash),
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
                context.l10n.habits,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.habitLoadFailed,
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
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final completedCount = _items.where((item) => item.isCompleted).length;

    final progressText = _items.isEmpty
        ? context.l10n.noHabitsScheduledToday
        : context.l10n.habitCompletionProgress(completedCount, _items.length);

    return RefreshIndicator(
      onRefresh: _loadHabits,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(context.l10n.today, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  _formatDate(DateTime.now()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: colors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.track_changes_rounded,
                          size: 24,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.todayProgress,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colors.onPrimaryContainer,
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
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.habitsToday,
                  style: theme.textTheme.titleLarge?.copyWith(),
                ),
                const SizedBox(height: 8),
                if (_items.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      context.l10n.dragToReorderHabit,
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
        title: Text(
          context.l10n.habits,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.archiveHabits,
            onPressed: _isUpdating ? null : _openArchive,
            icon: const Icon(Icons.archive_outlined),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUpdating ? null : _showCreateHabitDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.newHabit),
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
        _titleError = context.l10n.enterHabitName;
      });
      return;
    }

    if (_selectedWeekdays.isEmpty) {
      setState(() {
        _scheduleError = context.l10n.chooseWeekday;
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
        widget.isEditing ? context.l10n.editHabit : context.l10n.newHabit,
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
                labelText: context.l10n.habitTitle,
                hintText: context.l10n.habitHint,
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
              decoration: InputDecoration(
                labelText: context.l10n.taskDescription,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.habitSchedule,
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
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.isEditing ? context.l10n.save : context.l10n.create,
          ),
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
