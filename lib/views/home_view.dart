import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/category_controller.dart';
import '../controllers/expense_controller.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../routes/app_routes.dart';
import '../widgets/category_icon.dart';

class HomeView extends GetView<ExpenseController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final theme = Theme.of(context);
    final homeTheme = theme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: theme.brightness,
      ),
    );

    return Theme(
      data: homeTheme,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'EXPENSE TRACKER',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text('Expenses', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          body: SafeArea(
            child: Obx(() {
              final expenses = controller.expenses.toList();
              final categories = categoryController.categories.toList();

              if (controller.isLoading.value && expenses.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(key: Key('home.loading')),
                );
              }

              if (expenses.isEmpty && controller.error.value != null) {
                return _HomeMessage(
                  key: const Key('home.loadError'),
                  icon: Icons.error_outline,
                  message: 'Could not load expenses. Please try again.',
                  actionLabel: 'Retry',
                  onAction: () {
                    controller.loadExpenses();
                  },
                );
              }

              if (expenses.isEmpty) {
                return _HomeMessage(
                  key: const Key('home.empty'),
                  icon: Icons.receipt_long_outlined,
                  message: 'No expenses yet',
                  description:
                      'Add your first expense to start tracking your spending.',
                  actionLabel: 'Add expense',
                  actionKey: const Key('home.empty.addExpense'),
                  onAction: _openAddExpense,
                );
              }

              final categoriesById = <String, Category>{
                for (final category in categories) category.id: category,
              };
              final groups = _groupExpenses(expenses);

              return ListView.builder(
                key: const Key('home.expenseList'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _ExpenseDaySection(
                    group: group,
                    categoriesById: categoriesById,
                  );
                },
              );
            }),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('home.addExpense'),
            onPressed: _openAddExpense,
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
          ),
        ),
      ),
    );
  }

  void _openAddExpense() {
    Get.toNamed<void>(AppRoutes.addExpense);
  }
}

class _ExpenseDaySection extends StatelessWidget {
  const _ExpenseDaySection({required this.group, required this.categoriesById});

  final _ExpenseDayGroup group;
  final Map<String, Category> categoriesById;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupTotal = group.expenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _formatGroupDate(group.date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatAmount(groupTotal),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: <Widget>[
                for (var index = 0; index < group.expenses.length; index++) ...[
                  _ExpenseRow(
                    expense: group.expenses[index],
                    category: categoriesById[group.expenses[index].categoryId],
                  ),
                  if (index < group.expenses.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                      color: theme.colorScheme.outlineVariant,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatGroupDate(DateTime date) {
    final today = DateTime.now();
    final localDate = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    if (localDate == todayDate) {
      return 'Today';
    }
    if (localDate == yesterday) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy', 'en_US').format(date);
  }

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: r'$').format(amount);
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.category});

  final Expense expense;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = category?.name;
    final iconKey = category?.iconKey ?? expense.categoryId;
    final note = expense.note?.trim();
    final title = note == null || note.isEmpty
        ? categoryName ?? 'Expense'
        : note;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: CategoryIcon(
          iconKey: iconKey,
          size: 22,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        categoryName ?? 'Category unavailable',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        NumberFormat.currency(
          locale: 'en_US',
          symbol: r'$',
        ).format(-expense.amount),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
    required this.icon,
    required this.message,
    this.description,
    this.actionLabel,
    this.actionKey,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? description;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (description != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.icon(
                key: actionKey,
                onPressed: onAction,
                icon: Icon(actionLabel == 'Retry' ? Icons.refresh : Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<_ExpenseDayGroup> _groupExpenses(List<Expense> expenses) {
  final groupedExpenses = <DateTime, List<Expense>>{};
  for (final expense in expenses) {
    final date = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    groupedExpenses.putIfAbsent(date, () => <Expense>[]).add(expense);
  }

  return groupedExpenses.entries
      .map((entry) => _ExpenseDayGroup(date: entry.key, expenses: entry.value))
      .toList();
}

class _ExpenseDayGroup {
  const _ExpenseDayGroup({required this.date, required this.expenses});

  final DateTime date;
  final List<Expense> expenses;
}
