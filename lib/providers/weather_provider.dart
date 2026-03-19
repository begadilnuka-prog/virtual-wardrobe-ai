import 'package:flutter/foundation.dart';

import '../core/app_enums.dart';
import '../models/weather_snapshot.dart';
import '../repositories/preferences_repository.dart';
import '../services/weather_service.dart';
import 'auth_provider.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherProvider({
    required AuthProvider authProvider,
    required PreferencesRepository repository,
  })  : _authProvider = authProvider,
        _repository = repository,
        _weatherService = WeatherService();

  AuthProvider _authProvider;
  PreferencesRepository _repository;
  final WeatherService _weatherService;

  WeatherSnapshot? snapshot;
  bool isLoading = false;

  void updateDependencies(
      AuthProvider authProvider, PreferencesRepository repository) {
    final previousUserId = _authProvider.currentUser?.id;
    _authProvider = authProvider;
    _repository = repository;
    if (previousUserId != _authProvider.currentUser?.id) {
      loadWeather();
    }
  }

  Future<void> loadWeather({String city = ''}) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      snapshot = null;
      notifyListeners();
      return;
    }

    if (city.trim().isEmpty) {
      // Don't generate mock weather without a user-provided location.
      snapshot = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    final stored = await _repository.fetchWeather(user.id);
    snapshot = _weatherService.shouldRefreshStored(stored, city: city)
        ? _weatherService.refreshForCity(city)
        : stored;
    await _repository.saveWeather(userId: user.id, snapshot: snapshot!);
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh({String city = ''}) async {
    final user = _authProvider.currentUser;
    if (user == null || city.trim().isEmpty) {
      return;
    }

    isLoading = true;
    notifyListeners();
    snapshot = _weatherService.refreshForCity(city);
    await _repository.saveWeather(userId: user.id, snapshot: snapshot!);
    isLoading = false;
    notifyListeners();
  }

  Future<void> selectCondition(WeatherCondition condition,
      {String city = ''}) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    snapshot = _weatherService.buildSnapshot(condition: condition, city: city);
    await _repository.saveWeather(userId: user.id, snapshot: snapshot!);
    notifyListeners();
  }
}
