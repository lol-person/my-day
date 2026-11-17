import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Настройку можно сохранить и прочитать', () async {
    expect(await database.getSetting('theme'), isNull);

    await database.saveSetting('theme', 'dark');

    expect(await database.getSetting('theme'), 'dark');
  });

  test('Существующую настройку можно обновить', () async {
    await database.saveSetting('theme', 'dark');

    await database.saveSetting('theme', 'light');

    expect(await database.getSetting('theme'), 'light');
  });
}
