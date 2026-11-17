import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/controllers/expense_controller.dart';
import 'package:violet_expense_tracker/controllers/expense_form_controller.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  late _FakeExpenseController expenseController;

  setUp(() {
    Get.reset();
    expenseController = _FakeExpenseController();
  });

  tearDown(() {
    Get.reset();
  });

  test('create mode starts with blank fields and today as the date', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );
    final today = DateTime.now();

    expect(controller.isEditMode, isFalse);
    expect(controller.amountText.value, isEmpty);
    expect(controller.selectedCategoryId.value, isNull);
    expect(controller.expenseDate.value.year, today.year);
    expect(controller.expenseDate.value.month, today.month);
    expect(controller.expenseDate.value.day, today.day);
    expect(controller.noteText.value, isEmpty);
  });

  test('edit mode loads and prefills the existing expense', () async {
    final expense = _expense(
      id: 'expense-1',
      amount: 24.5,
      categoryId: 'food',
      note: 'Lunch',
    );
    expenseController.expenses.add(expense);

    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.edit,
      expenseId: expense.id,
    );

    expect(controller.isEditMode, isTrue);
    expect(controller.amountText.value, '24.5');
    expect(controller.selectedCategoryId.value, 'food');
    expect(controller.expenseDate.value, expense.date);
    expect(controller.noteText.value, 'Lunch');
    expect(controller.isNotFound.value, isFalse);
  });

  test('accepts a valid positive amount', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );
    _enterValidValues(controller, amount: '12.75');

    expect(controller.validate(), isTrue);
    expect(controller.amountError.value, isNull);
  });

  test('rejects empty, zero, and negative amounts', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );

    for (final amount in <String>['', '0', '-1']) {
      controller.amountText.value = amount;
      controller.selectedCategoryId.value = 'food';

      expect(controller.validate(), isFalse);
      expect(controller.amountError.value, isNotNull);
    }
  });

  test('rejects an empty category', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );
    _enterValidValues(controller);
    controller.selectedCategoryId.value = '  ';

    expect(controller.validate(), isFalse);
    expect(controller.categoryError.value, isNotNull);
  });

  test('accepts notes up to 200 characters and rejects longer notes', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );
    _enterValidValues(controller);
    controller.noteText.value = 'x' * 200;

    expect(controller.validate(), isTrue);

    controller.noteText.value = 'x' * 201;
    expect(controller.validate(), isFalse);
    expect(controller.noteError.value, isNotNull);
  });

  test('a missing expense has a distinct not-found state', () async {
    expenseController.remoteExpenses.clear();
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.edit,
      expenseId: 'missing',
    );

    expect(controller.isNotFound.value, isTrue);
    expect(controller.error.value, isNull);
    expect(expenseController.loadCalls, 1);
    expect(await controller.submit(), ExpenseFormSubmitResult.failure);
  });

  test('a loading failure is visible and can be retried', () async {
    final expense = _expense(id: 'expense-1');
    expenseController.failLoads = true;
    expenseController.loadFailure = HiveError('Simulated read failure.');
    expenseController.remoteExpenses.add(expense);

    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.edit,
      expenseId: expense.id,
    );

    expect(controller.error.value, isA<HiveError>());
    expect(controller.isNotFound.value, isFalse);

    expenseController.failLoads = false;
    expect(await controller.loadExpense(), isTrue);
    expect(controller.error.value, isNull);
    expect(controller.amountText.value, expense.amount.toString());
    expect(controller.isNotFound.value, isFalse);
  });

  test('failed add preserves all entered values', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );
    _enterValidValues(controller, amount: '17.25');
    final enteredDate = DateTime(2026, 11, 14);
    controller.expenseDate.value = enteredDate;
    controller.noteText.value = 'Keep this note';
    expenseController.addResult = false;
    expenseController.writeFailure = HiveError('Simulated write failure.');

    expect(await controller.submit(), ExpenseFormSubmitResult.failure);
    _expectFormValues(
      controller,
      amount: '17.25',
      categoryId: 'food',
      note: 'Keep this note',
    );
    expect(controller.expenseDate.value, enteredDate);
    expect(controller.error.value, isA<HiveError>());
    expect(controller.isSaving.value, isFalse);
  });

  test('failed edit preserves all entered values', () async {
    final expense = _expense(id: 'expense-1');
    expenseController.expenses.add(expense);
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.edit,
      expenseId: expense.id,
    );
    _enterValidValues(controller, amount: '35');
    final enteredDate = DateTime(2026, 11, 13);
    controller.expenseDate.value = enteredDate;
    controller.selectedCategoryId.value = 'transport';
    controller.noteText.value = 'Updated note';
    expenseController.editResult = false;
    expenseController.writeFailure = HiveError('Simulated write failure.');

    expect(await controller.submit(), ExpenseFormSubmitResult.failure);
    _expectFormValues(
      controller,
      amount: '35',
      categoryId: 'transport',
      note: 'Updated note',
    );
    expect(controller.expenseDate.value, enteredDate);
    expect(controller.error.value, isA<HiveError>());
  });

  test('create submission delegates to addExpense', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );
    _enterValidValues(controller, amount: '8.5');
    controller.noteText.value = 'Coffee';

    expect(await controller.submit(), ExpenseFormSubmitResult.success);
    expect(expenseController.addCalls, 1);
    expect(expenseController.editCalls, 0);
    expect(expenseController.lastAmount, 8.5);
    expect(expenseController.lastCategoryId, 'food');
    expect(expenseController.lastNote, 'Coffee');
  });

  test('edit submission delegates with the original expense ID', () async {
    final expense = _expense(id: 'original-id');
    expenseController.expenses.add(expense);
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.edit,
      expenseId: expense.id,
    );
    _enterValidValues(controller, amount: '19');

    expect(await controller.submit(), ExpenseFormSubmitResult.success);
    expect(expenseController.editCalls, 1);
    expect(expenseController.addCalls, 0);
    expect(expenseController.lastExpenseId, 'original-id');
  });

  test('prevents a second submission while the first is saving', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );
    _enterValidValues(controller);
    final gate = Completer<bool>();
    expenseController.addGate = gate;

    final firstSubmission = controller.submit();
    expect(controller.isSaving.value, isTrue);
    expect(await controller.submit(), ExpenseFormSubmitResult.failure);
    expect(expenseController.addCalls, 1);

    gate.complete(true);
    expect(await firstSubmission, ExpenseFormSubmitResult.success);
    expect(expenseController.addCalls, 1);
  });

  test('requires confirmation before saving a future-dated expense', () async {
    final controller = await _createFormController(
      expenseController: expenseController,
      mode: ExpenseFormMode.create,
    );
    _enterValidValues(controller);
    controller.expenseDate.value = DateTime(2999, 1, 1);

    expect(
      await controller.submit(),
      ExpenseFormSubmitResult.confirmationRequired,
    );
    expect(expenseController.addCalls, 0);

    expect(
      await controller.submit(confirmFutureDate: true),
      ExpenseFormSubmitResult.success,
    );
    expect(expenseController.addCalls, 1);
  });
}

