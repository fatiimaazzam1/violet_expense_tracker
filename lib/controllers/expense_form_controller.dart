import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/expense.dart';
import 'expense_controller.dart';

enum ExpenseFormMode { create, edit }

enum ExpenseFormSubmitResult { success, failure, confirmationRequired }

class ExpenseFormController extends GetxController {
  ExpenseFormController({
    required ExpenseController expenseController,
    required this.mode,
    this.expenseId,
  }) : _expenseController = expenseController;

  static const int maxNoteLength = 200;

  final ExpenseController _expenseController;
  final ExpenseFormMode mode;
  final String? expenseId;

  final RxString amountText = ''.obs;
  final RxnString selectedCategoryId = RxnString();
  final Rx<DateTime> expenseDate = DateTime.now().obs;
  final RxString noteText = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isNotFound = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  final RxnString amountError = RxnString();
  final RxnString categoryError = RxnString();
  final RxnString noteError = RxnString();

  bool get isEditMode => mode == ExpenseFormMode.edit;

  @override
  void onInit() {
    super.onInit();
    if (isEditMode) {
      // GetX lifecycle hooks are synchronous; the form exposes this load state.
      unawaited(loadExpense());
    }
  }

  /// Loads the edit record; calling this again retries a failed load.
  Future<bool> loadExpense() async {
    if (!isEditMode) {
      return true;
    }

    isLoading.value = true;
    isNotFound.value = false;
    error.value = null;

    try {
      final id = expenseId;
      if (id == null || id.trim().isEmpty) {
        isNotFound.value = true;
        return false;
      }

      while (_expenseController.isLoading.value) {
        await Future<void>.delayed(Duration.zero);
      }

      var expense = _findExpense(id);
      if (expense == null) {
        final loaded = await _expenseController.loadExpenses();
        if (!loaded) {
          error.value =
              _expenseController.error.value ??
              StateError('Unable to load the expense.');
          return false;
        }
        expense = _findExpense(id);
      }

      if (expense == null) {
        isNotFound.value = true;
        return false;
      }

      _populateFields(expense);
      return true;
    } on HiveError catch (failure) {
      error.value = failure;
      return false;
    } on StateError catch (failure) {
      error.value = failure;
      return false;
    } on Exception catch (failure) {
      error.value = failure;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  bool validate() {
    amountError.value = null;
    categoryError.value = null;
    noteError.value = null;
    error.value = null;

    final parsedAmount = double.tryParse(amountText.value.trim());
    if (parsedAmount == null || !parsedAmount.isFinite || parsedAmount <= 0) {
      amountError.value = 'Enter a positive amount.';
    }

    if (selectedCategoryId.value?.trim().isNotEmpty != true) {
      categoryError.value = 'Select a category.';
    }

    if (noteText.value.length > maxNoteLength) {
      noteError.value = 'Note must be $maxNoteLength characters or fewer.';
    }

    final isValid =
        amountError.value == null &&
        categoryError.value == null &&
        noteError.value == null;
    if (!isValid) {
      error.value = ArgumentError('Please correct the highlighted fields.');
    }
    return isValid;
  }

  /// Returns confirmationRequired so the UI can present the approved dialog.
  Future<ExpenseFormSubmitResult> submit({
    bool confirmFutureDate = false,
  }) async {
    if (isSaving.value ||
        (isEditMode &&
            (isLoading.value ||
                isNotFound.value ||
                expenseId == null ||
                expenseId!.trim().isEmpty))) {
      return ExpenseFormSubmitResult.failure;
    }

    if (!validate()) {
      return ExpenseFormSubmitResult.failure;
    }

    if (_isFutureDate(expenseDate.value) && !confirmFutureDate) {
      return ExpenseFormSubmitResult.confirmationRequired;
    }

    isSaving.value = true;
    error.value = null;

    try {
      final amount = double.parse(amountText.value.trim());
      final categoryId = selectedCategoryId.value!;
      final note = noteText.value.isEmpty ? null : noteText.value;

      final saved = isEditMode
          ? await _expenseController.editExpense(
              id: expenseId!,
              amount: amount,
              categoryId: categoryId,
              date: expenseDate.value,
              note: note,
            )
          : await _expenseController.addExpense(
              amount: amount,
              categoryId: categoryId,
              date: expenseDate.value,
              note: note,
            );

      if (!saved) {
        error.value =
            _expenseController.error.value ??
            StateError('The expense could not be saved.');
        return ExpenseFormSubmitResult.failure;
      }

      return ExpenseFormSubmitResult.success;
    } on HiveError catch (failure) {
      error.value = failure;
      return ExpenseFormSubmitResult.failure;
    } on StateError catch (failure) {
      error.value = failure;
      return ExpenseFormSubmitResult.failure;
    } on Exception catch (failure) {
      error.value = failure;
      return ExpenseFormSubmitResult.failure;
    } finally {
      isSaving.value = false;
    }
  }

  Expense? _findExpense(String id) {
    for (final expense in _expenseController.expenses) {
      if (expense.id == id) {
        return expense;
      }
    }
    return null;
  }

  void _populateFields(Expense expense) {
    amountText.value = expense.amount.toString();
    selectedCategoryId.value = expense.categoryId;
    expenseDate.value = expense.date;
    noteText.value = expense.note ?? '';
    amountError.value = null;
    categoryError.value = null;
    noteError.value = null;
  }

  bool _isFutureDate(DateTime value) {
    final today = DateTime.now();
    final selectedDate = DateTime(value.year, value.month, value.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return selectedDate.isAfter(todayDate);
  }
}
