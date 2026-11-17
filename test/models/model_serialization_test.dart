import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/models/category.dart';
import 'package:violet_expense_tracker/models/expense.dart';

void main() {
  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'violet_expense_model_test',
    );
    Hive.init(testDirectory.path);
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(CategoryAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  test('Expense adapter persists fields with and without a note', () async {
    final box = await Hive.openBox<Expense>('expense_model_test');
    final withoutNote = Expense(
      id: 'expense-1',
      amount: 24.5,
      categoryId: 'category-1',
      date: DateTime(2026, 11, 16),
    );
    final withNote = Expense(
      id: 'expense-2',
      amount: 8.75,
      categoryId: 'category-1',
      date: DateTime(2026, 11, 15),
      note: 'Lunch',
    );

    await box.put(withoutNote.id, withoutNote);
    await box.put(withNote.id, withNote);

    final storedWithoutNote = box.get(withoutNote.id);
    final storedWithNote = box.get(withNote.id);
    expect(storedWithoutNote, isNotNull);
    expect(storedWithoutNote!.id, withoutNote.id);
    expect(storedWithoutNote.amount, withoutNote.amount);
    expect(storedWithoutNote.categoryId, withoutNote.categoryId);
    expect(storedWithoutNote.date, withoutNote.date);
    expect(storedWithoutNote.note, isNull);
    expect(storedWithNote?.note, withNote.note);

    await box.close();
  });

  test('Category adapter persists all fields', () async {
    final box = await Hive.openBox<Category>('category_model_test');
    const category = Category(
      id: 'category-1',
      name: 'Food',
      iconKey: 'food',
      isDefault: true,
    );

    await box.put(category.id, category);

    final storedCategory = box.get(category.id);
    expect(storedCategory, isNotNull);
    expect(storedCategory!.id, category.id);
    expect(storedCategory.name, category.name);
    expect(storedCategory.iconKey, category.iconKey);
    expect(storedCategory.isDefault, category.isDefault);

    await box.close();
  });
}
