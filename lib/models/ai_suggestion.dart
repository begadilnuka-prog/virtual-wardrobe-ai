import 'wardrobe_item.dart';

class AiSuggestion {
  const AiSuggestion({
    required this.title,
    required this.reasoning,
    required this.items,
    required this.occasion,
    required this.mood,
  });

  final String title;
  final String reasoning;
  final List<WardrobeItem> items;
  final String occasion;
  final String mood;
}
