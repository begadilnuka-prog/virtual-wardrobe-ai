import '../core/app_enums.dart';

class WardrobeItem {
  const WardrobeItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.color,
    required this.season,
    required this.style,
    required this.createdAt,
    this.tags = const [],
    this.brand,
    this.notes,
    this.isFavorite = false,
  });

  final String id;
  final String userId;
  final String name;
  final String imageUrl;
  final ClothingCategory category;
  final String color;
  final SeasonTag season;
  final StyleTag style;
  final List<String> tags;
  final String? brand;
  final String? notes;
  final bool isFavorite;
  final DateTime createdAt;

  WardrobeItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? imageUrl,
    ClothingCategory? category,
    String? color,
    SeasonTag? season,
    StyleTag? style,
    List<String>? tags,
    String? brand,
    String? notes,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      color: color ?? this.color,
      season: season ?? this.season,
      style: style ?? this.style,
      tags: tags ?? this.tags,
      brand: brand ?? this.brand,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'category': category.name,
      'color': color,
      'season': season.name,
      'style': style.name,
      'tags': tags,
      'brand': brand,
      'notes': notes,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WardrobeItem.fromMap(Map<String, dynamic> map) {
    return WardrobeItem(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String? ?? '',
      category: ClothingCategory.values.byName(map['category'] as String),
      color: map['color'] as String,
      season: SeasonTag.values
          .byName(map['season'] as String? ?? SeasonTag.allSeason.name),
      style: StyleTag.values
          .byName(map['style'] as String? ?? StyleTag.minimal.name),
      tags: (map['tags'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      brand: map['brand'] as String?,
      notes: map['notes'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
