import 'package:get/get.dart';

import '../bindings/category_binding.dart';
import '../bindings/expense_binding.dart';
import '../bindings/expense_form_binding.dart';
import '../controllers/expense_form_controller.dart';
import '../views/expense_form_view.dart';
import '../views/home_view.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomeView(),
      bindings: <Bindings>[ExpenseBinding(), CategoryBinding()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.addExpense,
      page: () => const ExpenseFormView(),
      binding: ExpenseFormBinding(mode: ExpenseFormMode.create),
    ),
    GetPage<dynamic>(
      name: AppRoutes.editExpense,
      page: () => const ExpenseFormView(),
      binding: ExpenseFormBinding(mode: ExpenseFormMode.edit),
    ),
  ];
}
