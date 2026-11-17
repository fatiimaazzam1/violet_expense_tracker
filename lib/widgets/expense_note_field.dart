import 'package:flutter/material.dart';

class ExpenseNoteField extends StatelessWidget {
  const ExpenseNoteField({
    required this.textController,
    required this.errorText,
    required this.onChanged,
    required this.maxLength,
    super.key,
  });

  final TextEditingController textController;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('expense.note'),
      controller: textController,
      maxLength: maxLength,
      minLines: 2,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Note (optional)',
        hintText: 'Add a note',
        errorText: errorText,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
