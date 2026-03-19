class OutfitLook {
  const OutfitLook({
    required this.id,
    required this.userId,
    required this.title,
    required this.itemIds,
    required this.occasion,
    required this.style,
    required this.notes,
    required this.createdAt,
    this.tags = const [],
    this.weatherContext,
    this.isFavorite = false,
    this.isGenerated = true,
    this.isPremium = false,
  });

  final String id;
  final String userId;
  final String title;
  final List<String> itemIds;
  final String occasion;
  final String style;
  final String notes;
  final List<String> tags;
  final String? weatherContext;
  final bool isFavorite;
  final bool isGenerated;
  final bool isPremium;
  final DateTime createdAt;

  OutfitLook copyWith({
    String? id,
    String? userId,
    String? title,
    List<String>? itemIds,
    String? occasion,
    String? style,
    String? notes,
    List<String>? tags,
    String? weatherContext,
    bool? isFavorite,
    bool? isGenerated,
    bool? isPremium,
    DateTime? createdAt,
  }) {
    return OutfitLook(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      itemIds: itemIds ?? this.itemIds,
      occasion: occasion ?? this.occasion,
      style: style ?? this.style,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      weatherContext: weatherContext ?? this.weatherContext,
      isFavorite: isFavorite ?? this.isFavorite,
      isGenerated: isGenerated ?? this.isGenerated,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'itemIds': itemIds,
      'occasion': occasion,
      'style': style,
      'notes': notes,
      'tags': tags,
      'weatherContext': weatherContext,
      'isFavorite': isFavorite,
      'isGenerated': isGenerated,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OutfitLook.fromMap(Map<String, dynamic> map) {
    return OutfitLook(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      itemIds: List<String>.from(map['itemIds'] as List<dynamic>),
      occasion: map['occasion'] as String? ?? '',
      style: map['style'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      tags: (map['tags'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      weatherContext: map['weatherContext'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isGenerated: map['isGenerated'] as bool? ?? true,
      isPremium: map['isPremium'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
