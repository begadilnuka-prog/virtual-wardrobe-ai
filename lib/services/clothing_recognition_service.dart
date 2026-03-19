import '../core/app_constants.dart';
import '../core/app_enums.dart';
import '../core/app_utils.dart';
import '../models/clothing_recognition.dart';

class ClothingRecognitionService {
  Future<ClothingRecognition> recognize(String imagePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    final normalized = imagePath.split('/').last.toLowerCase();
    final seed = normalized.hashCode.abs();
    final category = _matchCategory(normalized, seed);
    final color = _matchColor(normalized, seed);
    final season = _matchSeason(normalized, seed);
    final style = _matchStyle(normalized, seed);
    final tags = _matchTags(normalized, category, style, seed);

    return ClothingRecognition(
      name: _buildName(color, category, style),
      category: category,
      color: color,
      season: season,
      style: style,
      tags: tags,
      confidence: 0.78 + (seed % 18) / 100,
    );
  }

  ClothingCategory _matchCategory(String value, int seed) {
    const keywords = <String, ClothingCategory>{
      'shirt': ClothingCategory.tops,
      'tee': ClothingCategory.tops,
      'top': ClothingCategory.tops,
      'blouse': ClothingCategory.tops,
      'sweater': ClothingCategory.tops,
      'hoodie': ClothingCategory.tops,
      'pants': ClothingCategory.bottoms,
      'trouser': ClothingCategory.bottoms,
      'jean': ClothingCategory.bottoms,
      'skirt': ClothingCategory.bottoms,
      'short': ClothingCategory.bottoms,
      'dress': ClothingCategory.dresses,
      'coat': ClothingCategory.outerwear,
      'jacket': ClothingCategory.outerwear,
      'blazer': ClothingCategory.outerwear,
      'sneaker': ClothingCategory.shoes,
      'shoe': ClothingCategory.shoes,
      'boot': ClothingCategory.shoes,
      'bag': ClothingCategory.bags,
      'purse': ClothingCategory.bags,
      'hat': ClothingCategory.accessories,
      'scarf': ClothingCategory.accessories,
      'belt': ClothingCategory.accessories,
    };

    for (final entry in keywords.entries) {
      if (value.contains(entry.key)) {
        return entry.value;
      }
    }

    return AppConstants
        .defaultCategoryOrder[seed % AppConstants.defaultCategoryOrder.length];
  }

  String _matchColor(String value, int seed) {
    for (final color in AppConstants.demoColors) {
      final key = color.toLowerCase().replaceAll(' ', '');
      final plain = color.toLowerCase().split(' ').last;
      if (value.contains(key) || value.contains(plain)) {
        return color;
      }
    }
    return AppConstants.demoColors[seed % AppConstants.demoColors.length];
  }

  SeasonTag _matchSeason(String value, int seed) {
    if (value.contains('coat') ||
        value.contains('knit') ||
        value.contains('wool')) {
      return SeasonTag.winter;
    }
    if (value.contains('linen') ||
        value.contains('short') ||
        value.contains('tank')) {
      return SeasonTag.summer;
    }
    if (value.contains('trench') || value.contains('light')) {
      return SeasonTag.spring;
    }
    if (value.contains('layer')) {
      return SeasonTag.autumn;
    }
    return SeasonTag.values[seed % SeasonTag.values.length];
  }

  StyleTag _matchStyle(String value, int seed) {
    if (value.contains('blazer') || value.contains('tailored')) {
      return StyleTag.formal;
    }
    if (value.contains('sneaker') || value.contains('hoodie')) {
      return StyleTag.casual;
    }
    if (value.contains('dress') || value.contains('silk')) {
      return StyleTag.chic;
    }
    if (value.contains('oversized') || value.contains('street')) {
      return StyleTag.streetwear;
    }
    return StyleTag.values[seed % StyleTag.values.length];
  }

  List<String> _matchTags(
    String value,
    ClothingCategory category,
    StyleTag style,
    int seed,
  ) {
    final tags = <String>{
      switch (style) {
        StyleTag.formal => 'formal',
        StyleTag.smartCasual => 'smart casual',
        StyleTag.casual => 'casual',
        StyleTag.modest => 'cozy',
        StyleTag.minimal => 'minimal',
        StyleTag.chic => 'weekend',
        StyleTag.streetwear => 'sporty',
      },
      switch (category) {
        ClothingCategory.outerwear => 'layering',
        ClothingCategory.shoes => 'weekend',
        ClothingCategory.dresses => 'college',
        _ => 'casual',
      },
    };

    if (value.contains('rain')) {
      tags.add('rainy day');
    }

    if (tags.length < 3) {
      tags.add(
          AppConstants.wardrobeTags[seed % AppConstants.wardrobeTags.length]);
    }

    return tags.take(3).toList();
  }

  String _buildName(String color, ClothingCategory category, StyleTag style) {
    final descriptor = switch (style) {
      StyleTag.formal =>
        localizedText(en: 'Tailored', ru: 'Структурная', kk: 'Нақты пішінді'),
      StyleTag.smartCasual =>
        localizedText(en: 'Everyday', ru: 'Повседневная', kk: 'Күнделікті'),
      StyleTag.casual =>
        localizedText(en: 'Relaxed', ru: 'Свободная', kk: 'Еркін'),
      StyleTag.modest => localizedText(en: 'Soft', ru: 'Мягкая', kk: 'Жұмсақ'),
      StyleTag.minimal =>
        localizedText(en: 'Clean', ru: 'Лаконичная', kk: 'Таза'),
      StyleTag.chic =>
        localizedText(en: 'Polished', ru: 'Элегантная', kk: 'Сәнді'),
      StyleTag.streetwear =>
        localizedText(en: 'Modern', ru: 'Современная', kk: 'Заманауи'),
    };

    return '$color $descriptor ${formatCategoryLabel(category)}';
  }
}
