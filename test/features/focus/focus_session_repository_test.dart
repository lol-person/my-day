import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/features/focus/data/focus_session_repository.dart';

void main() {
  late AppDatabase database;
  late FocusSessionRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FocusSessionRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('после четырёх рабочих интервалов выбирается длинный перерыв', () async {
    final start = DateTime(2026, 11, 16, 9);
    var state = await repository.load(now: start);

    for (var index = 0; index < 4; index++) {
      state = await repository.start(now: start.add(Duration(hours: index)));
      state = await repository.load(
        now: state.deadline!.add(const Duration(seconds: 1)),
      );
      if (index < 3) {
        expect(state.phase, FocusPhase.shortBreak.name);
        state = await repository.skipBreak();
      }
    }

    expect(state.phase, FocusPhase.longBreak.name);
    expect(state.completedWorkSessions, 0);
    expect(await repository.history(), hasLength(4));
  });

  test('короткий перерыв возвращает таймер к рабочему режиму', () async {
    final start = DateTime(2026, 11, 16, 9);
    await repository.load(now: start);
    final work = await repository.start(now: start);
    final shortBreak = await repository.load(now: work.deadline!);
    final breakRun = await repository.start(now: work.deadline!);
    final nextWork = await repository.load(now: breakRun.deadline!);

    expect(shortBreak.phase, FocusPhase.shortBreak.name);
    expect(nextWork.phase, FocusPhase.work.name);
    expect(nextWork.status, FocusStatus.ready.name);
    expect(await repository.history(), hasLength(1));
  });

  test('пауза и продолжение сохраняют оставшееся время', () async {
    final start = DateTime(2026, 11, 16, 9);
    await repository.load(now: start);
    var state = await repository.start(now: start);
    state = await repository.pause(now: start.add(const Duration(minutes: 10)));

    expect(state.status, FocusStatus.paused.name);
    expect(state.remainingSeconds, 15 * 60);
    expect(state.elapsedSeconds, 10 * 60);

    state = await repository.resume(now: start.add(const Duration(hours: 1)));
    expect(state.status, FocusStatus.running.name);
    expect(state.deadline, start.add(const Duration(hours: 1, minutes: 15)));
  });

  test('состояние восстанавливается после пересоздания репозитория', () async {
    final start = DateTime(2026, 11, 16, 9);
    await repository.load(now: start);
    await repository.start(now: start);
    final reopened = FocusSessionRepository(database);

    final restored = await reopened.load(
      now: start.add(const Duration(minutes: 7)),
    );

    expect(restored.status, FocusStatus.running.name);
    expect(restored.deadline, start.add(const Duration(minutes: 25)));
  });

  test('досрочно прерванный рабочий интервал не попадает в историю', () async {
    final start = DateTime(2026, 11, 16, 9);
    await repository.load(now: start);
    await repository.start(now: start);
    final state = await repository.finishEarly();

    expect(state.phase, FocusPhase.work.name);
    expect(state.status, FocusStatus.ready.name);
    expect(await repository.history(), isEmpty);
  });

  test('завершённый интервал сохраняет фактическую длительность', () async {
    final start = DateTime(2026, 11, 16, 9);
    await repository.load(now: start);
    final running = await repository.start(now: start);
    final state = await repository.load(now: running.deadline!);
    final history = await repository.history();

    expect(state.phase, FocusPhase.shortBreak.name);
    expect(history, hasLength(1));
    expect(history.single.startedAt, start);
    expect(history.single.completedAt, running.deadline);
    expect(history.single.durationSeconds, 25 * 60);
  });
}
