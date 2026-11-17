import 'package:get/get.dart';

import '../services/hive_service.dart';

class AppBinding extends Bindings {
  AppBinding(this._hiveService);

  final HiveService _hiveService;

  @override
  void dependencies() {
    Get.put<HiveService>(
      _hiveService,
      permanent: true,
    ); //hive services stay in GETX's memory for the entire app lifecycle, so we don't have to reinitialize it every time we navigate to a new page.
  }
}
