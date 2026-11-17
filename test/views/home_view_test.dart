import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:violet_expense_tracker/controllers/expense_controller.dart';
import 'package:violet_expense_tracker/models/category.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/routes/app_pages.dart';
import 'package:violet_expense_tracker/routes/app_routes.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('shows an explicit empty state and keeps Add expense available', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byKey(const Key('home.empty')), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.byKey(const Key('home.addExpense')), findsOneWidget);
    expect(find.byKey(const Key('home.empty.addExpense')), findsOneWidget);
  });

  testWidgets('shows expenses grouped by date with amounts and categories', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      expenses: <Expense>[
        _expense(
          id: 'lunch',
          amount: 23.25,
          categoryId: 'food',
          date: DateTime(2026, 11, 15),
          note: 'Lunch',
        ),
        _expense(
          id: 'bus',
          amount: 5,
          categoryId: 'transport',
          date: DateTime(2026, 11, 15, 9),
        ),
        _expense(
          id: 'taxi',
          amount: 9.25,
          categoryId: 'missing-category',
          date: DateTime(2026, 11, 7),
          note: 'Taxi',
        ),
      ],
    );

    expect(find.byKey(const Key('home.expenseList')), findsOneWidget);
    expect(find.text('Nov 15, 2026'), findsOneWidget);
    expect(find.text('Nov 7, 2026'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsNWidgets(2));
    expect(find.text('Taxi'), findsOneWidget);
    expect(find.text('Category unavailable'), findsOneWidget);
    expect(find.text(r'-$23.25'), findsOneWidget);
    expect(find.text(r'-$5.00'), findsOneWidget);
    expect(find.text(r'-$9.25'), findsOneWidget);
    expect(find.text(r'$28.25'), findsOneWidget);
  });

  testWidgets('refreshes the list reactively when expenses change', (
    tester,
  ) async {
    await _pumpHome(tester);
    expect(find.byKey(const Key('home.empty')), findsOneWidget);

    final controller = Get.find<ExpenseController>();
    controller.expenses.add(
      _expense(
        id: 'new-expense',
        amount: 12,
        categoryId: 'food',
        date: DateTime(2026, 11, 15),
        note: 'Coffee',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.byKey(const Key('home.empty')), findsNothing);

    controller.expenses.clear();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home.empty')), findsOneWidget);
  });

  testWidgets('Add expense opens the existing form route', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('home.addExpense')));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.byKey(const Key('expense.form')), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  List<Expense> expenses = const <Expense>[],
}) async {
  final service = _FakeHiveService(expenses);

  await tester.pumpWidget(
    GetMaterialApp(
      initialBinding: _HomeBinding(service),
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
    ),
  );
  await tester.pumpAndSettle();
}

Expense _expense({
  required String id,
  required double amount,
  required String categoryId,
  required DateTime date,
  String? note,
}) {
  return Expense(
    id: id,
    amount: amount,
    categoryId: categoryId,
    date: date,
    note: note,
  );
}

class _HomeBinding extends Bindings {
  _HomeBinding(this._hiveService);

  final _FakeHiveService _hiveService;

  @override
  void dependencies() {
    Get.put<HiveService>(_hiveService);
  }
}

class _FakeHiveService extends HiveService {
  _FakeHiveService(this.expenses);

  final List<Expense> expenses;

  @override
  Future<List<Expense>> getAllExpenses() async => expenses;

  @override
  Future<List<Category>> getAllCategories() async =>
      HiveService.defaultCategories;
}
