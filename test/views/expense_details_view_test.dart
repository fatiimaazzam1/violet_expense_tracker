import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/controllers/settings_controller.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/routes/app_pages.dart';
import 'package:violet_expense_tracker/routes/app_routes.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

import '../helpers/fake_hive_service.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('cancelling deletion keeps the selected expense', (tester) async {
    final service = _serviceWithExpense();
    await _pumpApp(tester, service);
    await _openDetails(tester);

    await tester.tap(find.byKey(const Key('details.delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(service.storedExpenses, hasLength(1));
    expect(find.byKey(const Key('details.content')), findsOneWidget);
  });

  testWidgets('editing from Details keeps the ID and updates Home', (
    tester,
  ) async {
    final service = _serviceWithExpense();
    await _pumpApp(tester, service);
    await _openDetails(tester);

    await tester.tap(find.byKey(const Key('details.edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense.amount')), '15');
    await tester.tap(find.byKey(const Key('expense.save')));
    await tester.pumpAndSettle();

    expect(service.storedExpenses.single.id, 'expense-1');
    expect(service.storedExpenses.single.amount, 15);
    expect(find.text(r'-$15.00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('successful deletion returns Home and removes the last expense', (
    tester,
  ) async {
    final service = _serviceWithExpense();
    await _pumpApp(tester, service);
    await _openDetails(tester);

    await tester.tap(find.byKey(const Key('details.delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('details.delete.confirm')));
    await tester.pumpAndSettle();

    expect(service.storedExpenses, isEmpty);
    expect(find.byKey(const Key('home.empty')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('failed deletion keeps Details open and exposes retry', (
    tester,
  ) async {
    final service = _serviceWithExpense();
    service.deleteExpenseFailure = HiveError('Simulated delete failure.');
    await _pumpApp(tester, service);
    await _openDetails(tester);

    await tester.tap(find.byKey(const Key('details.delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('details.delete.confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('details.content')), findsOneWidget);
    expect(find.byKey(const Key('details.deleteError')), findsOneWidget);
    expect(service.storedExpenses, hasLength(1));
  });

  testWidgets('missing ID has an explicit route back to Home', (tester) async {
    await _pumpApp(tester, FakeHiveService());
    Get.toNamed<void>(AppRoutes.expenseDetails, arguments: 'missing');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('details.notFound')), findsOneWidget);
    await tester.tap(find.byKey(const Key('details.returnHome')));
    await tester.pumpAndSettle();
    expect(find.text('Expenses'), findsOneWidget);
  });
}

FakeHiveService _serviceWithExpense() {
  return FakeHiveService(
    expenses: <Expense>[
      Expense(
        id: 'expense-1',
        amount: 12.5,
        categoryId: 'food',
        date: DateTime(2026, 11, 15),
        note: 'Lunch',
      ),
    ],
  );
}

Future<void> _pumpApp(WidgetTester tester, FakeHiveService service) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialBinding: _AppBinding(service),
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDetails(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home.expense.expense-1')));
  await tester.pumpAndSettle();
}

class _AppBinding extends Bindings {
  _AppBinding(this.service);

  final FakeHiveService service;

  @override
  void dependencies() {
    Get.put<HiveService>(service);
    Get.put<SettingsController>(SettingsController(service));
  }
}
