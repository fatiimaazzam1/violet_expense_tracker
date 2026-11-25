import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/category_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../routes/app_routes.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_icon.dart';

class HomeView extends GetView<ExpenseController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final settingsController = Get.find<SettingsController>();
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'EXPENSE TRACKER',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text('Expenses', style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
              Obx(
                () => IconButton(
                  key: const Key('home.filters'),
                  tooltip: 'Filter expenses',
                  onPressed: () => _showFilters(
                    context,
                    categoryController.categories.toList(),
                  ),
                  icon: Badge(
                    isLabelVisible: controller.hasActiveFilters,
                    child: const Icon(Icons.filter_list),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final expenses = controller.visibleExpenses;
            final allExpenses = controller.expenses;
            final categories = categoryController.categories.toList();
            final currencySymbol = settingsController.currencySymbol.value;

            if (controller.isLoading.value && allExpenses.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(key: Key('home.loading')),
              );
            }

            if (allExpenses.isEmpty && controller.loadError.value != null) {
              return _HomeMessage(
                key: const Key('home.loadError'),
                icon: Icons.error_outline,
                message: 'Could not load expenses. Please try again.',
                actionLabel: 'Retry',
                onAction: controller.loadExpenses,
              );
            }

            if (allExpenses.isEmpty) {
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

            if (expenses.isEmpty) {
              return _HomeMessage(
                key: const Key('home.filteredEmpty'),
                icon: Icons.filter_list_off,
                message: 'No expenses match these filters',
                description: 'Change or clear your filters to see expenses.',
                actionLabel: 'Clear filters',
                actionKey: const Key('home.clearFilters'),
                onAction: controller.clearFilters,
              );
            }

            final categoriesById = <String, Category>{
              for (final category in categories) category.id: category,
            };
            final groups = _groupExpenses(expenses);

            return ListView.builder(
              key: const Key('home.expenseList'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _ExpenseDaySection(
                  group: group,
                  categoriesById: categoriesById,
                  currencySymbol: currencySymbol,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Future<void> _showFilters(
    BuildContext context,
    List<Category> categories,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ExpenseFilterDialog(
        categories: categories,
        expenseController: controller,
      ),
    );
  }

  void _openAddExpense() {
    Get.toNamed<void>(AppRoutes.addExpense);
  }
}

class _ExpenseFilterDialog extends StatefulWidget {
  const _ExpenseFilterDialog({
    required this.categories,
    required this.expenseController,
  });

  final List<Category> categories;
  final ExpenseController expenseController;

  @override
  State<_ExpenseFilterDialog> createState() => _ExpenseFilterDialogState();
}

class _ExpenseFilterDialogState extends State<_ExpenseFilterDialog> {
  late final Set<String> _selectedCategoryIds;
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = widget.expenseController.selectedCategoryIds.toSet();
    _startDate = widget.expenseController.filterStartDate.value;
    _endDate = widget.expenseController.filterEndDate.value;
  }

  @override
  Widget build(BuildContext context) {
    final hasInvalidRange =
        _startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!);

    return AlertDialog(
      title: const Text('Filter expenses'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Categories', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.categories.map((category) {
                final selected = _selectedCategoryIds.contains(category.id);
                return FilterChip(
                  key: Key('home.filter.category.${category.id}'),
                  label: Text(category.name),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedCategoryIds.add(category.id);
                      } else {
                        _selectedCategoryIds.remove(category.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _DateFilterButton(
              key: const Key('home.filter.startDate'),
              label: 'Start date',
              date: _startDate,
              onPressed: () => _selectDate(isStart: true),
              onClear: () => setState(() => _startDate = null),
            ),
            _DateFilterButton(
              key: const Key('home.filter.endDate'),
              label: 'End date',
              date: _endDate,
              onPressed: () => _selectDate(isStart: false),
              onClear: () => setState(() => _endDate = null),
            ),
            if (hasInvalidRange)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Start date must be on or before end date.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('home.filter.clear'),
          onPressed: () {
            widget.expenseController.clearFilters();
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('home.filter.apply'),
          onPressed: hasInvalidRange
              ? null
              : () {
                  widget.expenseController.applyFilters(
                    categoryIds: _selectedCategoryIds,
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                  Navigator.pop(context);
                },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.date,
    required this.onPressed,
    required this.onClear,
    super.key,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPressed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              date == null
                  ? '$label (optional)'
                  : DateFormat.yMMMd().format(date!),
            ),
          ),
        ),
        if (date != null)
          IconButton(
            tooltip: 'Clear $label',
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}

class _ExpenseDaySection extends StatelessWidget {
  const _ExpenseDaySection({
    required this.group,
    required this.categoriesById,
    required this.currencySymbol,
  });

  final _ExpenseDayGroup group;
  final Map<String, Category> categoriesById;
  final String currencySymbol;

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
                CurrencyFormatter.format(groupTotal, currencySymbol),
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
                    currencySymbol: currencySymbol,
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
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.category,
    required this.currencySymbol,
  });

  final Expense expense;
  final Category? category;
  final String currencySymbol;

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
      key: Key('home.expense.${expense.id}'),
      onTap: () =>
          Get.toNamed<void>(AppRoutes.expenseDetails, arguments: expense.id),
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
        CurrencyFormatter.format(-expense.amount, currencySymbol),
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
                icon: Icon(
                  actionLabel == 'Retry' ? Icons.refresh : Icons.clear,
                ),
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
