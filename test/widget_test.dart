// test/widget_test.dart

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/core/database/app_database.dart';
import 'package:productivity_app/main.dart';

void main() {
  testWidgets('Главный экран приложения отображается', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());

    addTearDown(database.close);

    await tester.pumpWidget(ProductivityApp(database: database));

    await tester.pumpAndSettle();

    // Проверяем элементы, которые видны в начале экрана.
    expect(find.text('Мой день'), findsOneWidget);
    expect(find.text('Локальная база данных подключена'), findsNothing);

    // Прокручиваем экран до карточки в нижней части страницы.
    await tester.scrollUntilVisible(
      find.text('Здесь всё начнётся'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();

    expect(find.text('Здесь всё начнётся'), findsOneWidget);
  });
}
