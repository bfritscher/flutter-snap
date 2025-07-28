// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get take => 'Take';

  @override
  String get account => 'Account';

  @override
  String get send => 'Send';

  @override
  String get title => 'Title';

  @override
  String get increment => 'Increment Counter';

  @override
  String nItems(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pushed $countString times',
      one: 'Pushed once',
      zero: 'Never pushed',
    );
    return '$_temp0';
  }

  @override
  String get language => 'Language';

  @override
  String get settings => 'Settings';

  @override
  String selectLocale(String choice) {
    String _temp0 = intl.Intl.selectLogic(
      choice,
      {
        'fr': 'Français',
        'en': 'English',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'Ok';

  @override
  String get common => 'Common';

  @override
  String get theme => 'Theme';

  @override
  String selectTheme(String choice) {
    String _temp0 = intl.Intl.selectLogic(
      choice,
      {
        'light': 'Light',
        'dark': 'Dark',
        'system': 'System',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get selectValue => 'Select the value you want';
}
