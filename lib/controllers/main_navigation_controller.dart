import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void selectTab(int index) {
    if (index >= 0 && index < 4) {
      selectedIndex.value = index;
    }
  }
}
