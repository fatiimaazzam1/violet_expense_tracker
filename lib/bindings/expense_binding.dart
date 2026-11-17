import 'package:get/get.dart';

import '../controllers/expense_controller.dart';
import '../services/hive_service.dart';

class ExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExpenseController>(
      () => ExpenseController(
        Get.find<HiveService>(),
      ), //connect binding to the global HiveService
    );
  }
}
