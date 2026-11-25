import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final selectedCurrency = controller.currencySymbol.value;
      final selectedCurrencyCode = SettingsController.currencies.entries
          .firstWhere((entry) => entry.value == selectedCurrency)
          .key;

      return ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'PREFERENCES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Text('Settings', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          Text('Appearance', style: theme.textTheme.titleMedium),
          RadioGroup<ThemeMode>(
            groupValue: controller.themeMode.value,
            onChanged: (mode) {
              if (!controller.isSaving.value) {
                _changeTheme(context, mode);
              }
            },
            child: const Column(
              children: <Widget>[
                RadioListTile<ThemeMode>(
                  key: Key('settings.theme.light'),
                  title: Text('Light mode'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  key: Key('settings.theme.dark'),
                  title: Text('Dark mode'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text('Currency', style: theme.textTheme.titleMedium),
          RadioGroup<String>(
            groupValue: selectedCurrencyCode,
            onChanged: (code) {
              if (!controller.isSaving.value && code != null) {
                _changeCurrency(context, SettingsController.currencies[code]!);
              }
            },
            child: Column(
              children: SettingsController.currencies.entries
                  .map(
                    (entry) => RadioListTile<String>(
                      key: Key('settings.currency.${entry.key}'),
                      title: Text('${entry.key} (${entry.value})'),
                      value: entry.key,
                    ),
                  )
                  .toList(),
            ),
          ),
          Text(
            'Currency changes display formatting only; expense amounts are not converted.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Private by design'),
              subtitle: const Text(
                'Your expenses are stored on this device and work offline.',
              ),
            ),
          ),
          if (controller.error.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Could not save this preference. Your previous selection is still active; please retry.',
                key: const Key('settings.saveError'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (controller.isSaving.value)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(key: Key('settings.saving')),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _changeTheme(BuildContext context, ThemeMode? mode) async {
    if (mode == null) {
      return;
    }
    final saved = await controller.setThemeMode(mode);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${mode == ThemeMode.dark ? 'Dark' : 'Light'} mode is active.',
          ),
        ),
      );
    }
  }

  Future<void> _changeCurrency(BuildContext context, String symbol) async {
    final saved = await controller.setCurrencySymbol(symbol);
    if (saved && context.mounted) {
      final code = SettingsController.currencies.entries
          .firstWhere((entry) => entry.value == symbol)
          .key;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Currency display changed to $code.')),
      );
    }
  }
}
