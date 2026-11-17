import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/models/category.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  late Directory testDirectory;
  late HiveService service;

  setUp(() async {
    await Hive.close();
    testDirectory = await Directory.systemTemp.createTemp(
      'violet_category_service_test',
    );
    service = HiveService();
    await service.initialize(directoryPath: testDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  test('opens typed boxes and seeds stable default IDs exactly once', () async {
    expect(Hive.isAdapterRegistered(0), isTrue);
    expect(Hive.isAdapterRegistered(1), isTrue);
    expect(service.expenseBox.name, HiveService.expenseBoxName);
    expect(service.categoryBox.name, HiveService.categoryBoxName);

    final categories = await service.getAllCategories();
    expect(categories.map((category) => category.id).toSet(), <String>{
      'food',
      'transport',
      'bills',
      'shopping',
    });
    expect(categories.where((category) => category.isDefault), hasLength(4));

    await service.addCategory(
      const Category(
        id: 'custom-1',
        name: 'Books',
        iconKey: 'book',
        isDefault: false,
      ),
    );
    await service.initialize();

    expect(await service.getAllCategories(), hasLength(5));
  });

  test(
    'preserves existing categories and fills partially missing defaults',
    () async {
      const preservedFood = Category(
        id: 'food',
        name: 'Saved Food',
        iconKey: 'saved-food',
        isDefault: true,
      );
      await service.categoryBox.put(preservedFood.id, preservedFood);
      await service.categoryBox.delete('transport');
      const custom = Category(
        id: 'custom-1',
        name: 'Books',
        iconKey: 'book',
        isDefault: false,
      );
      await service.addCategory(custom);
      await service.categoryBox.close();

      await service.initialize();

      expect(service.categoryBox.get('food')?.name, 'Saved Food');
      expect(service.categoryBox.get('food')?.iconKey, 'saved-food');
      expect(service.categoryBox.get('transport'), isNotNull);
      expect(service.categoryBox.get('bills'), isNotNull);
      expect(service.categoryBox.get('shopping'), isNotNull);
      expect(service.categoryBox.get(custom.id)?.name, custom.name);
      expect(await service.getAllCategories(), hasLength(5));
    },
  );

  test('adds, reads, deletes, and persists custom categories', () async {
    const custom = Category(
      id: 'custom-1',
      name: 'Books',
      iconKey: 'book',
      isDefault: false,
    );
    await service.addCategory(custom);
    expect(
      (await service.getAllCategories()).singleWhere(
        (category) => category.id == custom.id,
      ),
      same(custom),
    );

    await service.categoryBox.close();
    await service.expenseBox.close();
    await service.initialize();

    expect(service.categoryBox.get(custom.id)?.name, custom.name);
    await service.deleteCategory(custom.id);
    expect(service.categoryBox.containsKey(custom.id), isFalse);
  });

  test(
    'rejects duplicate IDs, missing categories, defaults, and linked deletes',
    () async {
      const custom = Category(
        id: 'custom-1',
        name: 'Books',
        iconKey: 'book',
        isDefault: false,
      );
      await service.addCategory(custom);

      await expectLater(
        service.addCategory(custom),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.addCategory(
          const Category(
            id: 'custom-2',
            name: ' books ',
            iconKey: 'book',
            isDefault: false,
          ),
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.deleteCategory('missing'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.deleteCategory('food'),
        throwsA(isA<StateError>()),
      );

      await service.addExpense(
        Expense(
          id: 'expense-1',
          amount: 10,
          categoryId: custom.id,
          date: DateTime(2026, 1, 1),
        ),
      );
      await expectLater(
        service.deleteCategory(custom.id),
        throwsA(isA<StateError>()),
      );
      expect(service.categoryBox.containsKey(custom.id), isTrue);
    },
  );

  test(
    'storage operations report errors when the category box is closed',
    () async {
      await service.categoryBox.close();

      await expectLater(service.getAllCategories(), throwsA(isA<StateError>()));
      await expectLater(
        service.addCategory(
          const Category(
            id: 'custom-1',
            name: 'Books',
            iconKey: 'book',
            isDefault: false,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
