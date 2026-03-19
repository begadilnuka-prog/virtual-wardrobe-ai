import 'package:flutter/material.dart';

import '../core/app_utils.dart';
import '../l10n/app_localizations.dart';
import '../models/outfit_look.dart';
import '../models/wardrobe_item.dart';
import '../theme/app_theme.dart';
import 'common/premium_badge.dart';
import 'wardrobe_image.dart';

class OutfitCard extends StatelessWidget {
  const OutfitCard({
    required this.outfit,
    required this.items,
    this.onTap,
    this.onFavorite,
    this.footer,
    super.key,
  });

  final OutfitLook outfit;
  final List<WardrobeItem> items;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = items.take(3).toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHighlight.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SizedBox(
                  height: 138,
                  child: Row(
                    children: preview
                        .map(
                          (item) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: item == preview.last ? 0 : 10),
                              child: WardrobeImage(
                                imageUrl: item.imageUrl,
                                borderRadius: BorderRadius.circular(20),
                                iconSize: 28,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(outfit.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          joinWithDot([
                            formatWardrobeTagLabel(outfit.occasion),
                            formatWardrobeTagLabel(outfit.style),
                            if ((outfit.weatherContext ?? '').isNotEmpty)
                              outfit.weatherContext!,
                          ]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      if (outfit.isPremium)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: PremiumBadge(
                            label: l10n.t('outfit_badge_premium'),
                          ),
                        ),
                      IconButton(
                        onPressed: onFavorite,
                        icon: Icon(
                          outfit.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: outfit.isFavorite
                              ? AppTheme.accent
                              : AppTheme.textSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...outfit.tags.take(3).map(
                        (tag) => _OutfitMetaChip(
                          label: formatWardrobeTagLabel(tag),
                        ),
                      ),
                  _OutfitMetaChip(
                    label: l10n.t(
                      'outfit_card_pieces',
                      args: {'count': '${items.length}'},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  outfit.notes,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 16),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OutfitMetaChip extends StatelessWidget {
  const _OutfitMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 132),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
