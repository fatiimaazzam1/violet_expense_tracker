import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/category_controller.dart';
import 'category_icon.dart';

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  static const Map<String, String> _iconLabels = <String, String>{
    'food': 'Dining',
    'transport': 'Transport',
    'bills': 'Utilities',
    'shopping': 'Shopping',
    'coffee': 'Coffee',
    'wallet': 'Wallet',
    'tag': 'Tag',
    'card': 'Card',
  };

  final TextEditingController _nameController = TextEditingController();
  String _selectedIconKey = 'tag';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    return AlertDialog(
      title: const Text('Add category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              key: const Key('category.name'),
              controller: _nameController,
              maxLength: CategoryController.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Category name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose an icon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconLabels.entries.map((entry) {
                return ChoiceChip(
                  key: Key('category.icon.${entry.key}'),
                  avatar: CategoryIcon(iconKey: entry.key),
                  label: Text(entry.value),
                  selected: _selectedIconKey == entry.key,
                  onSelected: _isSaving
                      ? null
                      : (_) => setState(() => _selectedIconKey = entry.key),
                );
              }).toList(),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  key: const Key('category.form.error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('category.form.save'),
          onPressed: _isSaving ? null : () => _save(categoryController),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save category'),
        ),
      ],
    );
  }

  Future<void> _save(CategoryController controller) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final saved = await controller.addCategory(
      name: _nameController.text,
      iconKey: _selectedIconKey,
    );
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = controller.error.value.toString();
        _isSaving = false;
      });
    }
  }
}
