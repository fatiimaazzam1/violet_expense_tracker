import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/controllers/category_controller.dart';
import 'package:violet_expense_tracker/controllers/expense_controller.dart';
import 'package:violet_expense_tracker/models/category.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  late _FakeHiveService hiveService;
  late ExpenseController expenseController;
  late CategoryController categoryController;

  setUp(() async {
    hiveService = _FakeHiveService();
    expenseController = ExpenseController(hiveService);
    await expenseController.loadExpenses();
    categoryController = CategoryController(hiveService, expenseController);
    await categoryController.loadCategories();
  });

  test('adds a valid custom category after storage succeeds', () async {
    final succeeded = await categoryController.addCategory(
      name: '  Books  ',
      iconKey: 'book',
    );

    expect(succeeded, isTrue);
    expect(categoryController.categories, hasLength(5));
    expect(categoryController.categories.last.name, 'Books');
    expect(categoryController.categories.last.iconKey, 'book');
    expect(categoryController.categories.last.isDefault, isFalse);
    expect(
      hiveService.storedCategories.last.id,
      categoryController.categories.last.id,
    );
  });

  test(
    'rejects empty names, duplicate names, and names over 30 characters',
    () async {
      for (final name in <String>[' ', ' FOOD ', 'a' * 31]) {
        final succeeded = await categoryController.addCategory(
          name: name,
          iconKey: 'custom',
        );
        expect(succeeded, isFalse);
        expect(categoryController.error.value, isA<ArgumentError>());
      }

      expect(categoryController.categories, hasLength(4));
      expect(hiveService.storedCategories, hasLength(4));
    },
  );

  test('accepts a category name at the 30-character limit', () async {
    final succeeded = await categoryController.addCategory(
      name: 'a' * 30,
      iconKey: 'custom',
    );

    expect(succeeded, isTrue);
    expect(categoryController.categories.last.name, hasLength(30));
  });

  test('failed category writes do not update reactive categories', () async {
    hiveService.addCategoryFailure = HiveError(
      'Simulated category write error.',
    );

    final succeeded = await categoryController.addCategory(
      name: 'Books',
      iconKey: 'book',
    );

    expect(succeeded, isFalse);
    expect(categoryController.categories, hasLength(4));
    expect(hiveService.storedCategories, hasLength(4));
    expect(categoryController.error.value, isA<HiveError>());
  });

  test(
    'deletes an unreferenced custom category after storage succeeds',
    () async {
      await categoryController.addCategory(name: 'Books', iconKey: 'book');
      final customId = categoryController.categories.last.id;

      final succeeded = await categoryController.deleteCategory(customId);

      expect(succeeded, isTrue);
      expect(
        categoryController.categories.any(
          (category) => category.id == customId,
        ),
        isFalse,
      );
      expect(
        hiveService.storedCategories.any((category) => category.id == customId),
        isFalse,
      );
    },
  );

  test('prevents default-category deletion', () async {
    final succeeded = await categoryController.deleteCategory('food');

    expect(succeeded, isFalse);
    expect(categoryController.categories, hasLength(4));
    expect(hiveService.storedCategories, hasLength(4));
    expect(categoryController.error.value, isA<StateError>());
  });

  test(
    'blocks deleting linked categories unless reassignment is requested',
    () async {
      await categoryController.addCategory(name: 'Books', iconKey: 'book');
      final customId = categoryController.categories.last.id;
      final expense = _expense(id: 'expense-1', categoryId: customId);
      hiveService.storedExpenses.add(expense);
      await expenseController.loadExpenses();

      final succeeded = await categoryController.deleteCategory(customId);

      expect(succeeded, isFalse);
      expect(categoryController.categories, hasLength(5));
      expect(expenseController.expenses.single.categoryId, customId);
      expect(hiveService.storedCategories, hasLength(5));
    },
  );

  test(
    'reassigns expenses through ExpenseController before category deletion',
    () async {
      await categoryController.addCategory(name: 'Books', iconKey: 'book');
      final customId = categoryController.categories.last.id;
      hiveService.storedExpenses.add(
        _expense(id: 'expense-1', categoryId: customId),
      );

      final succeeded = await categoryController.deleteCategory(
        customId,
        reassignToCategoryId: 'food',
      );

      expect(succeeded, isTrue);
      expect(categoryController.categories, hasLength(4));
      expect(expenseController.expenses.single.categoryId, 'food');
      expect(hiveService.storedExpenses.single.categoryId, 'food');
      expect(hiveService.storedCategories, hasLength(4));
    },
  );

  test(
    'failed reassignment keeps the category and expense references intact',
    () async {
      await categoryController.addCategory(name: 'Books', iconKey: 'book');
      final customId = categoryController.categories.last.id;
      hiveService.storedExpenses.add(
        _expense(id: 'expense-1', categoryId: customId),
      );
      await expenseController.loadExpenses();
      hiveService.updateExpenseFailure = HiveError(
        'Simulated expense write error.',
      );

      final succeeded = await categoryController.deleteCategory(
        customId,
        reassignToCategoryId: 'food',
      );

      expect(succeeded, isFalse);
      expect(categoryController.categories, hasLength(5));
      expect(expenseController.expenses.single.categoryId, customId);
      expect(hiveService.storedExpenses.single.categoryId, customId);
      expect(categoryController.error.value, isA<HiveError>());
    },
  );

  test(
    'partial reassignment failure keeps the source category available',
    () async {
      await categoryController.addCategory(name: 'Books', iconKey: 'book');
      final customId = categoryController.categories.last.id;
      hiveService.storedExpenses
        ..add(_expense(id: 'expense-1', categoryId: customId))
        ..add(_expense(id: 'expense-2', categoryId: customId));
      await expenseController.loadExpenses();
      hiveService.failExpenseUpdateId = 'expense-2';

      final succeeded = await categoryController.deleteCategory(
        customId,
        reassignToCategoryId: 'food',
      );

      expect(succeeded, isFalse);
      expect(categoryController.categories, hasLength(5));
      expect(
        hiveService.storedCategories.any((item) => item.id == customId),
        isTrue,
      );
      expect(
        hiveService.storedExpenses.map((expense) => expense.categoryId),
        unorderedEquals(<String>['food', customId]),
      );
      expect(
        expenseController.expenses.map((expense) => expense.categoryId),
        unorderedEquals(<String>['food', customId]),
      );
    },
  );

  test('failed category deletion preserves the reactive category', () async {
    await categoryController.addCategory(name: 'Books', iconKey: 'book');
    final customId = categoryController.categories.last.id;
    hiveService.deleteCategoryFailure = HiveError('Simulated delete error.');

    final succeeded = await categoryController.deleteCategory(customId);

    expect(succeeded, isFalse);
    expect(categoryController.categories, hasLength(5));
    expect(hiveService.storedCategories, hasLength(5));
    expect(categoryController.error.value, isA<HiveError>());
  });

  test(
    'load failure exposes the error without clearing existing state',
    () async {
      final existingCategories = List<Category>.of(
        categoryController.categories,
      );
      hiveService.getCategoriesFailure = HiveError('Simulated read error.');

      final succeeded = await categoryController.loadCategories();

      expect(succeeded, isFalse);
      expect(categoryController.categories, existingCategories);
      expect(categoryController.error.value, isA<HiveError>());
    },
  );
}

