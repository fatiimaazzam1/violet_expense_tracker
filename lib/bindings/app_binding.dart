import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../services/hive_service.dart';

class AppBinding extends Bindings {
  AppBinding(this._hiveService, this._settingsController);

  final HiveService _hiveService;
  final SettingsController _settingsController;

  @override
  void dependencies() {
    Get.put<HiveService>(_hiveService, permanent: true);
    Get.put<SettingsController>(_settingsController, permanent: true);
  }
}
