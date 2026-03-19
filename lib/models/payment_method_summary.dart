import '../core/app_utils.dart';

class PaymentMethodSummary {
  const PaymentMethodSummary({
    required this.brand,
    required this.last4,
  });

  final String brand;
  final String last4;

  String get label {
    final displayBrand = brand == 'Card'
        ? localizedText(en: 'Card', ru: 'Карта', kk: 'Карта')
        : brand;
    return '$displayBrand •••• $last4';
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'last4': last4,
    };
  }

  factory PaymentMethodSummary.fromMap(Map<String, dynamic> map) {
    return PaymentMethodSummary(
      brand: map['brand'] as String? ?? 'Card',
      last4: map['last4'] as String? ?? '0000',
    );
  }
}