Expense _expense({required String id, required String categoryId}) {
  return Expense(
    id: id,
    amount: 10,
    categoryId: categoryId,
    date: DateTime(2026, 1, 1),
  );
}

class _FakeHiveService extends HiveService {
  final List<Category> storedCategories = List<Category>.of(
    HiveService.defaultCategories,
  );
  final List<Expense> storedExpenses = <Expense>[];
  Object? addCategoryFailure;
  Object? deleteCategoryFailure;
  Object? getCategoriesFailure;
  Object? updateExpenseFailure;
  String? failExpenseUpdateId;

  @override
  Future<List<Category>> getAllCategories() async {
    final failure = getCategoriesFailure;
    if (failure != null) {
      throw failure;
    }
    return List<Category>.of(storedCategories);
  }

  @override
  Future<void> addCategory(Category category) async {
    final failure = addCategoryFailure;
    if (failure != null) {
      throw failure;
    }
    storedCategories.add(category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final failure = deleteCategoryFailure;
    if (failure != null) {
      throw failure;
    }
    storedCategories.removeWhere((category) => category.id == id);
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    return List<Expense>.of(storedExpenses);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final failure = updateExpenseFailure;
    if (failure != null || failExpenseUpdateId == expense.id) {
      throw failure ?? HiveError('Simulated expense write error.');
    }
    final index = storedExpenses.indexWhere(
      (stored) => stored.id == expense.id,
    );
    if (index == -1) {
      throw StateError('Expense ${expense.id} does not exist.');
    }
    storedExpenses[index] = expense;
  }
}
