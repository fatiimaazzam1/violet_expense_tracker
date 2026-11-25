import 'package:violet_expense_tracker/models/category.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

class FakeHiveService extends HiveService {
  FakeHiveService({
    List<Expense> expenses = const <Expense>[],
    List<Category>? categories,
  }) : storedExpenses = List<Expense>.of(expenses),
       storedCategories = List<Category>.of(
         categories ?? HiveService.defaultCategories,
       );

  final List<Expense> storedExpenses;
  final List<Category> storedCategories;
  final Map<String, Object?> settings = <String, Object?>{};

  Object? getExpensesFailure;
  Object? deleteExpenseFailure;
  Object? updateExpenseFailure;
  Object? addCategoryFailure;
  Object? deleteCategoryFailure;
  Object? getSettingFailure;
  Object? saveSettingFailure;
  int expenseReadCount = 0;

  @override
  Future<List<Expense>> getAllExpenses() async {
    expenseReadCount++;
    final failure = getExpensesFailure;
    if (failure != null) {
      throw failure;
    }
    return List<Expense>.of(storedExpenses);
  }

  @override
  Future<void> addExpense(Expense expense) async {
    if (storedExpenses.any((stored) => stored.id == expense.id)) {
      throw StateError('Expense ${expense.id} already exists.');
    }
    storedExpenses.add(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final failure = updateExpenseFailure;
    if (failure != null) {
      throw failure;
    }
    final index = storedExpenses.indexWhere(
      (stored) => stored.id == expense.id,
    );
    if (index < 0) {
      throw StateError('Expense ${expense.id} does not exist.');
    }
    storedExpenses[index] = expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    final failure = deleteExpenseFailure;
    if (failure != null) {
      throw failure;
    }
    final index = storedExpenses.indexWhere((expense) => expense.id == id);
    if (index < 0) {
      throw StateError('Expense $id does not exist.');
    }
    storedExpenses.removeAt(index);
  }

  @override
  Future<List<Category>> getAllCategories() async {
    return List<Category>.of(storedCategories);
  }

  @override
  Future<void> addCategory(Category category) async {
    final failure = addCategoryFailure;
    if (failure != null) {
      throw failure;
    }
    if (storedCategories.any((stored) => stored.id == category.id)) {
      throw StateError('Category ${category.id} already exists.');
    }
    if (storedCategories.any(
      (stored) =>
          stored.name.trim().toLowerCase() ==
          category.name.trim().toLowerCase(),
    )) {
      throw StateError('Category ${category.name} already exists.');
    }
    storedCategories.add(category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final failure = deleteCategoryFailure;
    if (failure != null) {
      throw failure;
    }
    final index = storedCategories.indexWhere((category) => category.id == id);
    if (index < 0) {
      throw StateError('Category $id does not exist.');
    }
    if (HiveService.defaultCategories.any((category) => category.id == id)) {
      throw StateError('Default categories cannot be deleted.');
    }
    if (storedExpenses.any((expense) => expense.categoryId == id)) {
      throw StateError('Reassign expenses before deleting category $id.');
    }
    storedCategories.removeAt(index);
  }

  @override
  Future<Object?> getSetting(String key) async {
    final failure = getSettingFailure;
    if (failure != null) {
      throw failure;
    }
    return settings[key];
  }

  @override
  Future<void> saveSetting(String key, Object value) async {
    final failure = saveSettingFailure;
    if (failure != null) {
      throw failure;
    }
    settings[key] = value;
  }

  @override
  Future<bool> getOnboardingCompleted() async {
    final value = settings[HiveService.onboardingCompletedKey] ?? false;
    if (value is! bool) {
      throw FormatException('Invalid onboarding state.');
    }
    return value;
  }

  @override
  Future<void> saveOnboardingCompleted(bool completed) async {
    await saveSetting(HiveService.onboardingCompletedKey, completed);
  }
}
