import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/l10n.dart';
import '../data/task_repository.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final TaskRepository _repository;

  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.active;
  bool _hasAnyTasks = false;

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _repository = TaskRepository(widget.database);
    _loadTasks();
  }

  Future<void> _loadTasks({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final tasks = await _repository.getTasks(filter: _filter);
      var hasAnyTasks = tasks.isNotEmpty;

      if (!hasAnyTasks && _filter != TaskFilter.all) {
        hasAnyTasks = (await _repository.getTasks(filter: TaskFilter.all))
            .isNotEmpty;
      }

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _hasAnyTasks = hasAnyTasks;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = context.l10n.taskLoadFailed;
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
    if (_isSaving ||
        oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= _tasks.length ||
        newIndex < 0 ||
        newIndex >= _tasks.length) {
      return;
    }

    final previousTasks = List<Task>.of(_tasks);
    final reorderedTasks = List<Task>.of(_tasks);

    final movedTask = reorderedTasks.removeAt(oldIndex);
    reorderedTasks.insert(newIndex, movedTask);

    setState(() {
      _tasks = reorderedTasks;
      _isSaving = true;
    });

    try {
      await _repository.reorderTasks(
        orderedTaskIds: reorderedTasks.map((task) => task.id).toList(),
        filter: _filter,
      );

      if (!mounted) return;

      _showMessage(context.l10n.taskOrderSaved);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _tasks = previousTasks;
      });

      _showMessage(context.l10n.taskOrderFailed);

      await _loadTasks();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openTaskEditor({Task? task}) async {
    final draft = await showDialog<_TaskDraft>(
      context: context,
      builder: (dialogContext) {
        return _TaskEditorDialog(task: task);
      },
    );

    if (!mounted || draft == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (task == null) {
        await _repository.createTask(
          title: draft.title,
          description: draft.description,
          dueDate: draft.dueDate,
          priority: draft.priority,
        );

        _filter = TaskFilter.active;
      } else {
        await _repository.updateTask(
          taskId: task.id,
          title: draft.title,
          description: draft.description,
          dueDate: draft.dueDate,
          priority: draft.priority,
        );
      }

      await _loadTasks();

      if (!mounted) return;

      _showMessage(
        task == null ? context.l10n.taskAdded : context.l10n.taskUpdated,
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(context.l10n.taskSavedFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggleCompleted(Task task, bool completed) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.setCompleted(taskId: task.id, completed: completed);

      await _loadTasks();
    } catch (_) {
      if (!mounted) return;

      _showMessage(context.l10n.taskUpdateFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.moveTaskToTrash(task.id);
      await _loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.taskMovedToTrashTitle(task.title)),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: context.l10n.undo,
              onPressed: () => _restoreTask(task),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;

      _showMessage(context.l10n.taskDeleteFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _restoreTask(Task task) async {
    try {
      await _repository.restoreTask(task.id);
      await _loadTasks();
      if (mounted) _showMessage(context.l10n.taskRestored);
    } catch (_) {
      if (mounted) _showMessage(context.l10n.taskRestoreFailed);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _priorityLabel(int priority) {
    switch (priority) {
      case 0:
        return context.l10n.lowPriority;
      case 2:
        return context.l10n.highPriority;
      default:
        return context.l10n.normalPriority;
    }
  }

  Color _priorityColor(BuildContext context, int priority) {
    final colors = Theme.of(context).colorScheme;

    switch (priority) {
      case 2:
        return colors.error;
      case 0:
        return colors.onSurfaceVariant;
      default:
        return colors.primary;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    String title;
    String description;
    IconData icon;

    if (!_hasAnyTasks) {
      title = context.l10n.noTasksYet;
      description = context.l10n.addFirstTask;
      icon = Icons.checklist_rounded;
    } else if (_filter == TaskFilter.active) {
      title = context.l10n.allTasksComplete;
      description = context.l10n.noActiveTasks;
      icon = Icons.task_alt_rounded;
    } else if (_filter == TaskFilter.completed) {
      title = context.l10n.noCompletedTasks;
      description = context.l10n.completedTasksAppear;
      icon = Icons.task_alt_rounded;
    } else {
      title = context.l10n.noResults;
      description = context.l10n.changeFilters;
      icon = Icons.filter_list_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 72, color: colors.primary),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSaving ? null : () => _openTaskEditor(),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.newTask),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, {required int index}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final dueDate = task.dueDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final isOverdue =
        dueDate != null &&
        DateTime(dueDate.year, dueDate.month, dueDate.day).isBefore(today) &&
        !task.isCompleted;

    final priorityColor = _priorityColor(context, task.priority);

    return Card(
      key: ValueKey<int>(task.id),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Checkbox(
                value: task.isCompleted,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        _toggleCompleted(task, value ?? false);
                      },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isCompleted
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                      ),
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (dueDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: isOverdue
                                    ? colors.error
                                    : colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(dueDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOverdue
                                      ? colors.error
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 15,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _priorityLabel(task.priority),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: priorityColor,
                              ),
                            ),
                          ],
                        ),
                        if (isOverdue)
                          Text(
                            context.l10n.taskOverdue,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  enabled: !_isSaving,
                  child: Semantics(
                    label: context.l10n.taskOrderHint,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: _isSaving
                            ? colors.onSurfaceVariant.withValues(alpha: 0.4)
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !_isSaving,
                  tooltip: context.l10n.taskActions,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openTaskEditor(task: task);
                    } else if (value == 'delete') {
                      _deleteTask(task);
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
                      value: 'delete',
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
              Icon(Icons.error_outline_rounded, color: colors.error, size: 44),
              const SizedBox(height: 12),
              Text(
                context.l10n.tasks,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadTasks(showLoading: true),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(context.l10n.tasks, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  context.l10n.tasksIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SegmentedButton<TaskFilter>(
                  segments: [
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.active,
                      label: Text(context.l10n.activeFilter),
                      icon: Icon(Icons.pending_actions_rounded),
                    ),
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.completed,
                      label: Text(context.l10n.completedFilter),
                      icon: Icon(Icons.task_alt_rounded),
                    ),
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.all,
                      label: Text(context.l10n.allFilter),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: _isSaving
                      ? null
                      : (selection) {
                          setState(() {
                            _filter = selection.first;
                            _isLoading = true;
                          });
                          _loadTasks();
                        },
                ),
                const SizedBox(height: 18),
                Text(
                  context.l10n.taskCount(_tasks.length),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (_tasks.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.taskOrderHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ]),
            ),
          ),
          if (_tasks.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState(context))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverReorderableList(
                itemCount: _tasks.length,
                onReorderItem: (oldIndex, newIndex) {
                  _onReorder(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  return _buildTaskCard(_tasks[index], index: index);
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
      appBar: AppBar(title: Text(context.l10n.tasks)),
      body: SafeArea(child: _buildBody(context)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () => _openTaskEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.newTask),
      ),
    );
  }
}

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({this.task});

  final Task? task;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late int _priority;
  DateTime? _dueDate;

  String? _titleError;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.task?.title ?? '');

    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );

    _priority = widget.task?.priority ?? 1;
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _chooseDueDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: context.l10n.taskDueDate,
      cancelText: context.l10n.cancel,
      confirmText: context.l10n.choose,
    );

    if (!mounted || selectedDate == null) return;

    setState(() {
      _dueDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _titleError = context.l10n.taskTitleRequired;
      });
      return;
    }

    if (title.length > 150) {
      setState(() {
        _titleError = context.l10n.taskTitleTooLong;
      });
      return;
    }

    Navigator.of(context).pop(
      _TaskDraft(
        title: title,
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? context.l10n.editTask : context.l10n.newTask),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                autofocus: !_isEditing,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.l10n.taskTitle,
                  hintText: context.l10n.taskHint,
                  errorText: _titleError,
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
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.l10n.taskDescription,
                ),
              ),
              const SizedBox(height: 20),
              Text(context.l10n.taskDueDate, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _chooseDueDate,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(
                  _dueDate == null
                      ? context.l10n.chooseDate
                      : _formatDate(_dueDate!),
                ),
              ),
              if (_dueDate != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _dueDate = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: Text(context.l10n.removeDueDate),
                ),
              const SizedBox(height: 16),
              Text(context.l10n.priority, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text(context.l10n.lowPriority),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text(context.l10n.normalPriority),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    label: Text(context.l10n.highPriority),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (selection) {
                  setState(() {
                    _priority = selection.first;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? context.l10n.save : context.l10n.create),
        ),
      ],
    );
  }
}

class _TaskDraft {
  const _TaskDraft({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
  });

  final String title;
  final String description;
  final DateTime? dueDate;
  final int priority;
}
