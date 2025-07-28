import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import 'l10n/app_localizations.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        leading: BackButton(
            onPressed: () {
              if (kIsWeb) {
                context.go('/profile');
              } else {
                context.pop();
              }
            },
            color: Theme.of(context).colorScheme.onPrimary),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
              title: Text(AppLocalizations.of(context)!.common),
              tiles: [
                SettingsTile(
                  leading: const Icon(Icons.language),
                  title: Text(AppLocalizations.of(context)!.language),
                  value: Text(AppLocalizations.of(context)!
                      .selectLocale(settings.locale.languageCode)),
                  onPressed: (context) async {
                    final locale = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsListPickerScreen(
                                    title:
                                        AppLocalizations.of(context)!.language,
                                    options: {
                                      for (final item in ['fr', 'en'])
                                        item: AppLocalizations.of(context)!
                                            .selectLocale(item)
                                    })));
                    if (locale != null) {
                      settings.locale = Locale(locale);
                    }
                  },
                ),
                SettingsTile(
                  leading: const Icon(Icons.dark_mode),
                  title: Text(AppLocalizations.of(context)!.theme),
                  description: Text(AppLocalizations.of(context)!
                      .selectTheme(settings.themeMode.name)),
                  onPressed: (context) async {
                    final themeMode = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsListPickerScreen(
                                    title: AppLocalizations.of(context)!.theme,
                                    options: {
                                      for (final item in ThemeMode.values)
                                        item.name: AppLocalizations.of(context)!
                                            .selectTheme(item.name)
                                    })));
                    if (themeMode != null) {
                      settings.themeMode = themeModeFromString(themeMode);
                    }
                  },
                ),
              ]),
        ],
      ),
    );
  }
}

class SettingsListPickerScreen extends StatelessWidget {
  const SettingsListPickerScreen({
    super.key,
    required this.title,
    required this.options,
  });

  final String title;
  final Map<String, String> options;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.selectValue),
            tiles: options.keys.map((item) {
              return SettingsTile(
                title: Text(options[item]!),
                onPressed: (_) {
                  Navigator.of(context).pop(item);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
