import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'core/database/app_database.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/today_widget_service.dart';
import 'features/backup/presentation/backup_page.dart';
import 'features/calendar/presentation/calendar_page.dart';
import 'features/clock/presentation/clock_page.dart';
import 'features/focus/presentation/focus_page.dart';
import 'features/habits/presentation/habits_page.dart';
import 'features/reminders/presentation/reminders_page.dart';
import 'features/settings/presentation/settings_page.dart';
import 'features/statistics/presentation/statistics_page.dart';
import 'features/trash/presentation/trash_page.dart';
import 'features/tasks/presentation/tasks_page.dart';
import 'l10n/l10n.dart';

ThemeMode _parseThemeMode(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

Locale? _parseAppLocale(String? value) {
  switch (value) {
    case 'ru':
      return const Locale('ru');
    case 'en':
      return const Locale('en');
    default:
      return null;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  runApp(ProductivityApp(database: database));
}

class ProductivityApp extends StatefulWidget {
  const ProductivityApp({
    super.key,
    required this.database,
    this.initialThemeMode = ThemeMode.system,
    this.initialAccentColor = AppAccentColor.defaultKey,
    this.initialLocale,
    this.initialWidgetTarget,
  });

  final AppDatabase database;
  final ThemeMode initialThemeMode;
  final String initialAccentColor;
  final Locale? initialLocale;
  final String? initialWidgetTarget;

  @override
  State<ProductivityApp> createState() => _ProductivityAppState();
}

class _ProductivityAppState extends State<ProductivityApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late ThemeMode _themeMode;
  late String _accentColorName;
  Locale? _locale;

  @override
  void initState() {
    super.initState();

    _themeMode = widget.initialThemeMode;
    _accentColorName = AppAccentColor.normalize(widget.initialAccentColor);
    _locale = widget.initialLocale;

    TodayWidgetService.setTargetHandler(_openWidgetTarget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadInitialSettings());
      unawaited(_initializeBackgroundServices());
      unawaited(_openInitialWidgetTarget());
    });
  }

  Future<void> _loadInitialSettings() async {
    try {
      final values = await Future.wait<String?>([
        widget.database.getSetting(SettingsPage.themeModeKey),
        widget.database.getSetting(AppAccentColor.settingKey),
        widget.database.getSetting(SettingsPage.languageKey),
      ]);

      if (!mounted) return;

      setState(() {
        _themeMode = _parseThemeMode(values[0]);
        _accentColorName = AppAccentColor.normalize(values[1]);
        _locale = _parseAppLocale(values[2]);
      });
    } catch (error, stackTrace) {
      debugPrint('Не удалось загрузить настройки: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _initializeBackgroundServices() async {
    try {
      await LocalNotificationService.instance.initialize();
      await LocalNotificationService.instance.syncAll(widget.database);
    } catch (error, stackTrace) {
      debugPrint('Не удалось инициализировать уведомления: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await TodayWidgetService.update(widget.database);
    } catch (error, stackTrace) {
      debugPrint('Не удалось обновить виджет: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openInitialWidgetTarget() async {
    try {
      final target = await TodayWidgetService.getInitialTarget();

      if (!mounted || target == null) return;

      _openWidgetTarget(target);
    } catch (error) {
      debugPrint('Не удалось получить маршрут виджета: $error');
    }
  }

  void _openWidgetTarget(String target) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final Widget? page = switch (target) {
      'habits' => HabitsPage(database: widget.database),
      'tasks' => TasksPage(database: widget.database),
      'statistics' => StatisticsPage(database: widget.database),
      _ => null,
    };
    if (page == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => page));
  }

  void _changeThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;

    setState(() {
      _themeMode = mode;
    });
  }

  void _changeAccentColor(String colorName) {
    final normalized = AppAccentColor.normalize(colorName);

    if (_accentColorName == normalized) return;

    setState(() {
      _accentColorName = normalized;
    });
  }

  void _changeLocale(Locale? locale) {
    if (_locale?.languageCode == locale?.languageCode) return;

    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale?.languageCode == 'en') return const Locale('en');
        if (locale?.languageCode == 'ru') return const Locale('ru');
        return const Locale('ru');
      },
      themeMode: _themeMode,
      theme: AppTheme.light(_accentColorName),
      darkTheme: AppTheme.dark(_accentColorName),
      home: DashboardPage(
        database: widget.database,
        themeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
        accentColorName: _accentColorName,
        onAccentColorChanged: _changeAccentColor,
        locale: _locale,
        onLocaleChanged: _changeLocale,
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.database,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.accentColorName = AppAccentColor.defaultKey,
    this.onAccentColorChanged,
    this.locale,
    this.onLocaleChanged,
  });

  final AppDatabase database;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String accentColorName;
  final ValueChanged<String>? onAccentColorChanged;
  final Locale? locale;
  final ValueChanged<Locale?>? onLocaleChanged;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _getGreeting(int hour) {
    if (hour < 12) return context.l10n.homeMorning;
    if (hour < 18) return context.l10n.homeAfternoon;
    return context.l10n.homeEvening;
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatFullDate(date);
  }

  void _openClock() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => const ClockPage()));
  }

  void _openFocus() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FocusPage(database: widget.database),
      ),
    );
  }

  void _openHabits() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => HabitsPage(database: widget.database),
      ),
    );
  }

  void _openTasks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TasksPage(database: widget.database),
      ),
    );
  }

  void _openStatistics() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StatisticsPage(database: widget.database),
      ),
    );
  }

  void _openTrash() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TrashPage(database: widget.database),
      ),
    );
  }

  void _openReminders() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RemindersPage(database: widget.database),
      ),
    );
  }

  void _openBackup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BackupPage(database: widget.database),
      ),
    );
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CalendarPage(database: widget.database),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsPage(
          database: widget.database,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          accentColorName: widget.accentColorName,
          onAccentColorChanged: widget.onAccentColorChanged,
          locale: widget.locale,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
  }

  Widget _actionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool primary = false,
    bool outlined = false,
  }) {
    if (primary) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.settings,
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  _getGreeting(now.hour),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.homeHeadline,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(now),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.onPrimaryContainer.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: colors.onPrimaryContainer,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.l10n.welcomeHeadline,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.homeMessage,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _actionButton(
                  onPressed: _openClock,
                  icon: Icons.access_time_rounded,
                  label: context.l10n.openClock,
                  primary: true,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openFocus,
                  icon: Icons.timer_outlined,
                  label: context.l10n.openFocus,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openCalendar,
                  icon: Icons.calendar_month_rounded,
                  label: context.l10n.openCalendar,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openHabits,
                  icon: Icons.repeat_rounded,
                  label: context.l10n.openHabitTracker,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openTasks,
                  icon: Icons.checklist_rounded,
                  label: context.l10n.openTaskList,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openStatistics,
                  icon: Icons.bar_chart_rounded,
                  label: context.l10n.openStatistics,
                  outlined: true,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openReminders,
                  icon: Icons.notifications_active_outlined,
                  label: context.l10n.openReminders,
                  outlined: true,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openBackup,
                  icon: Icons.backup_rounded,
                  label: context.l10n.openBackup,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openTrash,
                  icon: Icons.delete_outline_rounded,
                  label: context.l10n.trash,
                  outlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
