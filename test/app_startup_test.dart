import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:violet_expense_tracker/main.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  testWidgets('application starts on Home and registers HiveService', (
    tester,
  ) async {
    Get.reset();
    addTearDown(Get.reset);
    final hiveService = HiveService();

    await tester.pumpWidget(VioletExpenseTrackerApp(hiveService: hiveService));
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(Get.find<HiveService>(), same(hiveService));
  });
}
