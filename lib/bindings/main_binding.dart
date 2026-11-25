import 'package:get/get.dart';

import '../controllers/category_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/main_navigation_controller.dart';
import '../services/hive_service.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ExpenseController>()) {
      Get.lazyPut<ExpenseController>(
        () => ExpenseController(Get.find<HiveService>()),
      );
    }
    if (!Get.isRegistered<CategoryController>()) {
      Get.lazyPut<CategoryController>(
        () => CategoryController(
          Get.find<HiveService>(),
          Get.find<ExpenseController>(),
        ),
      );
    }
    if (!Get.isRegistered<MainNavigationController>()) {
      Get.lazyPut<MainNavigationController>(MainNavigationController.new);
    }
  }
}
