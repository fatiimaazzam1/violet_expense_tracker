import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? note;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
  });
}
