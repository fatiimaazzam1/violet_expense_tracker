import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/category_controller.dart';
import '../controllers/expense_controller.dart';
import '../models/category.dart';

class CategoryReassignmentDialog extends StatefulWidget {
  const CategoryReassignmentDialog({
    required this.category,
    required this.expenseCount,
    required this.destinationCategories,
    super.key,
  });

  final Category category;
  final int expenseCount;
  final List<Category> destinationCategories;

  @override
  State<CategoryReassignmentDialog> createState() =>
      _CategoryReassignmentDialogState();
}

class _CategoryReassignmentDialogState
    extends State<CategoryReassignmentDialog> {
  String? _destinationId;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reassign expenses first'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${widget.expenseCount} ${widget.expenseCount == 1 ? 'expense uses' : 'expenses use'} ${widget.category.name}. '
            'They will be kept and reassigned before this category is deleted.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('category.reassign.destination'),
            initialValue: _destinationId,
            decoration: const InputDecoration(
              labelText: 'Move expenses to',
              border: OutlineInputBorder(),
            ),
            items: widget.destinationCategories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) => setState(() => _destinationId = value),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage!,
                key: const Key('category.reassign.error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('category.reassign.confirm'),
          onPressed: _isSaving || _destinationId == null ? null : _reassign,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reassign and delete'),
        ),
      ],
    );
  }

  Future<void> _reassign() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final categoryController = Get.find<CategoryController>();
    final expenseController = Get.find<ExpenseController>();
    final succeeded = await categoryController.deleteCategory(
      widget.category.id,
      reassignToCategoryId: _destinationId,
    );
    if (!mounted) {
      return;
    }
    if (succeeded) {
      Navigator.pop(context, true);
      return;
    }

    final error = categoryController.error.value;
    final remaining = expenseController.expenseCountForCategory(
      widget.category.id,
    );
    setState(() {
      _errorMessage = remaining < widget.expenseCount
          ? 'Some expenses were reassigned. The category is still available; retry to move the remaining $remaining.'
          : 'Could not reassign the expenses. They are unchanged; please retry.';
      if (error == null) {
        _errorMessage = 'Could not reassign the expenses. Please retry.';
      }
      _isSaving = false;
    });
  }
}
