import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  late Directory testDirectory;
  late HiveService service;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'violet_expense_service_test',
    );
    service = HiveService();
    await service.initialize(directoryPath: testDirectory.path);
  });

  tearDownAll(() async {
    if (service.expenseBox.isOpen) {
      await service.expenseBox.close();
    }
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  test('operations fail explicitly before initialization', () async {
    final uninitializedService = HiveService();

    await expectLater(
      uninitializedService.getAllExpenses(),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'initializes adapters and supports the expense persistence lifecycle',
    () async {
      expect(Hive.isAdapterRegistered(0), isTrue);
      expect(Hive.isAdapterRegistered(1), isTrue);
      expect(service.expenseBox.isOpen, isTrue);
      expect(service.expenseBox.name, HiveService.expenseBoxName);

      final original = Expense(
        id: 'expense-1',
        amount: 24.5,
        categoryId: 'category-1',
        date: DateTime(2026, 11, 16),
        note: 'Lunch',
      );

      await service.addExpense(original);
      var storedExpenses = await service.getAllExpenses();
      expect(storedExpenses, hasLength(1));
      expect(storedExpenses.single.id, original.id);
      expect(storedExpenses.single.amount, original.amount);
      expect(storedExpenses.single.note, original.note);
      await expectLater(
        service.addExpense(original),
        throwsA(isA<StateError>()),
      );

      final updated = Expense(
        id: original.id,
        amount: 25.0,
        categoryId: original.categoryId,
        date: original.date,
        note: 'Updated lunch',
      );
      await service.updateExpense(updated);
      storedExpenses = await service.getAllExpenses();
      expect(storedExpenses, hasLength(1));
      expect(storedExpenses.single.id, original.id);
      expect(storedExpenses.single.amount, updated.amount);
      expect(storedExpenses.single.note, updated.note);
      await expectLater(
        service.updateExpense(
          Expense(
            id: 'missing',
            amount: 10,
            categoryId: 'category-1',
            date: DateTime(2026, 11, 16),
          ),
        ),
        throwsA(isA<StateError>()),
      );

      await service.expenseBox.close();
      await expectLater(service.getAllExpenses(), throwsA(isA<StateError>()));
      await service.initialize();
      storedExpenses = await service.getAllExpenses();
      expect(storedExpenses, hasLength(1));
      expect(storedExpenses.single.id, original.id);
      expect(storedExpenses.single.amount, updated.amount);
      expect(storedExpenses.single.note, updated.note);

      await service.deleteExpense(updated.id);
      expect(await service.getAllExpenses(), isEmpty);
      await expectLater(
        service.deleteExpense(updated.id),
        throwsA(isA<StateError>()),
      );
    },
  );
}
