import '../core/app_enums.dart';
import 'marketplace_suggestion.dart';

class DailyPlan {
  const DailyPlan({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.weatherType,
    required this.occasionType,
    required this.recommendedItemIds,
    required this.explanation,
    required this.createdAt,
    required this.updatedAt,
    this.savedOutfitId,
    this.styleLabel = '',
    this.tags = const [],
    this.marketplaceSuggestions = const [],
  });

  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final WeatherCondition weatherType;
  final DailyOccasion occasionType;
  final List<String> recommendedItemIds;
  final String explanation;
  final String? savedOutfitId;
  final String styleLabel;
  final List<String> tags;
  final List<MarketplaceSuggestion> marketplaceSuggestions;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyPlan copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    WeatherCondition? weatherType,
    DailyOccasion? occasionType,
    List<String>? recommendedItemIds,
    String? explanation,
    String? savedOutfitId,
    bool clearSavedOutfitId = false,
    String? styleLabel,
    List<String>? tags,
    List<MarketplaceSuggestion>? marketplaceSuggestions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      weatherType: weatherType ?? this.weatherType,
      occasionType: occasionType ?? this.occasionType,
      recommendedItemIds: recommendedItemIds ?? this.recommendedItemIds,
      explanation: explanation ?? this.explanation,
      savedOutfitId:
          clearSavedOutfitId ? null : savedOutfitId ?? this.savedOutfitId,
      styleLabel: styleLabel ?? this.styleLabel,
      tags: tags ?? this.tags,
      marketplaceSuggestions:
          marketplaceSuggestions ?? this.marketplaceSuggestions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'date': date.toIso8601String(),
      'weatherType': weatherType.name,
      'occasionType': occasionType.name,
      'recommendedItemIds': recommendedItemIds,
      'explanation': explanation,
      'savedOutfitId': savedOutfitId,
      'styleLabel': styleLabel,
      'tags': tags,
      'marketplaceSuggestions':
          marketplaceSuggestions.map((entry) => entry.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyPlan.fromMap(Map<String, dynamic> map) {
    return DailyPlan(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      weatherType: WeatherCondition.values.byName(
        map['weatherType'] as String? ?? WeatherCondition.cloudy.name,
      ),
      occasionType: DailyOccasion.values.byName(
        map['occasionType'] as String? ?? DailyOccasion.casualWalk.name,
      ),
      recommendedItemIds:
          (map['recommendedItemIds'] as List<dynamic>? ?? const [])
              .map((entry) => entry.toString())
              .toList(),
      explanation: map['explanation'] as String? ?? '',
      savedOutfitId: map['savedOutfitId'] as String?,
      styleLabel: map['styleLabel'] as String? ?? '',
      tags: (map['tags'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      marketplaceSuggestions:
          (map['marketplaceSuggestions'] as List<dynamic>? ?? const [])
              .map((entry) => MarketplaceSuggestion.fromMap(
                  Map<String, dynamic>.from(entry as Map)))
              .toList(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
