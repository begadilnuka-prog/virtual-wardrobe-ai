import 'package:flutter/material.dart';

import '../core/app_enums.dart';
import 'app_en.dart';
import 'app_kk.dart';
import 'app_ru.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('kk'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final instance =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(instance != null, 'AppLocalizations not found in context.');
    return instance!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': appEn,
    'ru': appRu,
    'kk': appKk,
  };

  String get code => locale.languageCode;

  String t(String key, {Map<String, String> args = const {}}) {
    final catalog = _localizedValues[code] ?? appEn;
    var value = catalog[key] ?? appEn[key] ?? key;
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  String languageLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return t('language_english');
      case AppLanguage.russian:
        return t('language_russian');
      case AppLanguage.kazakh:
        return t('language_kazakh');
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
