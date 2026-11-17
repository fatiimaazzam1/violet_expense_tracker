import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../services/hive_service.dart';
import 'expense_controller.dart';

class CategoryController extends GetxController {
  CategoryController(this._hiveService, this._expenseController);

  static const int maxNameLength = 30;
  static const Uuid _uuid = Uuid();

  final HiveService _hiveService;
  final ExpenseController _expenseController;

  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    unawaited(loadCategories());
  }

  Future<bool> loadCategories() async {
    isLoading.value = true;
    error.value = null;

    try {
      final loadedCategories = await _hiveService.getAllCategories();
      categories.assignAll(loadedCategories);
      return true;
    } on HiveError catch (failure) {
      return _recordError(failure);
    } on StateError catch (failure) {
      return _recordError(failure);
    } on Exception catch (failure) {
      return _recordError(failure);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addCategory({
    required String name,
    required String iconKey,
  }) async {
    error.value = null;
    final normalizedName = name.trim();
    final normalizedIconKey = iconKey.trim();
    if (!_validateNewCategory(normalizedName, normalizedIconKey)) {
      return false;
    }

    final category = Category(
      id: _uuid.v4(),
      name: normalizedName,
      iconKey: normalizedIconKey,
      isDefault: false,
    );
    try {
      await _hiveService.addCategory(category);
      categories.add(category);
      return true;
    } on HiveError catch (failure) {
      return _recordError(failure);
    } on StateError catch (failure) {
      return _recordError(failure);
    } on Exception catch (failure) {
      return _recordError(failure);
    }
  }

  Future<bool> deleteCategory(String id, {String? reassignToCategoryId}) async {
    error.value = null;
    final categoryIndex = categories.indexWhere(
      (category) => category.id == id,
    );
    if (categoryIndex == -1) {
      return _recordError(StateError('Category $id does not exist.'));
    }

    final category = categories[categoryIndex];
    if (_isDefaultCategory(category)) {
      return _recordError(StateError('Default categories cannot be deleted.'));
    }

    if (!await _expenseController.loadExpenses()) {
      return _recordError(
        _expenseController.error.value ??
            StateError('Could not load expenses before deleting the category.'),
      );
    }

    if (_expenseController.hasExpensesForCategory(id)) {
      if (reassignToCategoryId == null) {
        return _recordError(
          StateError('Reassign expenses before deleting category $id.'),
        );
      }
      if (reassignToCategoryId == id ||
          !categories.any((item) => item.id == reassignToCategoryId)) {
        return _recordError(
          ArgumentError.value(
            reassignToCategoryId,
            'reassignToCategoryId',
            'Choose another existing category.',
          ),
        );
      }

      final reassigned = await _expenseController.reassignExpenses(
        sourceCategoryId: id,
        destinationCategoryId: reassignToCategoryId,
      );
      if (!reassigned) {
        return _recordError(
          _expenseController.error.value ??
              StateError('Could not reassign the category expenses.'),
        );
      }
    }

    try {
      await _hiveService.deleteCategory(id);
      categories.removeAt(categoryIndex);
      return true;
    } on HiveError catch (failure) {
      return _recordError(failure);
    } on StateError catch (failure) {
      return _recordError(failure);
    } on Exception catch (failure) {
      return _recordError(failure);
    }
  }

  bool _validateNewCategory(String name, String iconKey) {
    if (name.isEmpty) {
      error.value = ArgumentError.value(
        name,
        'name',
        'A category name is required.',
      );
      return false;
    }
    if (name.length > maxNameLength) {
      error.value = ArgumentError.value(
        name,
        'name',
        'Category names must be $maxNameLength characters or fewer.',
      );
      return false;
    }
    if (iconKey.isEmpty) {
      error.value = ArgumentError.value(
        iconKey,
        'iconKey',
        'A category icon is required.',
      );
      return false;
    }
    if (categories.any(
      (category) => category.name.trim().toLowerCase() == name.toLowerCase(),
    )) {
      error.value = ArgumentError.value(
        name,
        'name',
        'Category names must be unique.',
      );
      return false;
    }
    return true;
  }

  bool _isDefaultCategory(Category category) {
    return category.isDefault ||
        HiveService.defaultCategories.any(
          (defaultCategory) => defaultCategory.id == category.id,
        );
  }

  bool _recordError(Object failure) {
    error.value = failure;
    return false;
  }
}
