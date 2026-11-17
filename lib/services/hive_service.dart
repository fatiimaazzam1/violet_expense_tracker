import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../models/expense.dart';

class HiveService {
  static const String expenseBoxName = 'expenses';
  static const String categoryBoxName = 'categories';

  static const List<Category> defaultCategories = <Category>[
    Category(id: 'food', name: 'Food', iconKey: 'food', isDefault: true),
    Category(
      id: 'transport',
      name: 'Transport',
      iconKey: 'transport',
      isDefault: true,
    ),
    Category(id: 'bills', name: 'Bills', iconKey: 'bills', isDefault: true),
    Category(
      id: 'shopping',
      name: 'Shopping',
      iconKey: 'shopping',
      isDefault: true,
    ),
  ];

  Box<Expense>? _expenseBox;
  Box<Category>? _categoryBox;
  Future<void>? _initializing;
  bool _hiveInitialized = false;

  Box<Expense> get expenseBox {
    final box = _expenseBox;
    if (box == null || !box.isOpen) {
      throw StateError(
        'HiveService.initialize() must complete before using the expense box.',
      );
    }
    return box;
  }

  Box<Category> get categoryBox {
    final box = _categoryBox;
    if (box == null || !box.isOpen) {
      throw StateError(
        'HiveService.initialize() must complete before using the category box.',
      );
    }
    return box;
  }

  Future<void> initialize({String? directoryPath}) async {
    if ((_expenseBox?.isOpen ?? false) && (_categoryBox?.isOpen ?? false)) {
      return;
    }

    final initializing = _initializing;
    if (initializing != null) {
      await initializing;
      return;
    }

    final initialization = _initialize(directoryPath);
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize(String? directoryPath) async {
    if (!_hiveInitialized) {
      if (directoryPath == null) {
        await Hive.initFlutter();
      } else {
        Hive.init(directoryPath);
      }
      _hiveInitialized = true;
    }

    final expenseAdapter = ExpenseAdapter();
    if (!Hive.isAdapterRegistered(expenseAdapter.typeId)) {
      Hive.registerAdapter(expenseAdapter);
    }

    final categoryAdapter = CategoryAdapter();
    if (!Hive.isAdapterRegistered(categoryAdapter.typeId)) {
      Hive.registerAdapter(categoryAdapter);
    }

    _expenseBox = await Hive.openBox<Expense>(expenseBoxName);
    _categoryBox = await Hive.openBox<Category>(categoryBoxName);
    await _seedDefaultCategories();
  }

  Future<void> _seedDefaultCategories() async {
    for (final category in defaultCategories) {
      if (!categoryBox.containsKey(category.id)) {
        await categoryBox.put(category.id, category);
      }
    }
  }

  Future<List<Expense>> getAllExpenses() async {
    return List<Expense>.unmodifiable(expenseBox.values);
  }

  Future<void> addExpense(Expense expense) async {
    if (expenseBox.containsKey(expense.id)) {
      throw StateError('Expense ${expense.id} already exists.');
    }
    await expenseBox.put(expense.id, expense);
  }

  Future<void> updateExpense(Expense expense) async {
    if (!expenseBox.containsKey(expense.id)) {
      throw StateError('Expense ${expense.id} does not exist.');
    }
    await expenseBox.put(expense.id, expense);
  }

  Future<void> deleteExpense(String id) async {
    if (!expenseBox.containsKey(id)) {
      throw StateError('Expense $id does not exist.');
    }
    await expenseBox.delete(id);
  }

  Future<List<Category>> getAllCategories() async {
    return List<Category>.unmodifiable(categoryBox.values);
  }

  Future<void> addCategory(Category category) async {
    if (categoryBox.containsKey(category.id)) {
      throw StateError('Category ${category.id} already exists.');
    }
    if (categoryBox.values.any(
      (stored) =>
          stored.name.trim().toLowerCase() ==
          category.name.trim().toLowerCase(),
    )) {
      throw StateError('Category name ${category.name} already exists.');
    }
    await categoryBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    final category = categoryBox.get(id);
    if (category == null) {
      throw StateError('Category $id does not exist.');
    }
    if (category.isDefault ||
        defaultCategories.any((defaultCategory) => defaultCategory.id == id)) {
      throw StateError('Default categories cannot be deleted.');
    }
    if (expenseBox.values.any((expense) => expense.categoryId == id)) {
      throw StateError('Reassign expenses before deleting category $id.');
    }
    await categoryBox.delete(id);
  }
}
