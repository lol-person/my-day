// lib/features/backup/presentation/backup_page.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/backup/backup_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final BackupService _backupService;

  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(widget.database);
  }

  Future<void> _exportBackup() async {
    if (_isWorking) return;

    setState(() {
      _isWorking = true;
    });

    try {
      final bytes = await _backupService.createBackup();

      final result = await FilePicker.saveFile(
        dialogTitle: 'Сохранить резервную копию',
        fileName: BackupService.suggestedFileName(),
        bytes: bytes,
      );

      if (!mounted) return;

      if (result == null) {
        _showMessage('Сохранение отменено.');
      } else {
        _showMessage('Резервная копия сохранена.');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Не удалось создать резервную копию: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _importBackup() async {
    if (_isWorking) return;

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (!mounted || file == null) return;

      final length = await file.length();

      if (length != null && length > BackupService.maxBackupBytes) {
        _showMessage('Файл превышает допустимый размер 25 МБ.');
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Восстановить данные?'),
            content: const Text(
              'Текущие задачи, привычки, история выполнения и настройки '
              'будут заменены содержимым выбранной резервной копии. '
              'Это действие нельзя отменить. Рекомендуется сначала '
              'создать резервную копию текущих данных.',
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
                child: const Text('Восстановить'),
              ),
            ],
          );
        },
      );

      if (!mounted || confirmed != true) return;

      setState(() {
        _isWorking = true;
      });

      final summary = await _backupService.restoreBackup(bytes);

      var reminderWarning = false;

      try {
        await LocalNotificationService.instance.syncAll(widget.database);
      } catch (_) {
        reminderWarning = true;
      }

      if (!mounted) return;

      final message = StringBuffer(
        'Данные восстановлены. '
        'Задач: ${summary.tasksCount}, '
        'привычек: ${summary.habitsCount}, '
        'отметок: ${summary.entriesCount}, '
        'настроек: ${summary.settingsCount}.',
      );

      if (reminderWarning) {
        message.write(
          ' Не удалось обновить очередь напоминаний — '
          'проверь настройки напоминаний.',
        );
      }

      _showMessage(message.toString());
    } catch (error) {
      if (!mounted) return;
      _showMessage('Не удалось восстановить копию: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    required bool destructive,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: destructive ? colors.error : colors.primary,
              size: 32,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: destructive
                  ? FilledButton.icon(
                      onPressed: _isWorking ? null : onPressed,
                      icon: const Icon(Icons.restore_rounded),
                      label: Text(buttonLabel),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: _isWorking ? null : onPressed,
                      icon: const Icon(Icons.save_alt_rounded),
                      label: Text(buttonLabel),
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
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Экспорт и импорт',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Твои данные — под твоим контролем',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Резервная копия хранится там, куда ты сам её сохранишь. '
              'Приложение не отправляет её на собственный сервер.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildActionCard(
              icon: Icons.backup_rounded,
              title: 'Создать резервную копию',
              description:
                  'Сохрани задачи, привычки, расписания, историю '
                  'выполнения и настройки в один JSON-файл.',
              buttonLabel: 'Экспортировать данные',
              onPressed: _exportBackup,
              destructive: false,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.settings_backup_restore_rounded,
              title: 'Восстановить из копии',
              description:
                  'Выбери ранее созданный файл. Текущие данные будут '
                  'заменены содержимым копии.',
              buttonLabel: 'Выбрать файл и восстановить',
              onPressed: _importBackup,
              destructive: true,
            ),
            if (_isWorking) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('Обрабатываем данные…')),
            ],
            const SizedBox(height: 24),
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
                  const Expanded(
                    child: Text(
                      'Храни копию в безопасном месте. JSON-файл не зашифрован: '
                      'любой, кто получит его, сможет прочитать содержащиеся '
                      'в нём данные. Для переноса на другое устройство '
                      'скопируй файл и импортируй его там.',
                    ),
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
