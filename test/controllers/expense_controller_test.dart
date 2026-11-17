import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/controllers/expense_controller.dart';
import 'package:violet_expense_tracker/models/expense.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

void main() {
  late _FakeHiveService hiveService;

  setUp(() {
    Get.reset();
    hiveService = _FakeHiveService();
  });

  tearDown(() {
    Get.reset();
  });

  test('loads and sorts expenses when the controller initializes', () async {
    final olderExpense = _expense(id: 'older', date: DateTime(2026, 1, 1));
    final newerExpense = _expense(id: 'newer', date: DateTime(2026, 2, 1));
    hiveService.storedExpenses.addAll(<Expense>[olderExpense, newerExpense]);

    final controller = await _createController(hiveService);

    expect(hiveService.readCount, 1);
    expect(controller.expenses.map((expense) => expense.id), <String>[
      'newer',
      'older',
    ]);
  });

  test('adds an expense after persistence succeeds', () async {
    final controller = await _createController(hiveService);

    final succeeded = await controller.addExpense(
      amount: 18.5,
      categoryId: 'food',
      date: DateTime(2026, 11, 16),
      note: 'Lunch',
    );

    expect(succeeded, isTrue);
    expect(controller.expenses, hasLength(1));
    expect(controller.expenses.single.id, isNotEmpty);
    expect(controller.expenses.single.amount, 18.5);
    expect(hiveService.storedExpenses.single.id, controller.expenses.single.id);
    expect(controller.error.value, isNull);
  });

  test(
    'edits an expense without changing its ID or adding a duplicate',
    () async {
      final existing = _expense(id: 'expense-1');
      hiveService.storedExpenses.add(existing);
      final controller = await _createController(hiveService);

      final succeeded = await controller.editExpense(
        id: existing.id,
        amount: 42,
        categoryId: 'transport',
        date: DateTime(2026, 11, 16),
        note: 'Updated',
      );

      expect(succeeded, isTrue);
      expect(controller.expenses, hasLength(1));
      expect(controller.expenses.single.id, existing.id);
      expect(controller.expenses.single.amount, 42);
      expect(controller.expenses.single.categoryId, 'transport');
      expect(hiveService.storedExpenses, hasLength(1));
      expect(hiveService.storedExpenses.single.id, existing.id);
    },
  );

  test('deletes an expense only after persistence succeeds', () async {
    final existing = _expense(id: 'expense-1');
    hiveService.storedExpenses.add(existing);
    final controller = await _createController(hiveService);

    final succeeded = await controller.deleteExpense(existing.id);

    expect(succeeded, isTrue);
    expect(controller.expenses, isEmpty);
    expect(hiveService.storedExpenses, isEmpty);
  });

  test('rejects zero, negative, and non-finite amounts', () async {
    final controller = await _createController(hiveService);

    for (final amount in <double>[0, -1, double.infinity, double.nan]) {
      final succeeded = await controller.addExpense(
        amount: amount,
        categoryId: 'food',
        date: DateTime(2026, 11, 16),
      );

      expect(succeeded, isFalse);
      expect(controller.error.value, isA<ArgumentError>());
    }

    expect(controller.expenses, isEmpty);
    expect(hiveService.storedExpenses, isEmpty);
  });

  test('rejects an empty category ID', () async {
    final controller = await _createController(hiveService);

    final succeeded = await controller.addExpense(
      amount: 10,
      categoryId: '  ',
      date: DateTime(2026, 11, 16),
    );

    expect(succeeded, isFalse);
    expect(controller.error.value, isA<ArgumentError>());
    expect(controller.expenses, isEmpty);
    expect(hiveService.storedExpenses, isEmpty);
  });

  test('rejects a note longer than 200 characters', () async {
    final controller = await _createController(hiveService);

    final boundarySaveSucceeded = await controller.addExpense(
      amount: 10,
      categoryId: 'food',
      date: DateTime(2026, 11, 16),
      note: 'x' * 200,
    );
    expect(boundarySaveSucceeded, isTrue);
    expect(controller.expenses.single.note, hasLength(200));

    final succeeded = await controller.addExpense(
      amount: 10,
      categoryId: 'food',
      date: DateTime(2026, 11, 16),
      note: 'x' * 201,
    );

    expect(succeeded, isFalse);
    expect(controller.error.value, isA<ArgumentError>());
    expect(controller.expenses, hasLength(1));
    expect(hiveService.storedExpenses, hasLength(1));
  });

  test('a failed storage write does not update observable expenses', () async {
    final existing = _expense(id: 'existing-expense');
    hiveService.storedExpenses.add(existing);
    final controller = await _createController(hiveService);
    hiveService.addFailure = HiveError('Simulated storage failure.');

    final succeeded = await controller.addExpense(
      amount: 10,
      categoryId: 'food',
      date: DateTime(2026, 11, 16),
    );

    expect(succeeded, isFalse);
    expect(controller.expenses, <Expense>[existing]);
    expect(hiveService.storedExpenses, <Expense>[existing]);
    expect(controller.error.value, isA<HiveError>());
  });

  test('a failed deletion preserves the expense in observable state', () async {
    final existing = _expense(id: 'expense-1');
    hiveService.storedExpenses.add(existing);
    final controller = await _createController(hiveService);
    hiveService.deleteFailure = HiveError('Simulated storage failure.');

    final succeeded = await controller.deleteExpense(existing.id);

    expect(succeeded, isFalse);
    expect(controller.expenses, <Expense>[existing]);
    expect(hiveService.storedExpenses, <Expense>[existing]);
    expect(controller.error.value, isA<HiveError>());
  });
}

Future<ExpenseController> _createController(
  _FakeHiveService hiveService,
) async {
  Get.lazyPut<ExpenseController>(() => ExpenseController(hiveService));
  final controller = Get.find<ExpenseController>();

  while (controller.isLoading.value) {
    await Future<void>.delayed(Duration.zero);
  }

  return controller;
}

Expense _expense({required String id, DateTime? date}) {
  return Expense(
    id: id,
    amount: 10,
    categoryId: 'food',
    date: date ?? DateTime(2026, 1, 1),
  );
}

class _FakeHiveService extends HiveService {
  final List<Expense> storedExpenses = <Expense>[];
  int readCount = 0;
  Object? addFailure;
  Object? deleteFailure;

  @override
  Future<List<Expense>> getAllExpenses() async {
    readCount++;
    return List<Expense>.of(storedExpenses);
  }

  @override
  Future<void> addExpense(Expense expense) async {
    final failure = addFailure;
    if (failure != null) {
      throw failure;
    }
    if (storedExpenses.any((stored) => stored.id == expense.id)) {
      throw StateError('Expense ${expense.id} already exists.');
    }
    storedExpenses.add(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final index = storedExpenses.indexWhere(
      (stored) => stored.id == expense.id,
    );
    if (index == -1) {
      throw StateError('Expense ${expense.id} does not exist.');
    }
    storedExpenses[index] = expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    final failure = deleteFailure;
    if (failure != null) {
      throw failure;
    }
    final index = storedExpenses.indexWhere((stored) => stored.id == id);
    if (index == -1) {
      throw StateError('Expense $id does not exist.');
    }
    storedExpenses.removeAt(index);
  }
}
