import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/app_enums.dart';
import '../repositories/preferences_repository.dart';

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider({
    required PreferencesRepository repository,
  }) : _repository = repository;

  PreferencesRepository _repository;
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  Locale get locale => _localeForLanguage(_language);

  void updateDependencies(PreferencesRepository repository) {
    _repository = repository;
  }

  Future<void> loadLanguage() async {
    final savedLanguage = await _repository.fetchAppLanguage();
    _language = savedLanguage ?? _deviceLanguage();
    _applyLocale();
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }
    _language = language;
    _applyLocale();
    await _repository.saveAppLanguage(language);
    notifyListeners();
  }

  void _applyLocale() {
    Intl.defaultLocale = locale.toLanguageTag();
  }

  AppLanguage _deviceLanguage() {
    final code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    switch (code) {
      case 'ru':
        return AppLanguage.russian;
      case 'kk':
        return AppLanguage.kazakh;
      default:
        return AppLanguage.english;
    }
  }

  Locale _localeForLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.russian:
        return const Locale('ru');
      case AppLanguage.kazakh:
        return const Locale('kk');
    }
  }
}
