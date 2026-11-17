import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseDateSelector extends StatelessWidget {
  const ExpenseDateSelector({
    required this.date,
    required this.onPressed,
    super.key,
  });

  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('expense.date'),
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text('Date  ${DateFormat('yyyy-MM-dd').format(date)}'),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(54),
      ),
    );
  }
}
