import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../screens/premium/subscription_checkout_screen.dart';

Future<void> showSubscriptionCheckoutFlow(
  BuildContext context, {
  required SubscriptionTier tier,
  String? featureName,
}) async {
  if (tier == SubscriptionTier.free) {
    return;
  }

  final subscription = context.read<SubscriptionProvider>();
  final l10n = context.l10n;
  if (subscription.hasTier(tier)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.t(
            'checkout_plan_already_active',
            args: {'plan': formatSubscriptionTierLabel(tier)},
          ),
        ),
      ),
    );
    return;
  }

  final activatedTier = await Navigator.of(context).push<SubscriptionTier>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => SubscriptionCheckoutScreen(
        initialTier: tier,
        featureName: featureName,
      ),
    ),
  );

  if (!context.mounted || activatedTier == null) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        l10n.t(
          'checkout_plan_now_active',
          args: {'plan': formatSubscriptionTierLabel(activatedTier)},
        ),
      ),
    ),
  );
}
