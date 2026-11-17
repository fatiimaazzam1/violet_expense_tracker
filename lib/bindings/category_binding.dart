import 'package:get/get.dart';

import '../controllers/category_controller.dart';
import '../controllers/expense_controller.dart';
import '../services/hive_service.dart';

class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryController>(
      () => CategoryController(
        Get.find<HiveService>(),
        Get.find<ExpenseController>(),
      ),
    );
  }
}
