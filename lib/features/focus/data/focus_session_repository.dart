import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

enum FocusPhase { work, shortBreak, longBreak }

enum FocusStatus { ready, running, paused }

class FocusSessionRepository {
  FocusSessionRepository(this._database);

  final AppDatabase _database;

  static const int workDurationSeconds = 25 * 60;
  static const int shortBreakDurationSeconds = 5 * 60;
  static const int longBreakDurationSeconds = 15 * 60;
  static const int sessionsBeforeLongBreak = 4;

  Future<FocusTimerStateData> load({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _database.transaction(() async {
      final state = await _readOrCreate();
      if (state.status == FocusStatus.running.name &&
          state.deadline != null &&
          !state.deadline!.isAfter(current)) {
        return _completeInterval(state);
      }
      return state;
    });
  }

  Future<FocusTimerStateData> start({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _database.transaction(() async {
      final state = await _readOrCreate();
      final duration = _durationFor(state.phase);
      return _write(
        state.copyWith(
          status: FocusStatus.running.name,
          sessionStartedAt: Value(
            state.phase == FocusPhase.work.name
                ? state.sessionStartedAt ?? current
                : state.sessionStartedAt,
          ),
          deadline: Value(current.add(Duration(seconds: duration))),
          segmentStartedAt: Value(current),
          remainingSeconds: const Value(null),
        ),
      );
    });
  }

  Future<FocusTimerStateData> pause({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _database.transaction(() async {
      final state = await _readOrCreate();
      if (state.status != FocusStatus.running.name) return state;
      if (state.deadline != null && !state.deadline!.isAfter(current)) {
        return _completeInterval(state);
      }
      final deadline = state.deadline;
      final segmentStartedAt = state.segmentStartedAt;
      if (deadline == null || segmentStartedAt == null) return state;
      final remaining = math.max(
        0,
        (deadline.difference(current).inMilliseconds + 999) ~/ 1000,
      );
      final elapsed = math.max(
        0,
        current.difference(segmentStartedAt).inSeconds,
      );
      return _write(
        state.copyWith(
          status: FocusStatus.paused.name,
          deadline: const Value(null),
          segmentStartedAt: const Value(null),
          remainingSeconds: Value(remaining),
          elapsedSeconds: state.elapsedSeconds + elapsed,
        ),
      );
    });
  }

  Future<FocusTimerStateData> resume({DateTime? now}) {
    final current = now ?? DateTime.now();
    return _database.transaction(() async {
      final state = await _readOrCreate();
      final remaining = state.remainingSeconds ?? _durationFor(state.phase);
      return _write(
        state.copyWith(
          status: FocusStatus.running.name,
          deadline: Value(current.add(Duration(seconds: remaining))),
          segmentStartedAt: Value(current),
          remainingSeconds: const Value(null),
        ),
      );
    });
  }

  Future<FocusTimerStateData> finishEarly() {
    return _database.transaction(() async {
      final state = await _readOrCreate();
      return _write(
        state.copyWith(
          phase: FocusPhase.work.name,
          status: FocusStatus.ready.name,
          sessionStartedAt: const Value(null),
          deadline: const Value(null),
          segmentStartedAt: const Value(null),
          remainingSeconds: const Value(null),
          elapsedSeconds: 0,
        ),
      );
    });
  }

  Future<FocusTimerStateData> skipBreak() {
    return _database.transaction(() async {
      final state = await _readOrCreate();
      if (state.phase == FocusPhase.work.name) return state;
      return _write(
        state.copyWith(
          phase: FocusPhase.work.name,
          status: FocusStatus.ready.name,
          deadline: const Value(null),
          segmentStartedAt: const Value(null),
          remainingSeconds: const Value(null),
          sessionStartedAt: const Value(null),
          elapsedSeconds: 0,
        ),
      );
    });
  }

  Future<List<FocusSession>> history() async {
    return (_database.select(
      _database.focusSessions,
    )..orderBy([(session) => OrderingTerm.desc(session.completedAt)])).get();
  }

  Future<FocusTimerStateData> _readOrCreate() async {
    final existing = await (_database.select(
      _database.focusTimerState,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;
    await _database
        .into(_database.focusTimerState)
        .insert(
          FocusTimerStateCompanion.insert(
            id: const Value(1),
            phase: FocusPhase.work.name,
            status: FocusStatus.ready.name,
            completedWorkSessions: 0,
            elapsedSeconds: 0,
          ),
        );
    return (await (_database.select(
      _database.focusTimerState,
    )..where((row) => row.id.equals(1))).getSingle());
  }

  Future<FocusTimerStateData> _write(FocusTimerStateData state) async {
    await (_database.update(
      _database.focusTimerState,
    )..where((row) => row.id.equals(1))).write(state.toCompanion(true));
    return state;
  }

  Future<FocusTimerStateData> _completeInterval(
    FocusTimerStateData state,
  ) async {
    if (state.phase != FocusPhase.work.name) {
      return _write(
        state.copyWith(
          phase: FocusPhase.work.name,
          status: FocusStatus.ready.name,
          deadline: const Value(null),
          segmentStartedAt: const Value(null),
          remainingSeconds: const Value(null),
          sessionStartedAt: const Value(null),
          elapsedSeconds: 0,
        ),
      );
    }
    final startedAt =
        state.sessionStartedAt ??
        state.deadline!.subtract(const Duration(seconds: workDurationSeconds));
    final segmentStart = state.segmentStartedAt ?? startedAt;
    final segmentSeconds = math.min(
      workDurationSeconds - state.elapsedSeconds,
      math.max(0, state.deadline!.difference(segmentStart).inSeconds),
    );
    await _database
        .into(_database.focusSessions)
        .insert(
          FocusSessionsCompanion.insert(
            startedAt: startedAt,
            completedAt: state.deadline!,
            durationSeconds: state.elapsedSeconds + segmentSeconds,
          ),
        );
    final completed = state.completedWorkSessions + 1;
    final longBreak = completed >= sessionsBeforeLongBreak;
    return _write(
      state.copyWith(
        phase: longBreak
            ? FocusPhase.longBreak.name
            : FocusPhase.shortBreak.name,
        status: FocusStatus.ready.name,
        completedWorkSessions: longBreak ? 0 : completed,
        sessionStartedAt: const Value(null),
        deadline: const Value(null),
        segmentStartedAt: const Value(null),
        remainingSeconds: const Value(null),
        elapsedSeconds: 0,
      ),
    );
  }

  int _durationFor(String phase) => switch (phase) {
    'shortBreak' => shortBreakDurationSeconds,
    'longBreak' => longBreakDurationSeconds,
    _ => workDurationSeconds,
  };
}
