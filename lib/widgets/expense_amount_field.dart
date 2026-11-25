import 'package:flutter/material.dart';

class ExpenseAmountField extends StatelessWidget {
  const ExpenseAmountField({
    required this.textController,
    required this.currencySymbol,
    required this.errorText,
    required this.onChanged,
    super.key,
  });

  final TextEditingController textController;
  final String currencySymbol;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('expense.amount'),
      controller: textController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixText: '$currencySymbol ',
        prefixIcon: const Icon(Icons.payments_outlined),
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
