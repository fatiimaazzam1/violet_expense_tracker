import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:violet_expense_tracker/bindings/app_binding.dart';
import 'package:violet_expense_tracker/bindings/category_binding.dart';
import 'package:violet_expense_tracker/bindings/expense_binding.dart';
import 'package:violet_expense_tracker/controllers/category_controller.dart';
import 'package:violet_expense_tracker/controllers/expense_controller.dart';
import 'package:violet_expense_tracker/models/category.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/routes/app_pages.dart';
import 'package:violet_expense_tracker/routes/app_routes.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  tearDown(Get.reset);

  test('Home route binds both expense and category controllers', () {
    final homeRoute = AppPages.routes.singleWhere(
      (route) => route.name == AppRoutes.home,
    );

    expect(
      homeRoute.bindings.map((binding) => binding.runtimeType),
      containsAll(<Type>[ExpenseBinding, CategoryBinding]),
    );
  });

  test(
    'CategoryController reuses the app HiveService and ExpenseController',
    () async {
      final hiveService = _FakeHiveService();
      AppBinding(hiveService).dependencies();
      ExpenseBinding().dependencies();
      CategoryBinding().dependencies();

      final categoryController = Get.find<CategoryController>();
      final expenseController = Get.find<ExpenseController>();
      while (categoryController.isLoading.value ||
          expenseController.isLoading.value) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(Get.find<HiveService>(), same(hiveService));
      expect(categoryController.categories, hasLength(4));
      expect(expenseController.expenses, hasLength(1));
    },
  );
}

class _FakeHiveService extends HiveService {
  @override
  Future<List<Category>> getAllCategories() async {
    return HiveService.defaultCategories;
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    return <Expense>[
      Expense(
        id: 'expense-1',
        amount: 12,
        categoryId: 'food',
        date: DateTime(2026, 1, 1),
      ),
    ];
  }
}
