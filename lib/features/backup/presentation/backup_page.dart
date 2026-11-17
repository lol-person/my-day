import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/backup/backup_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../l10n/l10n.dart';

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
    final l10n = context.l10n;

    setState(() {
      _isWorking = true;
    });

    try {
      final bytes = await _backupService.createBackup();

      final result = await FilePicker.saveFile(
        dialogTitle: l10n.createBackup,
        fileName: BackupService.suggestedFileName(),
        bytes: bytes,
      );

      if (!mounted) return;

      if (result == null) {
        _showMessage(context.l10n.backupCanceled);
      } else {
        _showMessage(context.l10n.backupCreated);
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(context.l10n.backupCreateFailed);
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
    final l10n = context.l10n;

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (!mounted || file == null) return;

      final length = await file.length();

      if (length != null && length > BackupService.maxBackupBytes) {
        _showMessage(l10n.fileTooLarge);
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(context.l10n.restoreConfirmTitle),
            content: Text(context.l10n.restoreConfirmBody),
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
                child: Text(context.l10n.restore),
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

      _showMessage(
        reminderWarning
            ? context.l10n.restoreCompleteWithWarning(
                summary.tasksCount,
                summary.habitsCount,
                summary.entriesCount,
                summary.settingsCount,
              )
            : context.l10n.restoreComplete(
                summary.tasksCount,
                summary.habitsCount,
                summary.entriesCount,
                summary.settingsCount,
              ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(context.l10n.restoreFailed);
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
        title: Text(
          context.l10n.backupRestore,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              context.l10n.backupTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.backupDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildActionCard(
              icon: Icons.backup_rounded,
              title: context.l10n.createBackup,
              description: context.l10n.backupExportDescription,
              buttonLabel: context.l10n.exportData,
              onPressed: _exportBackup,
              destructive: false,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.settings_backup_restore_rounded,
              title: context.l10n.restoreBackup,
              description: context.l10n.backupImportDescription,
              buttonLabel: context.l10n.chooseAndRestore,
              onPressed: _importBackup,
              destructive: true,
            ),
            if (_isWorking) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Center(child: Text(context.l10n.processingData)),
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
                  Expanded(child: Text(context.l10n.backupPrivacy)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
