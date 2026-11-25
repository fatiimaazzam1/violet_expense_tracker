import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../services/hive_service.dart';

class SettingsController extends GetxController {
  SettingsController(this._hiveService);

  static const Map<String, String> currencies = <String, String>{
    'USD': r'$',
    'EUR': '€',
    'LBP': 'ل.ل',
    'GBP': '£',
  };

  final HiveService _hiveService;

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  final RxString currencySymbol = r'$'.obs;
  final RxBool isSaving = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  Future<bool> loadSettings() async {
    error.value = null;
    try {
      final storedTheme = await _hiveService.getSetting(
        HiveService.themeModeKey,
      );
      final storedCurrency = await _hiveService.getSetting(
        HiveService.currencySymbolKey,
      );

      if (storedTheme != null) {
        if (storedTheme == ThemeMode.light.name) {
          themeMode.value = ThemeMode.light;
        } else if (storedTheme == ThemeMode.dark.name) {
          themeMode.value = ThemeMode.dark;
        } else {
          throw FormatException('Unsupported theme mode: $storedTheme.');
        }
      }

      if (storedCurrency != null) {
        if (storedCurrency is! String ||
            !currencies.values.contains(storedCurrency)) {
          throw FormatException(
            'Unsupported currency symbol: $storedCurrency.',
          );
        }
        currencySymbol.value = storedCurrency;
      }
      return true;
    } on HiveError catch (failure) {
      return _recordError(failure);
    } on StateError catch (failure) {
      return _recordError(failure);
    } on FormatException catch (failure) {
      return _recordError(failure);
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) async {
    if (mode != ThemeMode.light && mode != ThemeMode.dark) {
      return _recordError(
        ArgumentError.value(mode, 'mode', 'Choose light or dark mode.'),
      );
    }
    if (mode == themeMode.value) {
      return true;
    }

    isSaving.value = true;
    error.value = null;
    try {
      await _hiveService.saveSetting(HiveService.themeModeKey, mode.name);
      themeMode.value = mode;
      Get.changeThemeMode(mode);
      return true;
    } on HiveError catch (failure) {
      return _recordError(failure);
    } on StateError catch (failure) {
      return _recordError(failure);
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> setCurrencySymbol(String symbol) async {
    if (!currencies.values.contains(symbol)) {
      return _recordError(
        ArgumentError.value(symbol, 'symbol', 'Choose a supported currency.'),
      );
    }
    if (symbol == currencySymbol.value) {
      return true;
    }

    isSaving.value = true;
    error.value = null;
    try {
      await _hiveService.saveSetting(HiveService.currencySymbolKey, symbol);
      currencySymbol.value = symbol;
      return true;
    } on HiveError catch (failure) {
      return _recordError(failure);
    } on StateError catch (failure) {
      return _recordError(failure);
    } finally {
      isSaving.value = false;
    }
  }

  bool _recordError(Object failure) {
    error.value = failure;
    return false;
  }
}
