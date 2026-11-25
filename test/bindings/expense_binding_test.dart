import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:violet_expense_tracker/bindings/app_binding.dart';
import 'package:violet_expense_tracker/bindings/main_binding.dart';
import 'package:violet_expense_tracker/controllers/expense_controller.dart';
import 'package:violet_expense_tracker/controllers/settings_controller.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/routes/app_pages.dart';
import 'package:violet_expense_tracker/routes/app_routes.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  tearDown(Get.reset);

  test('Home route uses the main feature binding', () {
    final homeRoute = AppPages.routes.singleWhere(
      (route) => route.name == AppRoutes.home,
    );
    expect(homeRoute.binding.runtimeType, MainBinding);
  });

  test('lazily injects the globally registered HiveService', () async {
    final storedExpense = Expense(
      id: 'expense-1',
      amount: 12,
      categoryId: 'food',
      date: DateTime(2026, 11, 16),
    );
    final hiveService = _FakeHiveService(<Expense>[storedExpense]);

    AppBinding(hiveService, SettingsController(hiveService)).dependencies();
    MainBinding().dependencies();

    final controller = Get.find<ExpenseController>();
    while (controller.isLoading.value) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(Get.find<HiveService>(), same(hiveService));
    expect(hiveService.readCount, 1);
    expect(controller.expenses.single.id, storedExpense.id);
  });
}

class _FakeHiveService extends HiveService {
  _FakeHiveService(this.expenses);

  final List<Expense> expenses;
  int readCount = 0;

  @override
  Future<List<Expense>> getAllExpenses() async {
    readCount++;
    return expenses;
  }
}
