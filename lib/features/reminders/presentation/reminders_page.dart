import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../l10n/l10n.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool _habitsEnabled = false;
  bool _tasksEnabled = false;

  TimeOfDay _habitsTime = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _tasksTime = const TimeOfDay(hour: 9, minute: 0);

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final database = widget.database;

      final habitsEnabled =
          await database.getSetting(
            LocalNotificationService.habitsEnabledKey,
          ) ==
          'true';

      final tasksEnabled =
          await database.getSetting(LocalNotificationService.tasksEnabledKey) ==
          'true';

      final habitsHour =
          int.tryParse(
            await database.getSetting(LocalNotificationService.habitsHourKey) ??
                '',
          ) ??
          8;

      final habitsMinute =
          int.tryParse(
            await database.getSetting(
                  LocalNotificationService.habitsMinuteKey,
                ) ??
                '',
          ) ??
          30;

      final tasksHour =
          int.tryParse(
            await database.getSetting(LocalNotificationService.tasksHourKey) ??
                '',
          ) ??
          9;

      final tasksMinute =
          int.tryParse(
            await database.getSetting(
                  LocalNotificationService.tasksMinuteKey,
                ) ??
                '',
          ) ??
          0;

      if (!mounted) return;

      setState(() {
        _habitsEnabled = habitsEnabled;
        _tasksEnabled = tasksEnabled;

        _habitsTime = TimeOfDay(
          hour: habitsHour.clamp(0, 23),
          minute: habitsMinute.clamp(0, 59),
        );

        _tasksTime = TimeOfDay(
          hour: tasksHour.clamp(0, 23),
          minute: tasksMinute.clamp(0, 59),
        );
      });
    } catch (error) {
      if (mounted) {
        _showMessage(context.l10n.reminderLoadFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final database = widget.database;

      await database.saveSetting(
        LocalNotificationService.habitsEnabledKey,
        _habitsEnabled.toString(),
      );
      await database.saveSetting(
        LocalNotificationService.habitsHourKey,
        _habitsTime.hour.toString(),
      );
      await database.saveSetting(
        LocalNotificationService.habitsMinuteKey,
        _habitsTime.minute.toString(),
      );

      await database.saveSetting(
        LocalNotificationService.tasksEnabledKey,
        _tasksEnabled.toString(),
      );
      await database.saveSetting(
        LocalNotificationService.tasksHourKey,
        _tasksTime.hour.toString(),
      );
      await database.saveSetting(
        LocalNotificationService.tasksMinuteKey,
        _tasksTime.minute.toString(),
      );

      await LocalNotificationService.instance.syncAll(database);

      if (mounted) {
        _showMessage(context.l10n.settingsSaved);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context.l10n.reminderSaveFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _ensurePermission() async {
    final l10n = context.l10n;
    try {
      final granted = await LocalNotificationService.instance
          .requestNotificationPermission();

      if (!granted) {
        if (mounted) _showMessage(l10n.reminderPermissionSettings);
        return false;
      }

      return true;
    } catch (_) {
      if (mounted) _showMessage(l10n.reminderPermissionFailed);
      return false;
    }
  }

  Future<void> _setHabitsEnabled(bool enabled) async {
    if (_isSaving) return;

    if (enabled && !await _ensurePermission()) return;

    setState(() {
      _habitsEnabled = enabled;
    });

    await _saveSettings();
  }

  Future<void> _setTasksEnabled(bool enabled) async {
    if (_isSaving) return;

    if (enabled && !await _ensurePermission()) return;

    setState(() {
      _tasksEnabled = enabled;
    });

    await _saveSettings();
  }

  Future<void> _chooseHabitsTime() async {
    if (_isSaving) return;

    final selected = await showTimePicker(
      context: context,
      initialTime: _habitsTime,
      helpText: context.l10n.habitReminderTime,
    );

    if (!mounted || selected == null) return;

    setState(() {
      _habitsTime = selected;
    });

    await _saveSettings();
  }

  Future<void> _chooseTasksTime() async {
    if (_isSaving) return;

    final selected = await showTimePicker(
      context: context,
      initialTime: _tasksTime,
      helpText: context.l10n.taskReminderTime,
    );

    if (!mounted || selected == null) return;

    setState(() {
      _tasksTime = selected;
    });

    await _saveSettings();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: _isSaving ? null : onPressed,
      icon: const Icon(Icons.schedule_rounded),
      label: Text('$label: ${time.format(context)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.remindersTitle,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    context.l10n.remindersOnDevice,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.remindersOffline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _habitsEnabled,
                            onChanged: _isSaving ? null : _setHabitsEnabled,
                            secondary: const Icon(Icons.repeat_rounded),
                            title: Text(context.l10n.habitsReminder),
                            subtitle: Text(context.l10n.dailyHabitReminder),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildTimeButton(
                                label: context.l10n.time,
                                time: _habitsTime,
                                onPressed: _chooseHabitsTime,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            value: _tasksEnabled,
                            onChanged: _isSaving ? null : _setTasksEnabled,
                            secondary: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            title: Text(context.l10n.tasksReminder),
                            subtitle: Text(context.l10n.taskDueReminder),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildTimeButton(
                                label: context.l10n.time,
                                time: _tasksTime,
                                onPressed: _chooseTasksTime,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: colors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.remindersTaskTimingNote,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSaving) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
      ),
    );
  }
}
