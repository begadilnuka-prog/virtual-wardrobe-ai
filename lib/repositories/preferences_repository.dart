import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_enums.dart';
import '../models/chat_message.dart';
import '../models/subscription_state.dart';
import '../models/weather_snapshot.dart';

class PreferencesRepository {
  static const _onboardingSeenKey = 'onboarding_seen';

  Future<SubscriptionState> fetchSubscriptionState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('subscription_$userId');
    if (raw == null) {
      return SubscriptionState(
        userId: userId,
        lastUsageReset: DateTime.now(),
      );
    }

    return SubscriptionState.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSubscriptionState(SubscriptionState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'subscription_${state.userId}',
      jsonEncode(state.toMap()),
    );
  }

  Future<WeatherSnapshot?> fetchWeather(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('weather_$userId');
    if (raw == null) {
      return null;
    }

    return WeatherSnapshot.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveWeather({
    required String userId,
    required WeatherSnapshot snapshot,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_$userId', jsonEncode(snapshot.toMap()));
  }

  Future<List<ChatMessage>> fetchMessages(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chat_$userId');
    if (raw == null) {
      return [];
    }

    final data =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
    return data.map(ChatMessage.fromMap).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> saveMessages({
    required String userId,
    required List<ChatMessage> messages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'chat_$userId',
      jsonEncode(messages.map((entry) => entry.toMap()).toList()),
    );
  }

  Future<AppLanguage?> fetchAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_language');
    if (raw == null) {
      return null;
    }
    return AppLanguage.values.where((value) => value.name == raw).firstOrNull;
  }

  Future<void> saveAppLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language.name);
  }

  Future<bool> fetchHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  Future<void> saveHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, value);
  }
}
