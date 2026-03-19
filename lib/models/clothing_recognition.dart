import '../core/app_enums.dart';

class ClothingRecognition {
  const ClothingRecognition({
    required this.name,
    required this.category,
    required this.color,
    required this.season,
    required this.style,
    required this.tags,
    this.confidence = 0.82,
  });

  final String name;
  final ClothingCategory category;
  final String color;
  final SeasonTag season;
  final StyleTag style;
  final List<String> tags;
  final double confidence;
}
