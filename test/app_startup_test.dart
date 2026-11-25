import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:violet_expense_tracker/controllers/settings_controller.dart';
import 'package:violet_expense_tracker/main.dart';
import 'package:violet_expense_tracker/routes/app_routes.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  testWidgets('application starts on Home and registers HiveService', (
    tester,
  ) async {
    Get.reset();
    addTearDown(Get.reset);
    final hiveService = HiveService();
    final settingsController = SettingsController(hiveService);

    await tester.pumpWidget(
      VioletExpenseTrackerApp(
        hiveService: hiveService,
        settingsController: settingsController,
        initialRoute: AppRoutes.home,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(Get.find<HiveService>(), same(hiveService));
  });
}
