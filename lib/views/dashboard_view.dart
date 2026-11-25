import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/category_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/category.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_icon.dart';

class DashboardView extends GetView<ExpenseController> {
  const DashboardView({super.key});

  static const List<Color> _chartColors = <Color>[
    Color(0xFF7652B8),
    Color(0xFF69A7D8),
    Color(0xFFE6A756),
    Color(0xFF69B69A),
    Color(0xFFCC7182),
    Color(0xFF8C86C8),
    Color(0xFF737C88),
    Color(0xFFB7A168),
  ];

  @override
  Widget build(BuildContext context) {
    final categoriesController = Get.find<CategoryController>();
    final settingsController = Get.find<SettingsController>();
    final theme = Theme.of(context);

    return Obx(() {
      final monthExpenses = controller.currentMonthExpenses;
      final symbol = settingsController.currencySymbol.value;
      final categoriesById = <String, Category>{
        for (final category in categoriesController.categories)
          category.id: category,
      };
      final totalsByCategory = <String, double>{};
      for (final expense in monthExpenses) {
        totalsByCategory.update(
          expense.categoryId,
          (total) => total + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      if (controller.isLoading.value && controller.expenses.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(key: Key('dashboard.loading')),
        );
      }
      if (controller.loadError.value != null && controller.expenses.isEmpty) {
        return _DashboardMessage(
          key: const Key('dashboard.loadError'),
          icon: Icons.error_outline,
          title: 'Could not load expenses',
          description: 'Please try again.',
          onRetry: controller.loadExpenses,
        );
      }

      return ListView(
        key: const Key('dashboard.list'),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'OVERVIEW',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Text('Dashboard', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(DateFormat.yMMMM().format(DateTime.now())),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('This month', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(
                      controller.currentMonthTotal,
                      symbol,
                    ),
                    key: const Key('dashboard.monthTotal'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${monthExpenses.length} recorded expenses'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Spending by category', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (monthExpenses.isEmpty)
            _DashboardMessage(
              key: const Key('dashboard.empty'),
              icon: Icons.pie_chart_outline,
              title: 'No expenses this month',
              description:
                  'Your category breakdown will appear after you add an expense.',
            )
          else ...<Widget>[
            SizedBox(
              height: 210,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 28,
                  sections: totalsByCategory.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((indexedEntry) {
                        final index = indexedEntry.key;
                        final entry = indexedEntry.value;
                        final percent =
                            entry.value / controller.currentMonthTotal * 100;
                        return PieChartSectionData(
                          color: _chartColors[index % _chartColors.length],
                          value: entry.value,
                          title: '${percent.round()}%',
                          radius: 78,
                          titleStyle: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final entry in totalsByCategory.entries)
              ListTile(
                key: Key('dashboard.category.${entry.key}'),
                contentPadding: EdgeInsets.zero,
                leading: CategoryIcon(
                  iconKey: categoriesById[entry.key]?.iconKey ?? entry.key,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  categoriesById[entry.key]?.name ?? 'Category unavailable',
                ),
                trailing: Text(
                  CurrencyFormatter.format(entry.value, symbol),
                  style: theme.textTheme.titleSmall,
                ),
              ),
          ],
          const SizedBox(height: 12),
          Text(
            'Updated automatically as you record expenses.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    });
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.onRetry,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Future<bool> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 44, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(description, textAlign: TextAlign.center),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
