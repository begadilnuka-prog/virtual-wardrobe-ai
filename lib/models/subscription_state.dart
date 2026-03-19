import '../core/app_enums.dart';
import 'payment_method_summary.dart';

class SubscriptionState {
  const SubscriptionState({
    required this.userId,
    required this.lastUsageReset,
    this.tier = SubscriptionTier.free,
    this.dailyChatUsed = 0,
    this.dailyOutfitGenerationsUsed = 0,
    this.dailySmartPlanUsed = 0,
    this.activatedAt,
    this.renewalDate,
    this.lastPaymentAt,
    this.lastTransactionId,
    this.paymentMethod,
  });

  final String userId;
  final SubscriptionTier tier;
  final int dailyChatUsed;
  final int dailyOutfitGenerationsUsed;
  final int dailySmartPlanUsed;
  final DateTime lastUsageReset;
  final DateTime? activatedAt;
  final DateTime? renewalDate;
  final DateTime? lastPaymentAt;
  final String? lastTransactionId;
  final PaymentMethodSummary? paymentMethod;

  SubscriptionState copyWith({
    String? userId,
    SubscriptionTier? tier,
    int? dailyChatUsed,
    int? dailyOutfitGenerationsUsed,
    int? dailySmartPlanUsed,
    DateTime? lastUsageReset,
    DateTime? activatedAt,
    DateTime? renewalDate,
    DateTime? lastPaymentAt,
    String? lastTransactionId,
    PaymentMethodSummary? paymentMethod,
    bool clearBillingDates = false,
    bool clearPaymentDetails = false,
  }) {
    return SubscriptionState(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      dailyChatUsed: dailyChatUsed ?? this.dailyChatUsed,
      dailyOutfitGenerationsUsed:
          dailyOutfitGenerationsUsed ?? this.dailyOutfitGenerationsUsed,
      dailySmartPlanUsed: dailySmartPlanUsed ?? this.dailySmartPlanUsed,
      lastUsageReset: lastUsageReset ?? this.lastUsageReset,
      activatedAt: clearBillingDates ? null : activatedAt ?? this.activatedAt,
      renewalDate: clearBillingDates ? null : renewalDate ?? this.renewalDate,
      lastPaymentAt:
          clearPaymentDetails ? null : lastPaymentAt ?? this.lastPaymentAt,
      lastTransactionId: clearPaymentDetails
          ? null
          : lastTransactionId ?? this.lastTransactionId,
      paymentMethod:
          clearPaymentDetails ? null : paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tier': tier.name,
      'isPremium': tier != SubscriptionTier.free,
      'dailyChatUsed': dailyChatUsed,
      'dailyOutfitGenerationsUsed': dailyOutfitGenerationsUsed,
      'dailySmartPlanUsed': dailySmartPlanUsed,
      'lastUsageReset': lastUsageReset.toIso8601String(),
      'activatedAt': activatedAt?.toIso8601String(),
      'renewalDate': renewalDate?.toIso8601String(),
      'lastPaymentAt': lastPaymentAt?.toIso8601String(),
      'lastTransactionId': lastTransactionId,
      'paymentMethod': paymentMethod?.toMap(),
    };
  }

  factory SubscriptionState.fromMap(Map<String, dynamic> map) {
    final legacyPremium = map['isPremium'] as bool? ?? false;
    final tierName = map['tier'] as String?;
    final tier = tierName == null
        ? (legacyPremium ? SubscriptionTier.premium : SubscriptionTier.free)
        : SubscriptionTier.values.byName(tierName);

    return SubscriptionState(
      userId: map['userId'] as String,
      tier: tier,
      dailyChatUsed: map['dailyChatUsed'] as int? ?? 0,
      dailyOutfitGenerationsUsed:
          map['dailyOutfitGenerationsUsed'] as int? ?? 0,
      dailySmartPlanUsed: map['dailySmartPlanUsed'] as int? ?? 0,
      lastUsageReset:
          DateTime.tryParse(map['lastUsageReset'] as String? ?? '') ??
              DateTime.now(),
      activatedAt: DateTime.tryParse(map['activatedAt'] as String? ?? ''),
      renewalDate: DateTime.tryParse(map['renewalDate'] as String? ?? ''),
      lastPaymentAt: DateTime.tryParse(map['lastPaymentAt'] as String? ?? ''),
      lastTransactionId: map['lastTransactionId'] as String?,
      paymentMethod: map['paymentMethod'] is Map
          ? PaymentMethodSummary.fromMap(
              Map<String, dynamic>.from(map['paymentMethod'] as Map),
            )
          : null,
    );
  }
}
