import 'package:flutter/material.dart';

class ExpenseFormActions extends StatelessWidget {
  const ExpenseFormActions({
    required this.isSaving,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  final bool isSaving;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            key: const Key('expense.cancel'),
            onPressed: isSaving ? null : onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const Key('expense.save'),
            onPressed: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(saveLabel),
          ),
        ),
      ],
    );
  }
}
