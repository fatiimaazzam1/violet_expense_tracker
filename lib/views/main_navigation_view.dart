import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/main_navigation_controller.dart';
import '../routes/app_routes.dart';
import 'categories_view.dart';
import 'dashboard_view.dart';
import 'home_view.dart';
import 'settings_view.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  static const List<Widget> _destinations = <Widget>[
    HomeView(),
    DashboardView(),
    CategoriesView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIndex = controller.selectedIndex.value;
      return Scaffold(
        body: SafeArea(
          child: IndexedStack(index: selectedIndex, children: _destinations),
        ),
        floatingActionButton: selectedIndex == 0
            ? FloatingActionButton.extended(
                key: const Key('home.addExpense'),
                onPressed: () => Get.toNamed<void>(AppRoutes.addExpense),
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: controller.selectTab,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              key: Key('navigation.home'),
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              key: Key('navigation.dashboard'),
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Dashboard',
            ),
            NavigationDestination(
              key: Key('navigation.categories'),
              icon: Icon(Icons.sell_outlined),
              selectedIcon: Icon(Icons.sell),
              label: 'Categories',
            ),
            NavigationDestination(
              key: Key('navigation.settings'),
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      );
    });
  }
}
