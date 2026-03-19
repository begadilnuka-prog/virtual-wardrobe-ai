import '../core/app_enums.dart';
import 'payment_method_summary.dart';

class SubscriptionPurchaseReceipt {
  const SubscriptionPurchaseReceipt({
    required this.tier,
    required this.paymentMethod,
    required this.transactionId,
    required this.paidAt,
  });

  final SubscriptionTier tier;
  final PaymentMethodSummary paymentMethod;
  final String transactionId;
  final DateTime paidAt;
}
