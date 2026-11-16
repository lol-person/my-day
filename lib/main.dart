// lib/main.dart

import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/backup/presentation/backup_page.dart';
import 'features/calendar/presentation/calendar_page.dart';
import 'features/clock/presentation/clock_page.dart';
import 'features/habits/presentation/habits_page.dart';
import 'features/reminders/presentation/reminders_page.dart';
import 'features/settings/presentation/settings_page.dart';
import 'features/statistics/presentation/statistics_page.dart';
import 'features/tasks/presentation/tasks_page.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  var initialThemeMode = ThemeMode.system;
  var initialAccentColor = AppAccentColor.defaultKey;

  try {
    final savedTheme = await database.getSetting(SettingsPage.themeModeKey);
    initialThemeMode = _parseThemeMode(savedTheme);
  } catch (error) {
    debugPrint('Не удалось загрузить тему: $error');
  }

  try {
    final savedAccentColor = await database.getSetting(
      AppAccentColor.settingKey,
    );
    initialAccentColor = AppAccentColor.normalize(savedAccentColor);
  } catch (error) {
    debugPrint('Не удалось загрузить цвет интерфейса: $error');
  }

  try {
    await LocalNotificationService.instance.initialize();
    await LocalNotificationService.instance.syncAll(database);
  } catch (error, stackTrace) {
    debugPrint('Не удалось инициализировать уведомления: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    ProductivityApp(
      database: database,
      initialThemeMode: initialThemeMode,
      initialAccentColor: initialAccentColor,
    ),
  );
}

class ProductivityApp extends StatefulWidget {
  const ProductivityApp({
    super.key,
    required this.database,
    this.initialThemeMode = ThemeMode.system,
    this.initialAccentColor = AppAccentColor.defaultKey,
  });

  final AppDatabase database;
  final ThemeMode initialThemeMode;
  final String initialAccentColor;

  @override
  State<ProductivityApp> createState() => _ProductivityAppState();
}

class _ProductivityAppState extends State<ProductivityApp> {
  late ThemeMode _themeMode;
  late String _accentColorName;

  @override
  void initState() {
    super.initState();

    _themeMode = widget.initialThemeMode;
    _accentColorName = AppAccentColor.normalize(widget.initialAccentColor);
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

  @override
  Widget build(BuildContext context) {
    final seedColor = AppAccentColor.colorFor(_accentColorName);

    return MaterialApp(
      title: 'Мой день',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F5FA),
          foregroundColor: Color(0xFF211F26),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121116),
      ),
      home: DashboardPage(
        database: widget.database,
        themeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
        accentColorName: _accentColorName,
        onAccentColorChanged: _changeAccentColor,
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
  });

  final AppDatabase database;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String accentColorName;
  final ValueChanged<String>? onAccentColorChanged;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _getGreeting(int hour) {
    if (hour < 12) return 'Доброе утро!';
    if (hour < 18) return 'Добрый день!';
    return 'Добрый вечер!';
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье',
    ];

    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]}';
  }

  void _openClock() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => const ClockPage()));
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
        title: const Text(
          'Мой день',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Настройки',
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Маленькие шаги.\nБольшие результаты.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppAccentColor.heroGradient(
                        widget.accentColorName,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Твой день —\nв твоих руках',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Выбирай главное, двигайся небольшими '
                        'шагами и постепенно создавай полезные привычки.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 15,
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
                  label: 'Открыть часы Flip Clock',
                  primary: true,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openCalendar,
                  icon: Icons.calendar_month_rounded,
                  label: 'Открыть календарь и план дня',
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openHabits,
                  icon: Icons.repeat_rounded,
                  label: 'Открыть трекер привычек',
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openTasks,
                  icon: Icons.checklist_rounded,
                  label: 'Открыть задачник',
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openStatistics,
                  icon: Icons.bar_chart_rounded,
                  label: 'Посмотреть статистику',
                  outlined: true,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openReminders,
                  icon: Icons.notifications_active_outlined,
                  label: 'Настроить напоминания',
                  outlined: true,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  onPressed: _openBackup,
                  icon: Icons.backup_rounded,
                  label: 'Экспорт и импорт данных',
                ),
                const SizedBox(height: 30),
                Text(
                  'Рабочее пространство',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 32,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Здесь всё начнётся',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Привычки, задачи, календарь, статистика, '
                        'напоминания и резервные копии уже доступны.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
