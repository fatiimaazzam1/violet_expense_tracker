import 'package:get/get.dart';

import '../controllers/expense_controller.dart';
import '../controllers/expense_form_controller.dart';

class ExpenseFormBinding extends Bindings {
  ExpenseFormBinding({required this.mode});

  final ExpenseFormMode mode;

  @override
  void dependencies() {
    final expenseId = mode == ExpenseFormMode.edit
        ? Get.arguments as String?
        : null;

    Get.lazyPut<ExpenseFormController>(
      () => ExpenseFormController(
        expenseController: Get.find<ExpenseController>(),
        mode: mode,
        expenseId: expenseId,
      ),
    );
  }
}
