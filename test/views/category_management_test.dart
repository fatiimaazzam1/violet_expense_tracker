import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:violet_expense_tracker/controllers/category_controller.dart';
import 'package:violet_expense_tracker/controllers/settings_controller.dart';
import 'package:violet_expense_tracker/models/category.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/routes/app_pages.dart';
import 'package:violet_expense_tracker/routes/app_routes.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

import '../helpers/fake_hive_service.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('creates a custom category and exposes it in Add Expense', (
    tester,
  ) async {
    final service = FakeHiveService();
    await _pumpApp(tester, service);
    await _openCategories(tester);

    await tester.tap(find.byKey(const Key('categories.add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category.name')), 'Books');
    await tester.tap(find.byKey(const Key('category.form.save')));
    await tester.pumpAndSettle();

    expect(
      Get.find<CategoryController>().categories.any(
        (category) => category.name == 'Books',
      ),
      isTrue,
    );
    await tester.tap(find.byKey(const Key('navigation.home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home.addExpense')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('expense.category.${service.storedCategories.last.id}')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('default categories are protected and linked expenses reassign', (
    tester,
  ) async {
    const customCategory = Category(
      id: 'custom-books',
      name: 'Books',
      iconKey: 'tag',
      isDefault: false,
    );
    final service = FakeHiveService(
      categories: <Category>[...HiveService.defaultCategories, customCategory],
      expenses: <Expense>[
        Expense(
          id: 'expense-1',
          amount: 10,
          categoryId: customCategory.id,
          date: DateTime(2026, 11, 15),
        ),
      ],
    );
    await _pumpApp(tester, service);
    await _openCategories(tester);

    expect(find.byKey(const Key('categories.delete.food')), findsNothing);
    await tester.drag(
      find.byKey(const Key('categories.list')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('categories.delete.custom-books')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category.reassign.destination')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(service.storedExpenses.single.categoryId, 'custom-books');

    await tester.tap(find.byKey(const Key('categories.delete.custom-books')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category.reassign.destination')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category.reassign.confirm')));
    await tester.pumpAndSettle();

    expect(service.storedExpenses.single.categoryId, 'food');
    expect(
      service.storedCategories.any((category) => category.id == 'custom-books'),
      isFalse,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('category creation validation stays visible', (tester) async {
    await _pumpApp(tester, FakeHiveService());
    await _openCategories(tester);
    await tester.tap(find.byKey(const Key('categories.add')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('category.form.save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('category.form.error')), findsOneWidget);
    expect(find.byKey(const Key('category.form.error')), findsOneWidget);
  });
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

Future<void> _openCategories(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('navigation.categories')));
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
