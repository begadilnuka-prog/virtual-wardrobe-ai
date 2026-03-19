import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/marketplace_suggestion.dart';
import '../../theme/app_theme.dart';
import '../wardrobe_image.dart';
import 'premium_badge.dart';

class MarketplaceProductCard extends StatelessWidget {
  const MarketplaceProductCard({
    required this.item,
    this.width = 220,
    this.locked = false,
    this.badgeLabel,
    this.onTap,
    super.key,
  });

  final MarketplaceSuggestion item;
  final double width;
  final bool locked;
  final String? badgeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.95,
                    child: WardrobeImage(
                      imageUrl: item.imageUrl,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                  ),
                  if (badgeLabel != null)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: PremiumBadge(label: badgeLabel!),
                    ),
                  if (locked)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: AppTheme.accentDeep,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.brand,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: AppTheme.accentDeep,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Text(
                            item.priceLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          item.reason,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            locked
                                ? Icons.workspace_premium_rounded
                                : Icons.shopping_bag_outlined,
                            size: 18,
                            color:
                                locked ? AppTheme.premium : AppTheme.accentDeep,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locked
                                  ? l10n.t('marketplace_unlock_plus')
                                  : l10n.t('marketplace_partner_pick'),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
