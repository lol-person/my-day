// lib/features/tasks/presentation/tasks_page.dart

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
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

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
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

  /// Меняет порядок задач и сохраняет его в локальной базе.
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

      _showMessage('Порядок задач сохранён');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _tasks = previousTasks;
      });

      _showMessage('Не удалось сохранить порядок задач: $error');

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

      _showMessage(task == null ? 'Задача добавлена' : 'Задача обновлена');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Не удалось сохранить задачу: $error');
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
    } catch (error) {
      if (!mounted) return;

      _showMessage('Не удалось обновить задачу: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удалить задачу?'),
          content: Text(
            'Задача «${task.title}» будет удалена без возможности '
            'восстановления из этого экрана.',
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
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.deleteTask(task.id);
      await _loadTasks();

      if (!mounted) return;

      _showMessage('Задача удалена');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Не удалось удалить задачу: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  String _priorityLabel(int priority) {
    switch (priority) {
      case 0:
        return 'Низкий';
      case 2:
        return 'Высокий';
      default:
        return 'Обычный';
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

    if (_filter == TaskFilter.completed) {
      title = 'Пока нет выполненных задач';
      description = 'Когда завершишь задачу, она появится здесь.';
      icon = Icons.task_alt_rounded;
    } else if (_filter == TaskFilter.active) {
      title = 'Все задачи выполнены!';
      description = 'Можно отдохнуть или добавить новую задачу.';
      icon = Icons.celebration_rounded;
    } else {
      title = 'Пока нет задач';
      description = 'Добавь первую задачу, чтобы спланировать свой день.';
      icon = Icons.checklist_rounded;
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
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
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
            label: const Text('Новая задача'),
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
                        fontWeight: FontWeight.w700,
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
                                  fontWeight: isOverdue
                                      ? FontWeight.w700
                                      : FontWeight.normal,
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
                            'Просрочена',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.error,
                              fontWeight: FontWeight.w700,
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
                    label: 'Перетащить задачу',
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
                  tooltip: 'Действия с задачей',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openTaskEditor(task: task);
                    } else if (value == 'delete') {
                      _deleteTask(task);
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
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded),
                          SizedBox(width: 12),
                          Text('Удалить'),
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
                'Не удалось загрузить задачи',
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
                label: const Text('Повторить'),
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
                Text(
                  'Мои задачи',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Планируй дела и отмечай выполненное.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SegmentedButton<TaskFilter>(
                  segments: const [
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.active,
                      label: Text('Активные'),
                      icon: Icon(Icons.pending_actions_rounded),
                    ),
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.completed,
                      label: Text('Готовые'),
                      icon: Icon(Icons.task_alt_rounded),
                    ),
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.all,
                      label: Text('Все'),
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
                  '${_tasks.length} ${_tasks.length == 1 ? 'задача' : 'задач в списке'}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (_tasks.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Зажми значок с полосками справа, чтобы изменить порядок.',
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
      appBar: AppBar(
        title: const Text(
          'Задачи',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () => _openTaskEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Новая задача'),
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
      helpText: 'Выбери срок выполнения',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
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
        _titleError = 'Введи название задачи';
      });
      return;
    }

    if (title.length > 150) {
      setState(() {
        _titleError = 'Максимум 150 символов';
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
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Редактировать задачу' : 'Новая задача'),
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
                  labelText: 'Название',
                  hintText: 'Например, купить продукты',
                  border: const OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Срок выполнения',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _chooseDueDate,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(
                  _dueDate == null ? 'Выбрать дату' : _formatDate(_dueDate!),
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
                  label: const Text('Убрать срок'),
                ),
              const SizedBox(height: 16),
              Text(
                'Приоритет',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<int>(value: 0, label: Text('Низкий')),
                  ButtonSegment<int>(value: 1, label: Text('Обычный')),
                  ButtonSegment<int>(value: 2, label: Text('Высокий')),
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
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Сохранить' : 'Создать'),
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