Future<ExpenseFormController> _createFormController({
  required _FakeExpenseController expenseController,
  required ExpenseFormMode mode,
  String? expenseId,
}) async {
  final controller = ExpenseFormController(
    expenseController: expenseController,
    mode: mode,
    expenseId: expenseId,
  );
  Get.put<ExpenseFormController>(controller);

  while (controller.isLoading.value) {
    await Future<void>.delayed(Duration.zero);
  }

  return controller;
}

void _enterValidValues(
  ExpenseFormController controller, {
  String amount = '10',
}) {
  controller.amountText.value = amount;
  controller.selectedCategoryId.value = 'food';
  controller.expenseDate.value = DateTime.now();
  controller.noteText.value = '';
}

void _expectFormValues(
  ExpenseFormController controller, {
  required String amount,
  required String categoryId,
  required String note,
}) {
  expect(controller.amountText.value, amount);
  expect(controller.selectedCategoryId.value, categoryId);
  expect(controller.noteText.value, note);
}

Expense _expense({
  required String id,
  double amount = 24.5,
  String categoryId = 'food',
  String? note = 'Existing note',
}) {
  return Expense(
    id: id,
    amount: amount,
    categoryId: categoryId,
    date: DateTime(2026, 11, 15),
    note: note,
  );
}

class _FakeExpenseController extends ExpenseController {
  _FakeExpenseController() : super(HiveService());

  final List<Expense> remoteExpenses = <Expense>[];
  int loadCalls = 0;
  int addCalls = 0;
  int editCalls = 0;
  bool failLoads = false;
  bool addResult = true;
  bool editResult = true;
  Object? loadFailure;
  Object? writeFailure;
  Completer<bool>? addGate;
  double? lastAmount;
  String? lastCategoryId;
  String? lastExpenseId;
  String? lastNote;

  @override
  Future<bool> loadExpenses() async {
    loadCalls++;
    if (failLoads) {
      error.value = loadFailure ?? StateError('Simulated loading failure.');
      return false;
    }
    expenses.assignAll(remoteExpenses);
    error.value = null;
    return true;
  }

  @override
  Future<bool> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    addCalls++;
    lastAmount = amount;
    lastCategoryId = categoryId;
    lastNote = note;
    final gate = addGate;
    if (gate != null) {
      return gate.future;
    }
    if (!addResult) {
      error.value = writeFailure ?? StateError('Simulated add failure.');
    }
    return addResult;
  }

  @override
  Future<bool> editExpense({
    required String id,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    editCalls++;
    lastExpenseId = id;
    lastAmount = amount;
    lastCategoryId = categoryId;
    lastNote = note;
    if (!editResult) {
      error.value = writeFailure ?? StateError('Simulated edit failure.');
    }
    return editResult;
  }
}
