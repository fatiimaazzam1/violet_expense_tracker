import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../services/hive_service.dart';

class OnboardingController extends GetxController {
  OnboardingController(this._hiveService);

  final HiveService _hiveService;

  final RxBool isSaving = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  Future<bool> completeOnboarding() async {
    if (isSaving.value) {
      return false;
    }
    isSaving.value = true;
    error.value = null;
    try {
      await _hiveService.saveOnboardingCompleted(true);
      return true;
    } on HiveError catch (failure) {
      error.value = failure;
      return false;
    } on StateError catch (failure) {
      error.value = failure;
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
