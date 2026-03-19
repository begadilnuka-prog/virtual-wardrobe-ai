import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../core/app_enums.dart';
import '../core/app_utils.dart';
import '../models/payment_method_summary.dart';
import '../models/subscription_purchase_receipt.dart';
import '../models/subscription_state.dart';
import '../repositories/preferences_repository.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({
    required AuthProvider authProvider,
    required PreferencesRepository repository,
    required SubscriptionService service,
  })  : _authProvider = authProvider,
        _repository = repository,
        _service = service;

  AuthProvider _authProvider;
  PreferencesRepository _repository;
  SubscriptionService _service;

  SubscriptionState? state;
  bool isLoading = false;

  SubscriptionTier get tier => state?.tier ?? SubscriptionTier.free;
  bool get isPremium => tier != SubscriptionTier.free;
  bool get isPlus => tier == SubscriptionTier.plus;
  String get tierLabel => formatSubscriptionTierLabel(tier);
  DateTime? get activatedAt => state?.activatedAt;
  DateTime? get renewalDate => state?.renewalDate;
  DateTime? get lastPaymentAt => state?.lastPaymentAt;
  String? get lastTransactionId => state?.lastTransactionId;
  PaymentMethodSummary? get paymentMethod => state?.paymentMethod;
  String? get paymentMethodLabel => paymentMethod?.label;

  int get remainingChatQuestions {
    if (isPremium) {
      return 999;
    }
    return (AppConstants.freeDailyChatLimit - (state?.dailyChatUsed ?? 0))
        .clamp(0, AppConstants.freeDailyChatLimit);
  }

  int get remainingOutfitGenerations {
    if (isPremium) {
      return 999;
    }
    return (AppConstants.freeDailyOutfitLimit -
            (state?.dailyOutfitGenerationsUsed ?? 0))
        .clamp(0, AppConstants.freeDailyOutfitLimit);
  }

  int get remainingSmartPlans {
    if (isPremium) {
      return 999;
    }
    return (AppConstants.freeDailySmartPlanLimit -
            (state?.dailySmartPlanUsed ?? 0))
        .clamp(0, AppConstants.freeDailySmartPlanLimit);
  }

  bool hasTier(SubscriptionTier requiredTier) =>
      tier.index >= requiredTier.index;

  void updateDependencies(
    AuthProvider authProvider,
    PreferencesRepository repository,
    SubscriptionService service,
  ) {
    final previousUserId = _authProvider.currentUser?.id;
    _authProvider = authProvider;
    _repository = repository;
    _service = service;
    if (previousUserId != _authProvider.currentUser?.id) {
      loadState();
    }
  }

  Future<void> loadState() async {
    final user = _authProvider.currentUser;
    if (user == null) {
      state = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    state = await _repository.fetchSubscriptionState(user.id);
    await _normalizeDailyReset();
    isLoading = false;
    notifyListeners();
  }

  Future<bool> consumeChatQuestion() async {
    if (isPremium) {
      return true;
    }
    if (remainingChatQuestions <= 0 || state == null) {
      return false;
    }

    state = state!.copyWith(dailyChatUsed: state!.dailyChatUsed + 1);
    await _repository.saveSubscriptionState(state!);
    notifyListeners();
    return true;
  }

  Future<bool> consumeOutfitGeneration() async {
    if (isPremium) {
      return true;
    }
    if (remainingOutfitGenerations <= 0 || state == null) {
      return false;
    }

    state = state!.copyWith(
      dailyOutfitGenerationsUsed: state!.dailyOutfitGenerationsUsed + 1,
    );
    await _repository.saveSubscriptionState(state!);
    notifyListeners();
    return true;
  }

  Future<void> completePurchase(SubscriptionPurchaseReceipt receipt) async {
    if (state == null) {
      return;
    }

    state = _service.activateSubscription(
      currentState: state!,
      receipt: receipt,
    );
    await _repository.saveSubscriptionState(state!);
    notifyListeners();
  }

  Future<bool> consumeSmartPlanRequest() async {
    if (isPremium) {
      return true;
    }
    if (remainingSmartPlans <= 0 || state == null) {
      return false;
    }

    state = state!.copyWith(dailySmartPlanUsed: state!.dailySmartPlanUsed + 1);
    await _repository.saveSubscriptionState(state!);
    notifyListeners();
    return true;
  }

  Future<void> _normalizeDailyReset() async {
    if (state == null) {
      return;
    }

    final now = DateTime.now();
    final last = state!.lastUsageReset;
    final isSameDay =
        now.year == last.year && now.month == last.month && now.day == last.day;
    if (isSameDay) {
      return;
    }

    state = state!.copyWith(
      dailyChatUsed: 0,
      dailyOutfitGenerationsUsed: 0,
      dailySmartPlanUsed: 0,
      lastUsageReset: now,
    );
    await _repository.saveSubscriptionState(state!);
  }
}
