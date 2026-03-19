import '../models/subscription_purchase_receipt.dart';
import '../models/subscription_state.dart';

class SubscriptionService {
  SubscriptionState activateSubscription({
    required SubscriptionState currentState,
    required SubscriptionPurchaseReceipt receipt,
  }) {
    return currentState.copyWith(
      tier: receipt.tier,
      activatedAt: receipt.paidAt,
      renewalDate: receipt.paidAt.add(const Duration(days: 30)),
      lastPaymentAt: receipt.paidAt,
      lastTransactionId: receipt.transactionId,
      paymentMethod: receipt.paymentMethod,
    );
  }
}
