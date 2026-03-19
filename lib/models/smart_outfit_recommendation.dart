import '../core/app_enums.dart';
import 'daily_plan.dart';
import 'marketplace_suggestion.dart';
import 'outfit_look.dart';

class SmartOutfitRecommendation {
  const SmartOutfitRecommendation({
    required this.look,
    required this.explanation,
    required this.date,
    required this.occasion,
    required this.weather,
    this.marketplaceSuggestions = const [],
  });

  final OutfitLook look;
  final String explanation;
  final DateTime date;
  final DailyOccasion occasion;
  final WeatherCondition weather;
  final List<MarketplaceSuggestion> marketplaceSuggestions;

  DailyPlan toDailyPlan({
    required String userId,
    String? existingId,
    String? savedOutfitId,
  }) {
    final now = DateTime.now();
    return DailyPlan(
      id: existingId ?? look.id,
      userId: userId,
      title: look.title,
      date: date,
      weatherType: weather,
      occasionType: occasion,
      recommendedItemIds: look.itemIds,
      explanation: explanation,
      savedOutfitId: savedOutfitId,
      styleLabel: look.style,
      tags: look.tags,
      marketplaceSuggestions: marketplaceSuggestions,
      createdAt: now,
      updatedAt: now,
    );
  }
}
