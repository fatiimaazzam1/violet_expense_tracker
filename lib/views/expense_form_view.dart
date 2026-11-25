import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/expense_form_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/expense_amount_field.dart';
import '../widgets/expense_category_selector.dart';
import '../widgets/expense_date_selector.dart';
import '../widgets/expense_form_actions.dart';
import '../widgets/expense_note_field.dart';
import '../routes/app_routes.dart';

class ExpenseFormView extends GetView<ExpenseFormController> {
  const ExpenseFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return _ExpenseFormBody(controller: controller);
  }
}

class _ExpenseFormBody extends StatefulWidget {
  const _ExpenseFormBody({required this.controller});

  final ExpenseFormController controller;

  @override
  State<_ExpenseFormBody> createState() => _ExpenseFormBodyState();
}

class _ExpenseFormBodyState extends State<_ExpenseFormBody> {
  late final TextEditingController _amountTextController;
  late final TextEditingController _noteTextController;
  late final Worker _amountWorker;
  late final Worker _noteWorker;
  bool _isConfirmingFutureDate = false;

  ExpenseFormController get _form => widget.controller;

  @override
  void initState() {
    super.initState();
    _amountTextController = TextEditingController(text: _form.amountText.value);
    _noteTextController = TextEditingController(text: _form.noteText.value);
    _amountWorker = ever<String>(
      _form.amountText,
      (value) => _syncTextController(_amountTextController, value),
    );
    _noteWorker = ever<String>(
      _form.noteText,
      (value) => _syncTextController(_noteTextController, value),
    );
  }

  @override
  void dispose() {
    _amountWorker.dispose();
    _noteWorker.dispose();
    _amountTextController.dispose();
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = theme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: theme.brightness,
      ),
    );

    return Theme(
      data: formTheme,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Go back',
              onPressed: Get.back<void>,
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(_form.isEditMode ? 'Edit Expense' : 'Add Expense'),
          ),
          body: SafeArea(
            child: Obx(() {
              if (_form.isLoading.value) {
                return const _ExpenseFormState(
                  key: Key('expense.loading'),
                  icon: CircularProgressIndicator(),
                  message: 'Loading expense…',
                );
              }

              if (_form.isNotFound.value) {
                return _ExpenseFormState(
                  key: const Key('expense.notFound'),
                  icon: const Icon(Icons.search_off_outlined, size: 44),
                  message: 'This expense could not be found.',
                  actionLabel: 'Back to expenses',
                  onAction: Get.back<void>,
                );
              }

              if (_isEditLoadFailure) {
                return _ExpenseFormState(
                  key: const Key('expense.loadError'),
                  icon: const Icon(Icons.error_outline, size: 44),
                  message: 'Could not load this expense. Please try again.',
                  actionLabel: 'Retry',
                  onAction: () {
                    _form.loadExpense();
                  },
                );
              }

              return _buildForm(context);
            }),
          ),
        ),
      ),
    );
  }

  bool get _isEditLoadFailure =>
      _form.isEditMode &&
      _form.error.value != null &&
      _form.amountText.value.isEmpty &&
      _form.selectedCategoryId.value == null;

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final categoryController = Get.find<CategoryController>();
    final settingsController = Get.find<SettingsController>();
    return ListView(
      key: const Key('expense.form'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: <Widget>[
        Text(
          _form.isEditMode
              ? 'Update the details of this expense.'
              : 'Record a new expense.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Obx(
          () => ExpenseAmountField(
            textController: _amountTextController,
            currencySymbol: settingsController.currencySymbol.value,
            errorText: _form.amountError.value,
            onChanged: (value) => _form.amountText.value = value,
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => ExpenseCategorySelector(
            categories: categoryController.categories.toList(),
            selectedCategoryId: _form.selectedCategoryId.value,
            errorText: _form.categoryError.value,
            onSelected: (value) => _form.selectedCategoryId.value = value,
          ),
        ),
        const SizedBox(height: 20),
        Obx(
          () => ExpenseDateSelector(
            date: _form.expenseDate.value,
            onPressed: _selectDate,
          ),
        ),
        const SizedBox(height: 20),
        Obx(
          () => ExpenseNoteField(
            textController: _noteTextController,
            errorText: _form.noteError.value,
            maxLength: ExpenseFormController.maxNoteLength,
            onChanged: (value) => _form.noteText.value = value,
          ),
        ),
        Obx(() => _buildErrorMessage(theme)),
        const SizedBox(height: 12),
        Obx(
          () => ExpenseFormActions(
            isSaving: _form.isSaving.value || _isConfirmingFutureDate,
            saveLabel: _form.isEditMode ? 'Save changes' : 'Save expense',
            onCancel: Get.back<void>,
            onSave: _submit,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    final hasFieldError =
        _form.amountError.value != null ||
        _form.categoryError.value != null ||
        _form.noteError.value != null;
    final hasOperationError = _form.error.value != null && !hasFieldError;
    if (!hasOperationError) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('expense.saveError'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Could not save the expense. Your entries are still here; please retry.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _form.expenseDate.value,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Select expense date',
    );
    if (selectedDate != null) {
      _form.expenseDate.value = selectedDate;
    }
  }

  Future<void> _submit() async {
    if (_isConfirmingFutureDate || _form.isSaving.value) {
      return;
    }

    final result = await _form.submit();
    if (!mounted) {
      return;
    }

    if (result == ExpenseFormSubmitResult.confirmationRequired) {
      await _confirmFutureDateAndSave();
      return;
    }

    _finishSubmission(result);
  }

  Future<void> _confirmFutureDateAndSave() async {
    setState(() => _isConfirmingFutureDate = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Future date'),
          content: const Text('This date is in the future. Save anyway?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save anyway'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }

      final result = await _form.submit(confirmFutureDate: true);
      if (mounted) {
        _finishSubmission(result);
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirmingFutureDate = false);
      }
    }
  }

  void _finishSubmission(ExpenseFormSubmitResult result) {
    if (result != ExpenseFormSubmitResult.success) {
      return;
    }

    final successTitle = _form.isEditMode ? 'Expense updated' : 'Expense added';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successTitle)));
    Navigator.of(
      context,
    ).popUntil((route) => route.settings.name == AppRoutes.home);
  }

  void _syncTextController(TextEditingController textController, String value) {
    if (textController.text == value) {
      return;
    }

    textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class _ExpenseFormState extends StatelessWidget {
  const _ExpenseFormState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final Widget icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
