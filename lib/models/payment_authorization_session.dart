import '../core/app_enums.dart';
import 'payment_method_summary.dart';
import 'subscription_purchase_receipt.dart';

class PaymentAuthorizationSession {
  const PaymentAuthorizationSession({
    required this.authorizationId,
    required this.tier,
    required this.paymentMethod,
    required this.verificationCode,
    required this.createdAt,
  });

  final String authorizationId;
  final SubscriptionTier tier;
  final PaymentMethodSummary paymentMethod;
  final String verificationCode;
  final DateTime createdAt;

  PaymentAuthorizationSession copyWith({
    String? authorizationId,
    SubscriptionTier? tier,
    PaymentMethodSummary? paymentMethod,
    String? verificationCode,
    DateTime? createdAt,
  }) {
    return PaymentAuthorizationSession(
      authorizationId: authorizationId ?? this.authorizationId,
      tier: tier ?? this.tier,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      verificationCode: verificationCode ?? this.verificationCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PaymentAuthorizationResult {
  const PaymentAuthorizationResult._({
    this.session,
    this.errorMessage,
  });

  final PaymentAuthorizationSession? session;
  final String? errorMessage;

  bool get isSuccess => session != null;

  factory PaymentAuthorizationResult.success(
    PaymentAuthorizationSession session,
  ) {
    return PaymentAuthorizationResult._(session: session);
  }

  factory PaymentAuthorizationResult.failure(String message) {
    return PaymentAuthorizationResult._(errorMessage: message);
  }
}

class PaymentVerificationResult {
  const PaymentVerificationResult._({
    this.receipt,
    this.errorMessage,
  });

  final SubscriptionPurchaseReceipt? receipt;
  final String? errorMessage;

  bool get isSuccess => receipt != null;

  factory PaymentVerificationResult.success(
    SubscriptionPurchaseReceipt receipt,
  ) {
    return PaymentVerificationResult._(receipt: receipt);
  }

  factory PaymentVerificationResult.failure(String message) {
    return PaymentVerificationResult._(errorMessage: message);
  }
}
