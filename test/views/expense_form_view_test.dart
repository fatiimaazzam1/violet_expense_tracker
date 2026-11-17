import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/controllers/category_controller.dart';
import 'package:violet_expense_tracker/controllers/expense_controller.dart';
import 'package:violet_expense_tracker/controllers/expense_form_controller.dart';
import 'package:violet_expense_tracker/models/category.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/routes/app_pages.dart';
import 'package:violet_expense_tracker/routes/app_routes.dart';
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

  testWidgets('Add form renders the approved fields and actions', (
    tester,
  ) async {
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.byKey(const Key('expense.amount')), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.byKey(const Key('expense.date')), findsOneWidget);
    expect(find.text('Note (optional)'), findsOneWidget);
    expect(find.text('Save expense'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Edit form pre-fills the existing expense', (tester) async {
    final expense = _expense(id: 'edit-1', note: 'Lunch');
    expenseController.expenses.add(expense);
    await _pumpApp(tester, expenseController);

    unawaited(Get.toNamed<void>(AppRoutes.editExpense, arguments: expense.id));
    await tester.pumpAndSettle();

    expect(find.text('Edit Expense'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expense.amount')))
          .controller
          ?.text,
      '24.5',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expense.note')))
          .controller
          ?.text,
      'Lunch',
    );
    expect(expenseController.expenses.single.id, 'edit-1');
  });

  testWidgets('each named form route receives its own mode and controller', (
    tester,
  ) async {
    final expense = _expense(id: 'route-edit');
    expenseController.expenses.add(expense);
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);
    final addController = Get.find<ExpenseFormController>();

    await tester.tap(find.byKey(const Key('expense.cancel')));
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(AppRoutes.editExpense, arguments: expense.id));
    await tester.pumpAndSettle();

    final editController = Get.find<ExpenseFormController>();
    expect(editController, isNot(same(addController)));
    expect(editController.mode, ExpenseFormMode.edit);
    expect(editController.expenseId, expense.id);
  });

  testWidgets('amount and required category errors are shown inline', (
    tester,
  ) async {
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);

    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump();
    expect(find.text('Enter a positive amount.'), findsOneWidget);
    expect(find.text('Select a category.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('expense.amount')), '0');
    await tester.tap(find.byKey(const Key('expense.category.food')));
    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump();
    expect(find.text('Enter a positive amount.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('expense.amount')), '10.25');
    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump();
    expect(find.text('Enter a positive amount.'), findsNothing);
    expect(find.text('Select a category.'), findsNothing);
    await _dismissSuccessMessage(tester);
  });

  testWidgets('note field limits input to 200 characters', (tester) async {
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);

    await tester.enterText(find.byKey(const Key('expense.note')), 'n' * 201);
    await tester.pump();

    final noteField = tester.widget<TextField>(
      find.byKey(const Key('expense.note')),
    );
    expect(noteField.controller?.text.length, 200);
    expect(find.text('200/200'), findsOneWidget);
  });

  testWidgets('date picker updates the displayed date', (tester) async {
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);
    Get.find<ExpenseFormController>().expenseDate.value = DateTime(2026, 1, 1);
    await tester.pump();

    await tester.tap(find.byKey(const Key('expense.date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      Get.find<ExpenseFormController>().expenseDate.value,
      DateTime(2026, 1, 2),
    );
    expect(find.textContaining('2026-01-02'), findsOneWidget);
  });

  testWidgets('future date requires confirmation before saving', (
    tester,
  ) async {
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);
    await _enterValidFormValues(tester);
    Get.find<ExpenseFormController>().expenseDate.value = DateTime(2999, 1, 1);
    await tester.pump();

    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('This date is in the future. Save anyway?'),
      findsOneWidget,
    );
    expect(expenseController.addCalls, 0);

    await tester.tap(find.text('Save anyway'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(expenseController.addCalls, 1);
  });

  testWidgets('successful Add shows feedback and returns to Home', (
    tester,
  ) async {
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);
    await _enterValidFormValues(tester);

    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(expenseController.addCalls, 1);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Expense added'), findsOneWidget);
    await _dismissSuccessMessage(tester);
  });

  testWidgets('successful Edit preserves the original ID and returns Home', (
    tester,
  ) async {
    final expense = _expense(id: 'original-expense');
    expenseController.expenses.add(expense);
    await _pumpApp(tester, expenseController);
    unawaited(Get.toNamed<void>(AppRoutes.editExpense, arguments: expense.id));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('expense.amount')), '31.75');
    await tester.tap(find.byKey(const Key('expense.category.bills')));
    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(expenseController.editCalls, 1);
    expect(expenseController.lastExpenseId, 'original-expense');
    expect(expenseController.lastAmount, 31.75);
    expect(expenseController.lastCategoryId, 'bills');
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Expense updated'), findsOneWidget);
    await _dismissSuccessMessage(tester);
  });

  testWidgets('failed Add keeps entered values and shows an error', (
    tester,
  ) async {
    expenseController.addResult = false;
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);
    await _enterValidFormValues(tester, note: 'Keep my note');

    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump();

    expect(find.byKey(const Key('expense.form')), findsOneWidget);
    expect(find.byKey(const Key('expense.saveError')), findsOneWidget);
    expect(_fieldText(tester, 'expense.amount'), '12.50');
    expect(_fieldText(tester, 'expense.note'), 'Keep my note');
  });

  testWidgets('failed Edit keeps changed values and the original ID', (
    tester,
  ) async {
    final expense = _expense(id: 'stable-id');
    expenseController.expenses.add(expense);
    expenseController.editResult = false;
    await _pumpApp(tester, expenseController);
    unawaited(Get.toNamed<void>(AppRoutes.editExpense, arguments: expense.id));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense.amount')), '36.5');
    await tester.enterText(
      find.byKey(const Key('expense.note')),
      'Retry later',
    );
    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump();

    expect(find.byKey(const Key('expense.saveError')), findsOneWidget);
    expect(_fieldText(tester, 'expense.amount'), '36.5');
    expect(_fieldText(tester, 'expense.note'), 'Retry later');
    expect(expenseController.lastExpenseId, 'stable-id');
  });

  testWidgets('disables duplicate submissions while a write is pending', (
    tester,
  ) async {
    final gate = Completer<bool>();
    expenseController.addGate = gate;
    await _pumpApp(tester, expenseController);
    await _openAddForm(tester);
    await _enterValidFormValues(tester);

    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pump();
    expect(expenseController.addCalls, 1);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('expense.save')))
          .onPressed,
      isNull,
    );

    gate.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(expenseController.addCalls, 1);
    expect(find.text('Expenses'), findsOneWidget);
    await _dismissSuccessMessage(tester);
  });

  testWidgets('edit loading state and not-found state are explicit', (
    tester,
  ) async {
    final gate = Completer<bool>();
    expenseController.loadGate = gate;
    await _pumpApp(tester, expenseController);
    unawaited(
      Get.toNamed<void>(AppRoutes.editExpense, arguments: 'missing-later'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('expense.loading')), findsOneWidget);

    gate.complete(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense.notFound')), findsOneWidget);
    expect(find.text('This expense could not be found.'), findsOneWidget);
  });

  testWidgets('edit load errors offer retry', (tester) async {
    expenseController.loadResult = false;
    expenseController.loadFailure = HiveError('Temporary storage failure.');
    await _pumpApp(tester, expenseController);
    unawaited(Get.toNamed<void>(AppRoutes.editExpense, arguments: 'retry-me'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense.loadError')), findsOneWidget);

    expenseController.loadResult = true;
    expenseController.remoteExpenses.add(_expense(id: 'retry-me'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense.form')), findsOneWidget);
    expect(_fieldText(tester, 'expense.amount'), '24.5');
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  _FakeExpenseController expenseController,
) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialBinding: _FakeExpenseBinding(expenseController),
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openAddForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home.addExpense')));
  await tester.pumpAndSettle();
}

Future<void> _dismissSuccessMessage(WidgetTester tester) async {
  final scaffold = tester.element(find.byType(Scaffold).first);
  ScaffoldMessenger.of(scaffold).hideCurrentSnackBar();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _enterValidFormValues(
  WidgetTester tester, {
  String note = '',
}) async {
  await tester.enterText(find.byKey(const Key('expense.amount')), '12.50');
  await tester.tap(find.byKey(const Key('expense.category.food')));
  if (note.isNotEmpty) {
    await tester.enterText(find.byKey(const Key('expense.note')), note);
  }
}

String _fieldText(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key))).controller?.text ?? '';
}

Expense _expense({required String id, String? note = 'Existing note'}) {
  return Expense(
    id: id,
    amount: 24.5,
    categoryId: 'food',
    date: DateTime(2026, 11, 15),
    note: note,
  );
}

class _FakeExpenseBinding extends Bindings {
  _FakeExpenseBinding(this._expenseController);

  final _FakeExpenseController _expenseController;

  @override
  void dependencies() {
    final hiveService = _FakeHomeHiveService();
    Get.put<HiveService>(hiveService);
    Get.put<ExpenseController>(_expenseController);
    Get.put<CategoryController>(
      CategoryController(hiveService, _expenseController),
    );
  }
}

class _FakeHomeHiveService extends HiveService {
  @override
  Future<List<Category>> getAllCategories() async {
    return HiveService.defaultCategories;
  }
}

class _FakeExpenseController extends ExpenseController {
  _FakeExpenseController() : super(HiveService());

  final List<Expense> remoteExpenses = <Expense>[];
  int addCalls = 0;
  int editCalls = 0;
  bool addResult = true;
  bool editResult = true;
  bool loadResult = true;
  Object? loadFailure;
  Completer<bool>? addGate;
  Completer<bool>? loadGate;
  double? lastAmount;
  String? lastCategoryId;
  String? lastExpenseId;

  @override
  Future<bool> loadExpenses() async {
    if (_skipInitialLoad) {
      _skipInitialLoad = false;
      return true;
    }

    await Future<void>.delayed(Duration.zero);
    final gate = loadGate;
    if (gate != null) {
      final result = await gate.future;
      if (result) {
        expenses.assignAll(remoteExpenses);
      }
      return result;
    }

    if (!loadResult) {
      error.value = loadFailure ?? HiveError('Simulated read failure.');
      return false;
    }
    expenses.assignAll(remoteExpenses);
    error.value = null;
    return true;
  }

  bool _skipInitialLoad = true;

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
    final gate = addGate;
    if (gate != null) {
      return gate.future;
    }
    if (!addResult) {
      error.value = HiveError('Simulated write failure.');
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
    if (!editResult) {
      error.value = HiveError('Simulated write failure.');
    }
    return editResult;
  }
}
