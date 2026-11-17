import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../services/hive_service.dart';

class ExpenseController extends GetxController {
  ExpenseController(this._hiveService);

  static const int maxNoteLength = 200;
  static const Uuid _uuid = Uuid();

  final HiveService _hiveService;

  final RxList<Expense> expenses = <Expense>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    unawaited(loadExpenses());
  }

  Future<bool> loadExpenses() async {
    isLoading.value = true;
    error.value = null;

    try {
      final loadedExpenses = await _hiveService.getAllExpenses();
      expenses.assignAll(_sortByDate(loadedExpenses));
      return true;
    } on HiveError catch (failure) {
      return _recordError(failure);
    } on StateError catch (failure) {
      return _recordError(failure);
    } on Exception catch (failure) {
      return _recordError(failure);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    error.value = null;
    if (!_validateExpense(amount: amount, categoryId: categoryId, note: note)) {
      return false;
    }

    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
    );

    return _runWrite(() => _hiveService.addExpense(expense), () {
      _upsertExpense(expense);
    });
  }

  Future<bool> editExpense({
    required String id,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    error.value = null;
    if (!_validateExpense(amount: amount, categoryId: categoryId, note: note)) {
      return false;
    }

    final expense = Expense(
      id: id,
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
    );

    return _runWrite(() => _hiveService.updateExpense(expense), () {
      _upsertExpense(expense);
    });
  }

  Future<bool> deleteExpense(String id) {
    error.value = null;
    return _runWrite(() => _hiveService.deleteExpense(id), () {
      expenses.removeWhere((expense) => expense.id == id);
    });
  }

  bool hasExpensesForCategory(String categoryId) {
    return expenses.any((expense) => expense.categoryId == categoryId);
  }

  Future<bool> reassignExpenses({
    required String sourceCategoryId,
    required String destinationCategoryId,
  }) async {
    error.value = null;
    if (sourceCategoryId.trim().isEmpty ||
        destinationCategoryId.trim().isEmpty ||
        sourceCategoryId == destinationCategoryId) {
      return _recordError(
        ArgumentError('Choose two different, non-empty category IDs.'),
      );
    }

    final affectedExpenses = expenses
        .where((expense) => expense.categoryId == sourceCategoryId)
        .toList();
    for (final expense in affectedExpenses) {
      final reassignedExpense = Expense(
        id: expense.id,
        amount: expense.amount,
        categoryId: destinationCategoryId,
        date: expense.date,
        note: expense.note,
      );
      final succeeded = await _runWrite(
        () => _hiveService.updateExpense(reassignedExpense),
        () => _upsertExpense(reassignedExpense),
      );
      if (!succeeded) {
        return false;
      }
    }

    return true;
  }

  bool _validateExpense({
    required double amount,
    required String categoryId,
    required String? note,
  }) {
    if (!amount.isFinite || amount <= 0) {
      error.value = ArgumentError.value(
        amount,
        'amount',
        'Amount must be a positive number.',
      );
      return false;
    }

    if (categoryId.trim().isEmpty) {
      error.value = ArgumentError.value(
        categoryId,
        'categoryId',
        'A category is required.',
      );
      return false;
    }

    if ((note?.length ?? 0) > maxNoteLength) {
      error.value = ArgumentError.value(
        note,
        'note',
        'Note must be $maxNoteLength characters or fewer.',
      );
      return false;
    }

    return true;
  }

  Future<bool> _runWrite(
    Future<void> Function() persist,
    void Function() updateState,
  ) async {
    error.value = null;

    try {
      await persist();
      updateState();
      _sortExpenses();
      return true;
    } on HiveError catch (failure) {
      return _recordError(failure);
    } on StateError catch (failure) {
      return _recordError(failure);
    } on Exception catch (failure) {
      return _recordError(failure);
    }
  }

  bool _recordError(Object failure) {
    error.value = failure;
    return false;
  }

  void _upsertExpense(Expense expense) {
    final index = expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      expenses.add(expense);
    } else {
      expenses[index] = expense;
    }
  }

  void _sortExpenses() {
    expenses.sort((first, second) => second.date.compareTo(first.date));
  }

  List<Expense> _sortByDate(Iterable<Expense> values) {
    final sorted = List<Expense>.of(values);
    sorted.sort((first, second) => second.date.compareTo(first.date));
    return sorted;
  }
}
