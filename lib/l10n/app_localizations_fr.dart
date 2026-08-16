// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get take => 'Prendre';

  @override
  String get account => 'Compte';

  @override
  String get send => 'Envoyer';

  @override
  String get title => 'Titre';

  @override
  String get increment => 'Incrémenter Compteur';

  @override
  String nItems(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vous avez appuyé $countString fois',
      one: 'Vous avez appuyé une fois',
      zero: 'Jamais appyuez',
    );
    return '$_temp0';
  }

  @override
  String get language => 'Langue';

  @override
  String get settings => 'Paramètres';

  @override
  String selectLocale(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'fr': 'Français',
      'en': 'English',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'Ok';

  @override
  String get common => 'Commun';

  @override
  String get theme => 'Thème';

  @override
  String selectTheme(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'light': 'Clair',
      'dark': 'Sombre',
      'system': 'Système',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get selectValue => 'Sélectionnez la valeur que vous souhaitez';
}
