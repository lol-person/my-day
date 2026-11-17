import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/l10n.dart';
import '../../habits/data/habit_repository.dart';
import '../../tasks/data/task_repository.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({required this.database, super.key});

  final AppDatabase database;

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  late final TaskRepository _taskRepository;
  late final HabitRepository _habitRepository;
  List<Task> _tasks = const [];
  List<Habit> _habits = const [];
  bool _loading = true;
  bool _updating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _taskRepository = TaskRepository(widget.database);
    _habitRepository = HabitRepository(widget.database);
    _load();
  }

  Future<void> _load() async {
    try {
      final tasks = await _taskRepository.getDeletedTasks();
      final habits = await _habitRepository.getDeletedHabits();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _habits = habits;
        _errorMessage = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = context.l10n.trashLoadFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreTask(Task task) async {
    await _runUpdate(() => _taskRepository.restoreTask(task.id));
  }

  Future<void> _restoreHabit(Habit habit) async {
    await _runUpdate(() => _habitRepository.restoreHabitFromTrash(habit.id));
  }

  Future<void> _permanentlyDeleteTask(Task task) async {
    final approved = await _confirmDelete(task.title, isHabit: false);
    if (approved) {
      await _runUpdate(() => _taskRepository.permanentlyDeleteTask(task.id));
    }
  }

  Future<void> _permanentlyDeleteHabit(Habit habit) async {
    final approved = await _confirmDelete(habit.title, isHabit: true);
    if (approved) {
      await _runUpdate(() => _habitRepository.permanentlyDeleteHabit(habit.id));
    }
  }

  Future<bool> _confirmDelete(String title, {required bool isHabit}) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.deletePermanentlyTitle),
            content: Text(
              isHabit
                  ? context.l10n.trashConfirmHabit(title)
                  : context.l10n.trashConfirmTask(title),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(context.l10n.delete),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _runUpdate(Future<void> Function() action) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await action();
      await _load();
      if (mounted && _errorMessage == null) _message(context.l10n.trashUpdated);
    } catch (_) {
      if (mounted) _message(context.l10n.actionFailed);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _deletedDate(DateTime? date) {
    if (date == null) return context.l10n.trashNotDeletedYet;
    return context.l10n.trashDeletedDate(
      MaterialLocalizations.of(context).formatMediumDate(date),
    );
  }

  Widget _entry({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onRestore,
    required VoidCallback onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.restoreFromTrash,
              onPressed: _updating ? null : onRestore,
              icon: const Icon(Icons.restore_rounded),
            ),
            IconButton(
              tooltip: context.l10n.deleteFromTrash,
              onPressed: _updating ? null : onDelete,
              icon: const Icon(Icons.delete_forever_outlined),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = _tasks.isEmpty && _habits.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trash)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.l10n.retry),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    if (empty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 72),
                        child: Column(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 52,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.trashEmpty,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.trashEmptyDescription,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_tasks.isNotEmpty) ...[
                      Text(
                        context.l10n.tasks,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      for (final task in _tasks)
                        _entry(
                          title: task.title,
                          subtitle: _deletedDate(task.deletedAt),
                          icon: Icons.checklist_rounded,
                          onRestore: () => _restoreTask(task),
                          onDelete: () => _permanentlyDeleteTask(task),
                        ),
                      const SizedBox(height: 20),
                    ],
                    if (_habits.isNotEmpty) ...[
                      Text(
                        context.l10n.habits,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      for (final habit in _habits)
                        _entry(
                          title: habit.title,
                          subtitle:
                              '${_deletedDate(habit.deletedAt)} · '
                              '${habit.isArchived ? context.l10n.archivedHabit : context.l10n.activeHabit}',
                          icon: habit.isArchived
                              ? Icons.archive_outlined
                              : Icons.repeat_rounded,
                          onRestore: () => _restoreHabit(habit),
                          onDelete: () => _permanentlyDeleteHabit(habit),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
