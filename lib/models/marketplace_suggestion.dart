class MarketplaceSuggestion {
  const MarketplaceSuggestion({
    required this.brand,
    required this.title,
    required this.priceLabel,
    required this.reason,
    this.imageUrl = '',
  });

  final String brand;
  final String title;
  final String priceLabel;
  final String reason;
  final String imageUrl;

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'title': title,
      'priceLabel': priceLabel,
      'reason': reason,
      'imageUrl': imageUrl,
    };
  }

  factory MarketplaceSuggestion.fromMap(Map<String, dynamic> map) {
    return MarketplaceSuggestion(
      brand: map['brand'] as String? ?? '',
      title: map['title'] as String? ?? '',
      priceLabel: map['priceLabel'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }
}
