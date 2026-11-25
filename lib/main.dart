import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/app_binding.dart';
import 'controllers/settings_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.initialize();
  final settingsController = SettingsController(hiveService);
  final settingsLoaded = await settingsController.loadSettings();
  if (!settingsLoaded) {
    throw StateError(
      'Could not load saved settings: ${settingsController.error.value}',
    );
  }
  final onboardingCompleted = await hiveService.getOnboardingCompleted();

  runApp(
    VioletExpenseTrackerApp(
      hiveService: hiveService,
      settingsController: settingsController,
      initialRoute: onboardingCompleted ? AppRoutes.home : AppRoutes.welcome,
    ),
  );
}

class VioletExpenseTrackerApp extends StatelessWidget {
  const VioletExpenseTrackerApp({
    required this.hiveService,
    required this.settingsController,
    required this.initialRoute,
    super.key,
  });

  final HiveService hiveService;
  final SettingsController settingsController;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Violet Expense Tracker',
      initialBinding: AppBinding(hiveService, settingsController),
      initialRoute: initialRoute,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settingsController.themeMode.value,
      getPages: AppPages.routes,
    );
  }
}
