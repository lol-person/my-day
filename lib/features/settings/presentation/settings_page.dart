import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.database,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.accentColorName = AppAccentColor.defaultKey,
    this.onAccentColorChanged,
    this.locale,
    this.onLocaleChanged,
  });

  static const String themeModeKey = 'appearance.themeMode';
  static const String languageKey = 'appearance.language';

  final AppDatabase database;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String accentColorName;
  final ValueChanged<String>? onAccentColorChanged;
  final Locale? locale;
  final ValueChanged<Locale?>? onLocaleChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _selectedMode;
  late String _selectedAccentColor;
  late Locale? _selectedLocale;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _selectedMode = widget.themeMode;
    _selectedAccentColor = AppAccentColor.normalize(widget.accentColorName);
    _selectedLocale = widget.locale;
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
    if (oldWidget.locale?.languageCode != widget.locale?.languageCode) {
      _selectedLocale = widget.locale;
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
      _showMessage(context.l10n.settingsSaved);
    } catch (error) {
      if (mounted) {
        _showMessage(context.l10n.settingsSaveFailed);
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
      _showMessage(context.l10n.accentSaved);
    } catch (error) {
      if (mounted) {
        _showMessage(context.l10n.accentSaveFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveLocale(Locale? locale) async {
    if (_isSaving || _selectedLocale?.languageCode == locale?.languageCode) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.database.saveSetting(
        SettingsPage.languageKey,
        locale?.languageCode ?? 'system',
      );

      if (!mounted) return;

      setState(() {
        _selectedLocale = locale;
      });

      widget.onLocaleChanged?.call(locale);
      _showMessage(context.l10n.settingsSaved);
    } catch (error) {
      if (mounted) {
        _showMessage(context.l10n.settingsSaveFailed);
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
        return context.l10n.systemThemeDescription;
      case ThemeMode.light:
        return context.l10n.lightThemeDescription;
      case ThemeMode.dark:
        return context.l10n.darkThemeDescription;
    }
  }

  String _accentColorLabel(String colorName) => switch (colorName) {
    'green' => context.l10n.colorGreen,
    'red' => context.l10n.colorRed,
    'blue' => context.l10n.colorBlue,
    'orange' => context.l10n.colorOrange,
    'teal' => context.l10n.colorTeal,
    _ => context.l10n.colorPurple,
  };

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

  Widget _languageChip({required String label, required Locale? locale}) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedLocale?.languageCode == locale?.languageCode,
      onSelected: _isSaving
          ? null
          : (selected) {
              if (selected) {
                _saveLocale(locale);
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              context.l10n.settingsAppearance,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.appearanceDescription,
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
                      context.l10n.appTheme,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _themeChip(
                          label: context.l10n.systemTheme,
                          icon: Icons.brightness_auto_rounded,
                          mode: ThemeMode.system,
                        ),
                        _themeChip(
                          label: context.l10n.lightTheme,
                          icon: Icons.light_mode_rounded,
                          mode: ThemeMode.light,
                        ),
                        _themeChip(
                          label: context.l10n.darkTheme,
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
                      context.l10n.appLanguage,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _languageChip(
                          label: context.l10n.systemLanguage,
                          locale: null,
                        ),
                        _languageChip(
                          label: context.l10n.russianLanguage,
                          locale: const Locale('ru'),
                        ),
                        _languageChip(
                          label: context.l10n.englishLanguage,
                          locale: const Locale('en'),
                        ),
                      ],
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
                      context.l10n.accentColor,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.accentDescription,
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
                          label: _accentColorLabel(entry.key),
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
            Text(context.l10n.dataStorage, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.storage_rounded, color: colors.primary),
                title: Text(context.l10n.localDatabase),
                subtitle: Text(context.l10n.localDatabaseDescription),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
