import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Center(
        child: FilledButton.icon(
          key: const Key('home.addExpense'),
          onPressed: () => Get.toNamed<void>(AppRoutes.addExpense),
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        ),
      ),
    );
  }
}
