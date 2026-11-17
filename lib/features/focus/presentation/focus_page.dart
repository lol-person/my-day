import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../l10n/l10n.dart';
import '../data/focus_session_repository.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({required this.database, super.key});

  final AppDatabase database;

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  late final FocusSessionRepository _repository;
  FocusTimerStateData? _state;
  List<FocusSession> _history = const [];
  Timer? _ticker;
  bool _busy = true;
  bool _loadErrorShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = FocusSessionRepository(widget.database);
    unawaited(_refresh());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_refresh());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final previous = _state;
      final state = await _repository.load();
      final completed =
          previous?.status == FocusStatus.running.name &&
          previous?.phase == FocusPhase.work.name &&
          state.phase != FocusPhase.work.name;
      final history = previous == null || completed
          ? await _repository.history()
          : _history;
      if (!mounted) return;
      setState(() {
        _state = state;
        _history = history;
        _busy = false;
      });
      _loadErrorShown = false;
      if (completed) {
        await LocalNotificationService.instance.cancelFocusCompletion();
      }
      if (previous == null && state.status == FocusStatus.running.name) {
        await _scheduleWorkNotification(state);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (!_loadErrorShown) {
        _loadErrorShown = true;
        _showMessage(context.l10n.focusLoadFailed);
      }
    }
  }

  Future<void> _start() async {
    final state = await _repository.start();
    if (!mounted) return;
    setState(() => _state = state);
    await _scheduleWorkNotification(state);
  }

  Future<void> _pause() async {
    await LocalNotificationService.instance.cancelFocusCompletion();
    await _setStateFrom(_repository.pause());
  }

  Future<void> _resume() async {
    final state = await _repository.resume();
    if (!mounted) return;
    setState(() => _state = state);
    await _scheduleWorkNotification(state);
  }

  Future<void> _scheduleWorkNotification(FocusTimerStateData state) async {
    final deadline = state.deadline;
    if (deadline == null || state.phase != FocusPhase.work.name) return;
    try {
      final scheduled = await LocalNotificationService.instance
          .scheduleFocusCompletion(deadline);
      if (!scheduled && mounted) {
        _showMessage(context.l10n.notificationPermission);
      }
    } catch (_) {
      if (mounted) _showMessage(context.l10n.notificationScheduleFailed);
    }
  }

  Future<void> _finishEarly() async {
    await LocalNotificationService.instance.cancelFocusCompletion();
    await _setStateFrom(_repository.finishEarly());
  }

  Future<void> _skipBreak() async {
    await LocalNotificationService.instance.cancelFocusCompletion();
    await _setStateFrom(_repository.skipBreak());
  }

  Future<void> _setStateFrom(Future<FocusTimerStateData> future) async {
    final state = await future;
    if (mounted) setState(() => _state = state);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  int _remainingSeconds(FocusTimerStateData state) {
    if (state.status == FocusStatus.paused.name) {
      return state.remainingSeconds ?? 0;
    }
    if (state.status == FocusStatus.running.name && state.deadline != null) {
      final remaining = state.deadline!.difference(DateTime.now());
      return remaining.isNegative
          ? 0
          : (remaining.inMilliseconds + 999) ~/ 1000;
    }
    return switch (state.phase) {
      'shortBreak' => FocusSessionRepository.shortBreakDurationSeconds,
      'longBreak' => FocusSessionRepository.longBreakDurationSeconds,
      _ => FocusSessionRepository.workDurationSeconds,
    };
  }

  String _phaseTitle(String phase) => switch (phase) {
    'shortBreak' => context.l10n.focusShortBreak,
    'longBreak' => context.l10n.focusLongBreak,
    _ => context.l10n.focusWork,
  };

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final phase = state?.phase ?? FocusPhase.work.name;
    final remaining = state == null ? 0 : _remainingSeconds(state);
    final duration = switch (phase) {
      'shortBreak' => FocusSessionRepository.shortBreakDurationSeconds,
      'longBreak' => FocusSessionRepository.longBreakDurationSeconds,
      _ => FocusSessionRepository.workDurationSeconds,
    };
    final progress =
        state?.status == FocusStatus.running.name ||
            state?.status == FocusStatus.paused.name
        ? (1 - remaining / duration).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.focusSession)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _busy && state == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        _phaseTitle(phase),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: SizedBox(
                          width: 250,
                          height: 250,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 10,
                                backgroundColor: colors.surfaceContainerHighest,
                                strokeCap: StrokeCap.round,
                              ),
                              Center(
                                child: Text(
                                  _formatTime(remaining),
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.l10n.focusBreaksRemaining(
                          FocusSessionRepository.sessionsBeforeLongBreak -
                              (state?.completedWorkSessions ?? 0),
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (state?.status == FocusStatus.ready.name ||
                          state == null)
                        FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(context.l10n.start),
                        )
                      else if (state.status == FocusStatus.running.name)
                        FilledButton.icon(
                          onPressed: _pause,
                          icon: const Icon(Icons.pause_rounded),
                          label: Text(context.l10n.pause),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _resume,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(context.l10n.resume),
                        ),
                      if (phase == FocusPhase.work.name &&
                          state?.status != FocusStatus.ready.name)
                        TextButton(
                          onPressed: _finishEarly,
                          child: Text(context.l10n.finishEarly),
                        ),
                      if (phase != FocusPhase.work.name)
                        TextButton(
                          onPressed: _skipBreak,
                          child: Text(context.l10n.skipBreak),
                        ),
                      const SizedBox(height: 32),
                      Text(
                        context.l10n.focusHistory,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_history.isEmpty)
                        Text(
                          context.l10n.focusHistoryEmpty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      else
                        ..._history.map(
                          (session) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(
                              context.l10n.focusMinutes(
                                session.durationSeconds ~/ 60,
                              ),
                            ),
                            subtitle: Text(
                              MaterialLocalizations.of(context)
                                  .formatMediumDate(session.completedAt),
                            ),
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
