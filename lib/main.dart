import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/app_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.initialize();

  runApp(VioletExpenseTrackerApp(hiveService: hiveService));
}

class VioletExpenseTrackerApp extends StatelessWidget {
  const VioletExpenseTrackerApp({required this.hiveService, super.key});

  final HiveService hiveService;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Violet Expense Tracker',
      initialBinding: AppBinding(hiveService),
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
    );
  }
}
