import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_assets.dart';
import '../../core/app_constants.dart';
import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/marketplace_product_card.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/common/subscription_checkout_sheet.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/styled_button.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PremiumScaffold(
      appBar: AppBar(title: Text(l10n.t('premium_title'))),
      child: Consumer<SubscriptionProvider>(
        builder: (context, subscription, _) {
          return ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(l10n.t('premium_upgrade_title'),
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                l10n.t('premium_upgrade_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _CurrentPlanHero(subscription: subscription),
              const SizedBox(height: 24),
              _PlanCard(
                tier: SubscriptionTier.free,
                accent: AppTheme.softSurface,
                icon: Icons.checkroom_rounded,
                active: subscription.tier == SubscriptionTier.free,
                actionLabel: subscription.tier == SubscriptionTier.free
                    ? l10n.t('premium_action_current_plan')
                    : l10n.t('premium_action_included_default'),
                onPressed: null,
              ),
              const SizedBox(height: 14),
              _PlanCard(
                tier: SubscriptionTier.premium,
                accent: AppTheme.accent,
                icon: Icons.workspace_premium_rounded,
                active: subscription.tier == SubscriptionTier.premium,
                actionLabel: subscription.isPlus
                    ? l10n.t('premium_action_included_plus')
                    : subscription.tier == SubscriptionTier.premium
                        ? l10n.t('premium_action_current_plan')
                        : l10n.t('premium_action_upgrade_premium'),
                onPressed: subscription.isPremium
                    ? null
                    : () => showSubscriptionCheckoutFlow(
                          context,
                          tier: SubscriptionTier.premium,
                        ),
              ),
              const SizedBox(height: 14),
              _PlanCard(
                tier: SubscriptionTier.plus,
                accent: AppTheme.premium,
                icon: Icons.shopping_bag_outlined,
                active: subscription.isPlus,
                actionLabel: subscription.isPlus
                    ? l10n.t('premium_action_current_plan')
                    : l10n.t('premium_action_subscribe_plus'),
                onPressed: subscription.isPlus
                    ? null
                    : () => showSubscriptionCheckoutFlow(
                          context,
                          tier: SubscriptionTier.plus,
                        ),
              ),
              const SizedBox(height: 24),
              const _ComparisonTable(),
              const SizedBox(height: 24),
              Text(l10n.t('premium_partner_preview_title'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                subscription.isPlus
                    ? l10n.t('premium_partner_preview_body_plus')
                    : l10n.t('premium_partner_preview_body_locked'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 332,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppAssets.partnerPreviewItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => MarketplaceProductCard(
                    item: AppAssets.partnerPreviewItems[index],
                    locked: !subscription.isPlus,
                    badgeLabel: subscription.isPlus
                        ? l10n.t('marketplace_partner_pick')
                        : formatSubscriptionTierLabel(SubscriptionTier.plus),
                    onTap: subscription.isPlus
                        ? null
                        : () => showSubscriptionCheckoutFlow(
                              context,
                              tier: SubscriptionTier.plus,
                              featureName: l10n.t('smart_planner_shop_title'),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.t('premium_billing_title'),
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(
                        subscription.isPremium
                            ? l10n.t(
                                'premium_billing_active_body',
                                args: {
                                  'plan': subscription.tierLabel,
                                  'activated': formatShortDate(
                                    subscription.activatedAt ?? DateTime.now(),
                                  ),
                                  'renewal': formatShortDate(
                                    subscription.renewalDate ?? DateTime.now(),
                                  ),
                                },
                              )
                            : l10n.t('premium_billing_free_body'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (subscription.isPremium &&
                          subscription.paymentMethodLabel != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.credit_card_rounded,
                              size: 18,
                              color: AppTheme.accentDeep,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              subscription.paymentMethodLabel!,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ],
                      if (subscription.isPremium &&
                          subscription.lastTransactionId != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.t(
                            'premium_billing_reference',
                            args: {
                              'reference':
                                  subscription.lastTransactionId!.substring(
                                0,
                                12,
                              ),
                            },
                          ),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      StyledButton(
                        label: subscription.isPlus
                            ? l10n.t('premium_cta_active')
                            : subscription.isPremium
                                ? l10n.t('premium_cta_upgrade_plus')
                                : l10n.t('premium_gate_continue'),
                        icon: Icons.lock_outline_rounded,
                        onPressed: subscription.isPlus
                            ? null
                            : () => showSubscriptionCheckoutFlow(
                                  context,
                                  tier: subscription.isPremium
                                      ? SubscriptionTier.plus
                                      : SubscriptionTier.premium,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CurrentPlanHero extends StatelessWidget {
  const _CurrentPlanHero({required this.subscription});

  final SubscriptionProvider subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1F2F5),
            Color(0xFFE8EBF2),
            Color(0xFFE1D9E7),
          ],
        ),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumBadge(
            label: context.l10n.t(
              'premium_plan_badge',
              args: {'plan': subscription.tierLabel},
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subscription.isPlus
                ? context.l10n.t('premium_current_plus_title')
                : subscription.isPremium
                    ? context.l10n.t('premium_current_premium_title')
                    : context.l10n.t('premium_current_free_title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            subscription.isPremium
                ? context.l10n.t('premium_current_paid_subtitle')
                : context.l10n.t('premium_current_free_subtitle'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (subscription.isPremium &&
              subscription.paymentMethodLabel != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.credit_card_rounded,
                  size: 18,
                  color: AppTheme.accentDeep,
                ),
                const SizedBox(width: 8),
                Text(
                  subscription.paymentMethodLabel!,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tier,
    required this.accent,
    required this.icon,
    required this.active,
    required this.actionLabel,
    required this.onPressed,
  });

  final SubscriptionTier tier;
  final Color accent;
  final IconData icon;
  final bool active;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = formatSubscriptionTierLabel(tier);
    final features = AppConstants.planFeatureBullets[tier] ?? const <String>[];
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: 0.84),
        border: Border.all(
          color: active ? accent.withValues(alpha: 0.75) : AppTheme.border,
          width: active ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: active ? 0.12 : 0.05),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      formatSubscriptionPrice(tier),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: accent),
                    ),
                  ],
                ),
              ),
              if (active) PremiumBadge(label: l10n.t('common_active')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppConstants.planTaglines[tier] ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 18, color: accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          StyledButton(
            label: actionLabel,
            icon: onPressed == null
                ? Icons.verified_rounded
                : Icons.lock_outline_rounded,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 720),
            child: Column(
              children: [
                const _TableHeader(),
                const Divider(height: 28),
                _PlanRow(
                  label: l10n.t('premium_compare_stylist_chat'),
                  freeValue:
                      l10n.t('premium_compare_per_day', args: {'count': '6'}),
                  premiumValue: l10n.t('premium_compare_unlimited'),
                  plusValue: l10n.t('premium_compare_unlimited'),
                ),
                const Divider(height: 28),
                _PlanRow(
                  label: l10n.t('premium_compare_outfit_generation'),
                  freeValue:
                      l10n.t('premium_compare_per_day', args: {'count': '3'}),
                  premiumValue: l10n.t('premium_compare_unlimited'),
                  plusValue: l10n.t('premium_compare_unlimited'),
                ),
                const Divider(height: 28),
                _PlanRow(
                  label: l10n.t('premium_compare_smart_planner'),
                  freeValue:
                      l10n.t('premium_compare_per_day', args: {'count': '2'}),
                  premiumValue: l10n.t('premium_compare_unlimited'),
                  plusValue: l10n.t('premium_compare_unlimited'),
                ),
                const Divider(height: 28),
                _PlanRow(
                  label: l10n.t('premium_compare_personalization_quality'),
                  freeValue: l10n.t('premium_compare_basic'),
                  premiumValue: l10n.t('premium_compare_advanced'),
                  plusValue: l10n.t('premium_compare_most_advanced'),
                ),
                const Divider(height: 28),
                _PlanRow(
                  label: l10n.t('premium_compare_marketplace_access'),
                  freeValue: l10n.t('premium_compare_locked'),
                  premiumValue: l10n.t('premium_compare_locked'),
                  plusValue: l10n.t('premium_compare_included'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.t('premium_compare_feature'),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeaderCell(
            label: formatSubscriptionTierLabel(SubscriptionTier.free),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeaderCell(
            label: formatSubscriptionTierLabel(SubscriptionTier.premium),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeaderCell(
            label: formatSubscriptionTierLabel(SubscriptionTier.plus),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.label,
    required this.freeValue,
    required this.premiumValue,
    required this.plusValue,
  });

  final String label;
  final String freeValue;
  final String premiumValue;
  final String plusValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanValue(
            value: freeValue,
            alignment: Alignment.center,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanValue(
            value: premiumValue,
            alignment: Alignment.center,
            highlightColor: AppTheme.accentDeep,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanValue(
            value: plusValue,
            alignment: Alignment.centerRight,
            highlightColor: AppTheme.premium,
          ),
        ),
      ],
    );
  }
}

class _PlanValue extends StatelessWidget {
  const _PlanValue({
    required this.value,
    required this.alignment,
    this.highlightColor,
  });

  final String value;
  final Alignment alignment;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final isLocked = value == context.l10n.t('premium_compare_locked');
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight:
              highlightColor == null ? FontWeight.w500 : FontWeight.w700,
          color: highlightColor,
        );

    return Align(
      alignment: alignment,
      child: isLocked
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppTheme.textSoft),
                const SizedBox(width: 4),
                Text(value, style: textStyle),
              ],
            )
          : Text(value, textAlign: TextAlign.center, style: textStyle),
    );
  }
}
