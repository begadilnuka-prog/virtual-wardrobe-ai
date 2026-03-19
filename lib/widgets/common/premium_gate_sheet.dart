import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/subscription_checkout_sheet.dart';
import '../../widgets/styled_button.dart';
import '../../screens/premium/premium_screen.dart';

Future<void> showPremiumGateSheet(
  BuildContext context, {
  required String featureName,
  SubscriptionTier requiredTier = SubscriptionTier.premium,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Consumer<SubscriptionProvider>(
          builder: (context, subscription, _) {
            final l10n = context.l10n;
            final hasRequiredTier =
                subscription.tier.index >= requiredTier.index;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppTheme.premium),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.t('premium_gate_title', args: {'feature': featureName}),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  requiredTier == SubscriptionTier.plus
                      ? l10n.t('premium_gate_subtitle_plus')
                      : l10n.t('premium_gate_subtitle_premium'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                StyledButton(
                  label: hasRequiredTier
                      ? l10n.t('premium_gate_active',
                          args: {'plan': subscription.tierLabel})
                      : requiredTier == SubscriptionTier.plus
                          ? l10n.t('premium_gate_continue')
                          : l10n.t('premium_gate_upgrade'),
                  icon: Icons.auto_awesome_rounded,
                  onPressed: hasRequiredTier
                      ? null
                      : () async {
                          Navigator.of(sheetContext).pop();
                          if (context.mounted) {
                            await showSubscriptionCheckoutFlow(
                              context,
                              tier: requiredTier,
                              featureName: featureName,
                            );
                          }
                        },
                ),
                const SizedBox(height: 12),
                StyledButton(
                  label: l10n.t('premium_gate_details'),
                  secondary: true,
                  onPressed: () {
                    Navigator.of(sheetContext).push(
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    );
                  },
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
