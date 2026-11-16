// lib/features/settings/presentation/settings_page.dart

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.database,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.accentColorName = AppAccentColor.defaultKey,
    this.onAccentColorChanged,
  });

  static const String themeModeKey = 'appearance.themeMode';

  final AppDatabase database;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String accentColorName;
  final ValueChanged<String>? onAccentColorChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _selectedMode;
  late String _selectedAccentColor;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _selectedMode = widget.themeMode;
    _selectedAccentColor = AppAccentColor.normalize(widget.accentColorName);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.themeMode != widget.themeMode) {
      _selectedMode = widget.themeMode;
    }

    if (oldWidget.accentColorName != widget.accentColorName) {
      _selectedAccentColor = AppAccentColor.normalize(widget.accentColorName);
    }
  }

  String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    if (_isSaving || mode == _selectedMode) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.database.saveSetting(
        SettingsPage.themeModeKey,
        _encodeThemeMode(mode),
      );

      if (!mounted) return;

      setState(() {
        _selectedMode = mode;
      });

      widget.onThemeModeChanged(mode);
      _showMessage('Настройки сохранены');
    } catch (error) {
      if (mounted) {
        _showMessage('Не удалось сохранить настройки: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveAccentColor(String colorName) async {
    if (_isSaving || colorName == _selectedAccentColor) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.database.saveSetting(AppAccentColor.settingKey, colorName);

      if (!mounted) return;

      setState(() {
        _selectedAccentColor = colorName;
      });

      widget.onAccentColorChanged?.call(colorName);
      _showMessage('Цвет интерфейса сохранён');
    } catch (error) {
      if (mounted) {
        _showMessage('Не удалось сохранить цвет: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _themeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Приложение следует настройкам Android.';
      case ThemeMode.light:
        return 'Всегда используется светлое оформление.';
      case ThemeMode.dark:
        return 'Всегда используется тёмное оформление.';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _themeChip({
    required String label,
    required IconData icon,
    required ThemeMode mode,
  }) {
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: _selectedMode == mode,
      onSelected: _isSaving
          ? null
          : (selected) {
              if (selected) {
                _saveThemeMode(mode);
              }
            },
    );
  }

  Widget _accentColorChip({
    required String colorName,
    required String label,
    required Color color,
  }) {
    return ChoiceChip(
      avatar: CircleAvatar(radius: 9, backgroundColor: color),
      label: Text(label),
      selected: _selectedAccentColor == colorName,
      onSelected: _isSaving
          ? null
          : (selected) {
              if (selected) {
                _saveAccentColor(colorName);
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Настройки',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Внешний вид',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выбери оформление, которое тебе удобно. '
              'Изменение применяется сразу.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тема приложения',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _themeChip(
                          label: 'Система',
                          icon: Icons.brightness_auto_rounded,
                          mode: ThemeMode.system,
                        ),
                        _themeChip(
                          label: 'Светлая',
                          icon: Icons.light_mode_rounded,
                          mode: ThemeMode.light,
                        ),
                        _themeChip(
                          label: 'Тёмная',
                          icon: Icons.dark_mode_rounded,
                          mode: ThemeMode.dark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _themeDescription(_selectedMode),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Основной цвет',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Меняет акцентный цвет кнопок, выделений '
                      'и главного блока.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppAccentColor.colors.entries.map((entry) {
                        return _accentColorChip(
                          colorName: entry.key,
                          label: AppAccentColor.names[entry.key]!,
                          color: entry.value,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            if (_isSaving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 24),
            Text(
              'Хранение данных',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.storage_rounded, color: colors.primary),
                title: const Text('Локальная база данных'),
                subtitle: const Text(
                  'Задачи, привычки и настройки хранятся на устройстве. '
                  'Тема и выбранный цвет включаются в резервную копию '
                  'через экспорт настроек.',
                ),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
