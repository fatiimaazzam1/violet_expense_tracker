import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:violet_expense_tracker/controllers/onboarding_controller.dart';
import 'package:violet_expense_tracker/controllers/settings_controller.dart';
import 'package:violet_expense_tracker/services/hive_service.dart';

import '../helpers/fake_hive_service.dart';

void main() {
  tearDown(Get.reset);

  test(
    'uses the approved Light and USD defaults and loads saved preferences',
    () async {
      final service = FakeHiveService();
      service.settings[HiveService.themeModeKey] = ThemeMode.dark.name;
      service.settings[HiveService.currencySymbolKey] = '€';
      final controller = SettingsController(service);

      expect(await controller.loadSettings(), isTrue);
      expect(controller.themeMode.value, ThemeMode.dark);
      expect(controller.currencySymbol.value, '€');

      final defaults = SettingsController(FakeHiveService());
      expect(defaults.themeMode.value, ThemeMode.light);
      expect(defaults.currencySymbol.value, r'$');
    },
  );

  test('persists currency before updating reactive state', () async {
    final service = FakeHiveService();
    final controller = SettingsController(service);

    expect(await controller.setCurrencySymbol('€'), isTrue);
    expect(controller.currencySymbol.value, '€');
    expect(service.settings[HiveService.currencySymbolKey], '€');
  });

  test('failed preference writes preserve the previous setting', () async {
    final service = FakeHiveService();
    final controller = SettingsController(service);
    service.saveSettingFailure = HiveError('Simulated settings write failure.');

    expect(await controller.setCurrencySymbol('£'), isFalse);
    expect(controller.currencySymbol.value, r'$');
    expect(controller.error.value, isA<HiveError>());
    expect(service.settings, isEmpty);
  });

  testWidgets('applies theme only after the preference is persisted', (
    tester,
  ) async {
    final service = FakeHiveService();
    final controller = SettingsController(service);
    Get.put<SettingsController>(controller);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    expect(await controller.setThemeMode(ThemeMode.dark), isTrue);
    await tester.pumpAndSettle();
    expect(service.settings[HiveService.themeModeKey], ThemeMode.dark.name);
    expect(controller.themeMode.value, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  test('onboarding completion reports storage failure and can retry', () async {
    final service = FakeHiveService();
    final controller = OnboardingController(service);
    service.saveSettingFailure = HiveError('Simulated settings write failure.');

    expect(await controller.completeOnboarding(), isFalse);
    expect(service.settings, isEmpty);
    expect(controller.error.value, isA<HiveError>());

    service.saveSettingFailure = null;
    expect(await controller.completeOnboarding(), isTrue);
    expect(service.settings[HiveService.onboardingCompletedKey], isTrue);
  });
}
