import '../core/app_enums.dart';

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.condition,
    required this.temperatureCelsius,
    required this.feelsLikeCelsius,
    required this.windKph,
    required this.city,
    required this.summary,
    required this.styleSuggestion,
    required this.updatedAt,
  });

  final WeatherCondition condition;
  final int temperatureCelsius;
  final int feelsLikeCelsius;
  final int windKph;
  final String city;
  final String summary;
  final String styleSuggestion;
  final DateTime updatedAt;

  WeatherSnapshot copyWith({
    WeatherCondition? condition,
    int? temperatureCelsius,
    int? feelsLikeCelsius,
    int? windKph,
    String? city,
    String? summary,
    String? styleSuggestion,
    DateTime? updatedAt,
  }) {
    return WeatherSnapshot(
      condition: condition ?? this.condition,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      feelsLikeCelsius: feelsLikeCelsius ?? this.feelsLikeCelsius,
      windKph: windKph ?? this.windKph,
      city: city ?? this.city,
      summary: summary ?? this.summary,
      styleSuggestion: styleSuggestion ?? this.styleSuggestion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition.name,
      'temperatureCelsius': temperatureCelsius,
      'feelsLikeCelsius': feelsLikeCelsius,
      'windKph': windKph,
      'city': city,
      'summary': summary,
      'styleSuggestion': styleSuggestion,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WeatherSnapshot.fromMap(Map<String, dynamic> map) {
    return WeatherSnapshot(
      condition: WeatherCondition.values.byName(
        map['condition'] as String? ?? WeatherCondition.cloudy.name,
      ),
      temperatureCelsius: map['temperatureCelsius'] as int? ?? 22,
      feelsLikeCelsius: map['feelsLikeCelsius'] as int? ?? 21,
      windKph: map['windKph'] as int? ?? 12,
      city: map['city'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      styleSuggestion: map['styleSuggestion'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
