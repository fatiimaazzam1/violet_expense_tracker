import 'package:flutter/material.dart';

import '../models/category.dart';
import 'category_icon.dart';

const List<Category> defaultExpenseCategories = <Category>[
  Category(id: 'food', name: 'Food', iconKey: 'food', isDefault: true),
  Category(
    id: 'transport',
    name: 'Transport',
    iconKey: 'transport',
    isDefault: true,
  ),
  Category(id: 'bills', name: 'Bills', iconKey: 'bills', isDefault: true),
  Category(
    id: 'shopping',
    name: 'Shopping',
    iconKey: 'shopping',
    isDefault: true,
  ),
];

class ExpenseCategorySelector extends StatelessWidget {
  const ExpenseCategorySelector({
    required this.categories,
    required this.selectedCategoryId,
    required this.errorText,
    required this.onSelected,
    super.key,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final String? errorText;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Category', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            return ChoiceChip(
              key: Key('expense.category.${category.id}'),
              avatar: CategoryIcon(iconKey: category.iconKey),
              label: Text(category.name),
              selected: selectedCategoryId == category.id,
              selectedColor: theme.colorScheme.primaryContainer,
              onSelected: (_) => onSelected(category.id),
            );
          }).toList(),
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            errorText!,
            key: const Key('expense.category.error'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
