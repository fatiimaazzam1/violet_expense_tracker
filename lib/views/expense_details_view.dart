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

class ExpenseDetailsView extends GetView<ExpenseController> {
  const ExpenseDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final categoriesController = Get.find<CategoryController>();
    final settingsController = Get.find<SettingsController>();
    final argument = Get.arguments;
    final expenseId = argument is String ? argument : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Expense details')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.expenses.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(key: Key('details.loading')),
            );
          }
          if (controller.loadError.value != null &&
              controller.expenses.isEmpty) {
            return _DetailsMessage(
              key: const Key('details.loadError'),
              title: 'Could not load this expense',
              actionLabel: 'Retry',
              onAction: () {
                controller.loadExpenses();
              },
            );
          }
          final expense = expenseId == null
              ? null
              : _findExpense(controller.expenses, expenseId);
          if (expense == null) {
            if (controller.loadError.value != null) {
              return _DetailsMessage(
                key: const Key('details.loadError'),
                title: 'Could not load this expense',
                actionLabel: 'Retry',
                onAction: () {
                  controller.loadExpenses();
                },
              );
            }
            return _DetailsMessage(
              key: const Key('details.notFound'),
              title: 'This expense could not be found.',
              actionLabel: 'Back to expenses',
              onAction: _returnHome,
            );
          }

          final category = _findCategory(
            categoriesController.categories,
            expense.categoryId,
          );
          final symbol = settingsController.currencySymbol.value;
          return _ExpenseDetailsContent(
            expense: expense,
            category: category,
            currencySymbol: symbol,
            error: controller.deleteError.value,
            onEdit: () =>
                Get.toNamed<void>(AppRoutes.editExpense, arguments: expense.id),
            onDelete: () => _deleteExpense(context, expense),
            onRetryDelete: () => _deleteExpense(context, expense),
          );
        }),
      ),
    );
  }

  Future<bool> _deleteExpense(BuildContext context, Expense expense) async {
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await controller.deleteExpense(expense.id);
    if (!deleted) {
      return false;
    }
    _returnHome();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Expense deleted. Your expense was deleted.'),
      ),
    );
    return true;
  }

  void _returnHome() {
    Get.until((route) => route.settings.name == AppRoutes.home);
  }
}

class _ExpenseDetailsContent extends StatefulWidget {
  const _ExpenseDetailsContent({
    required this.expense,
    required this.category,
    required this.currencySymbol,
    required this.error,
    required this.onEdit,
    required this.onDelete,
    required this.onRetryDelete,
  });

  final Expense expense;
  final Category? category;
  final String currencySymbol;
  final Object? error;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;
  final Future<bool> Function() onRetryDelete;

  @override
  State<_ExpenseDetailsContent> createState() => _ExpenseDetailsContentState();
}

class _ExpenseDetailsContentState extends State<_ExpenseDetailsContent> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = widget.expense.note?.trim();
    return ListView(
      key: const Key('details.content'),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        CircleAvatar(
          radius: 32,
          child: CategoryIcon(
            iconKey: widget.category?.iconKey ?? widget.expense.categoryId,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          CurrencyFormatter.format(
            widget.expense.amount,
            widget.currencySymbol,
          ),
          key: const Key('details.amount'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        _DetailRow(
          label: 'Category',
          value: widget.category?.name ?? 'Category unavailable',
        ),
        _DetailRow(
          label: 'Date',
          value: DateFormat.yMMMMd().format(widget.expense.date),
        ),
        if (note != null && note.isNotEmpty)
          _DetailRow(label: 'Note', value: note),
        const SizedBox(height: 28),
        FilledButton.icon(
          key: const Key('details.edit'),
          onPressed: _isDeleting ? null : widget.onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit expense'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('details.delete'),
          onPressed: _isDeleting ? null : _delete,
          icon: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: const Text('Delete expense'),
        ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: <Widget>[
                Text(
                  'Could not delete this expense. It is still saved; please retry.',
                  key: const Key('details.deleteError'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                TextButton(
                  onPressed: _isDeleting ? null : _retryDelete,
                  child: const Text('Retry deletion'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: Text(
          'Delete ${CurrencyFormatter.format(widget.expense.amount, widget.currencySymbol)}? This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('details.delete.confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runDeletion(widget.onDelete);
    }
  }

  Future<void> _retryDelete() async {
    await _runDeletion(widget.onRetryDelete);
  }

  Future<void> _runDeletion(Future<bool> Function() delete) async {
    setState(() => _isDeleting = true);
    try {
      await delete();
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _DetailsMessage extends StatelessWidget {
  const _DetailsMessage({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('details.returnHome'),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Expense? _findExpense(Iterable<Expense> expenses, String id) {
  for (final expense in expenses) {
    if (expense.id == id) {
      return expense;
    }
  }
  return null;
}

Category? _findCategory(Iterable<Category> categories, String id) {
  for (final category in categories) {
    if (category.id == id) {
      return category;
    }
  }
  return null;
}
