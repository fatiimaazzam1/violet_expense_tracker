import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/controllers/expense_controller.dart';
import 'package:violet_expense_tracker/controllers/settings_controller.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/routes/app_pages.dart';
import 'package:violet_expense_tracker/routes/app_routes.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

import '../helpers/fake_hive_service.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('Dashboard shows current-month total, breakdown, and updates', (
    tester,
  ) async {
    final now = DateTime.now();
    final service = FakeHiveService(
      expenses: <Expense>[
        Expense(
          id: 'current',
          amount: 25,
          categoryId: 'food',
          date: DateTime(now.year, now.month, 10),
        ),
        Expense(
          id: 'older',
          amount: 100,
          categoryId: 'transport',
          date: DateTime(now.year, now.month - 1, 10),
        ),
      ],
    );
    await _pumpApp(tester, service);
    await tester.tap(find.byKey(const Key('navigation.dashboard')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('dashboard.monthTotal'))).data,
      r'$25.00',
    );
    expect(find.text('1 recorded expenses'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('dashboard.list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard.category.food')), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);

    Get.find<ExpenseController>().expenses.add(
      Expense(
        id: 'new-current',
        amount: 5,
        categoryId: 'transport',
        date: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('dashboard.monthTotal'))).data,
      r'$30.00',
    );
  });

  testWidgets('Dashboard has a clear no-expenses-this-month state', (
    tester,
  ) async {
    await _pumpApp(tester, FakeHiveService());
    await tester.tap(find.byKey(const Key('navigation.dashboard')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard.empty')), findsOneWidget);
    expect(find.text('No expenses this month'), findsOneWidget);
  });

  testWidgets('Home and Welcome stay within a 320px phone layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester, FakeHiveService());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
    await _pumpApp(tester, FakeHiveService(), initialRoute: AppRoutes.welcome);
    expect(tester.takeException(), isNull);
  });

  testWidgets('currency selection persists and updates Home formatting', (
    tester,
  ) async {
    final service = FakeHiveService(
      expenses: <Expense>[
        Expense(
          id: 'currency-expense',
          amount: 10,
          categoryId: 'food',
          date: DateTime.now(),
        ),
      ],
    );
    await _pumpApp(tester, service);
    await tester.tap(find.byKey(const Key('navigation.settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.currency.EUR')));
    await tester.pumpAndSettle();

    expect(service.settings[HiveService.currencySymbolKey], '€');
    await tester.tap(find.byKey(const Key('navigation.home')));
    await tester.pumpAndSettle();
    expect(find.text('-€10.00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('first launch can retry onboarding persistence before Home', (
    tester,
  ) async {
    final service = FakeHiveService();
    service.saveSettingFailure = HiveError('Simulated settings write failure.');
    await _pumpApp(tester, service, initialRoute: AppRoutes.welcome);

    await tester.tap(find.byKey(const Key('welcome.getStarted')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('welcome.scroll')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('welcome.saveError')), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(service.settings, isEmpty);

    service.saveSettingFailure = null;
    await tester.tap(find.byKey(const Key('welcome.getStarted')));
    await tester.pumpAndSettle();
    expect(service.settings[HiveService.onboardingCompletedKey], isTrue);
    expect(find.text('Expenses'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeHiveService service, {
  String initialRoute = AppRoutes.home,
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialBinding: _AppBinding(service),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    ),
  );
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
