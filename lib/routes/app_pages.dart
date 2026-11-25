import 'package:get/get.dart';

import '../bindings/main_binding.dart';
import '../bindings/onboarding_binding.dart';
import '../bindings/expense_form_binding.dart';
import '../controllers/expense_form_controller.dart';
import '../views/expense_details_view.dart';
import '../views/expense_form_view.dart';
import '../views/main_navigation_view.dart';
import '../views/welcome_view.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const MainNavigationView(),
      binding: MainBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.welcome,
      page: () => const WelcomeView(),
      binding: OnboardingBinding(),
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
    GetPage<dynamic>(
      name: AppRoutes.expenseDetails,
      page: () => const ExpenseDetailsView(),
    ),
  ];
}
