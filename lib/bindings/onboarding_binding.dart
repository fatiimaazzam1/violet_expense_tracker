import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';
import '../services/hive_service.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(Get.find<HiveService>()),
    );
  }
}
