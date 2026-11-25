import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/category_controller.dart';
import '../controllers/expense_controller.dart';
import '../models/category.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_icon.dart';
import '../widgets/category_reassignment_dialog.dart';

class CategoriesView extends GetView<CategoryController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value && controller.categories.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(key: Key('categories.loading')),
        );
      }
      if (controller.error.value != null && controller.categories.isEmpty) {
        return _CategoriesMessage(
          key: const Key('categories.loadError'),
          message: 'Could not load categories.',
          actionLabel: 'Retry',
          onAction: controller.loadCategories,
        );
      }

      final defaults = controller.categories
          .where((category) => category.isDefault)
          .toList();
      final custom = controller.categories
          .where((category) => !category.isDefault)
          .toList();

      return ListView(
        key: const Key('categories.list'),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ORGANIZE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text('Categories', style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
              IconButton(
                key: const Key('categories.add'),
                tooltip: 'Add category',
                onPressed: () => _addCategory(context),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Organize your expenses with categories.'),
          const SizedBox(height: 24),
          Text('Default', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final category in defaults)
            _CategoryTile(category: category, protected: true),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Custom', style: theme.textTheme.titleMedium),
              ),
              TextButton.icon(
                key: const Key('categories.addCustom'),
                onPressed: () => _addCategory(context),
                icon: const Icon(Icons.add),
                label: const Text('Add category'),
              ),
            ],
          ),
          if (custom.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Your custom categories will appear here.'),
            )
          else
            for (final category in custom)
              _CategoryTile(
                key: Key('categories.custom.${category.id}'),
                category: category,
                expenseCount: Get.find<ExpenseController>()
                    .expenseCountForCategory(category.id),
                onDelete: () => _deleteCategory(context, category),
              ),
        ],
      );
    });
  }

  Future<void> _addCategory(BuildContext context) async {
    final saved = await Get.dialog<bool>(const CategoryFormDialog());
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added. Your new category is ready to use.'),
        ),
      );
    }
  }

  Future<void> _deleteCategory(BuildContext context, Category category) async {
    final expenses = Get.find<ExpenseController>();
    final count = expenses.expenseCountForCategory(category.id);
    if (count > 0) {
      final destinations = controller.categories
          .where((item) => item.id != category.id)
          .toList();
      final deleted = await showDialog<bool>(
        context: context,
        builder: (_) => CategoryReassignmentDialog(
          category: category,
          expenseCount: count,
          destinationCategories: destinations,
        ),
      );
      if (deleted == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted. Expenses were reassigned safely.'),
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete ${category.name}? This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('categories.delete.confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final deleted = await controller.deleteCategory(category.id);
    if (!context.mounted) {
      return;
    }
    if (deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category deleted. ${category.name} was removed.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete category: ${controller.error.value}'),
        ),
      );
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    this.protected = false,
    this.expenseCount = 0,
    this.onDelete,
    super.key,
  });

  final Category category;
  final bool protected;
  final int expenseCount;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: CategoryIcon(iconKey: category.iconKey)),
        title: Text(category.name),
        subtitle: Text(
          protected
              ? 'Built in · Protected'
              : '$expenseCount ${expenseCount == 1 ? 'expense' : 'expenses'}',
        ),
        trailing: protected
            ? const Icon(Icons.lock_outline)
            : IconButton(
                key: Key('categories.delete.${category.id}'),
                tooltip: 'Delete ${category.name}',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
      ),
    );
  }
}

class _CategoriesMessage extends StatelessWidget {
  const _CategoriesMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final Future<bool> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
