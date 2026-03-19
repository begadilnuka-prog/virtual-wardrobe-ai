import 'package:flutter/material.dart';

import '../core/app_utils.dart';
import '../l10n/app_localizations.dart';
import '../models/wardrobe_item.dart';
import '../theme/app_theme.dart';
import 'wardrobe_image.dart';

enum _WardrobeMenuAction { edit, delete }

class WardrobeItemCard extends StatelessWidget {
  const WardrobeItemCard({
    required this.item,
    this.onFavorite,
    this.onEdit,
    this.onDelete,
    this.onTap,
    super.key,
  });

  final WardrobeItem item;
  final VoidCallback? onFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitle = joinWithDot([
      formatColorLabel(item.color),
      formatStyleTagLabel(item.style),
    ]);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'wardrobe-item-${item.id}',
                    child: WardrobeImage(
                      imageUrl: item.imageUrl,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            AppTheme.accentDeep.withValues(alpha: 0.16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        formatCategoryLabel(item.category),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.text,
                                ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _SurfaceIconButton(
                      tooltip: l10n.t('form_favorite_item'),
                      icon: item.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor:
                          item.isFavorite ? AppTheme.accent : AppTheme.textSoft,
                      onPressed: onFavorite,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatWardrobeItemName(item.name),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (onEdit != null || onDelete != null) ...[
                        const SizedBox(width: 10),
                        PopupMenuButton<_WardrobeMenuAction>(
                          tooltip: l10n.t('common_edit'),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_horiz_rounded),
                          onSelected: (action) {
                            switch (action) {
                              case _WardrobeMenuAction.edit:
                                onEdit?.call();
                                break;
                              case _WardrobeMenuAction.delete:
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              PopupMenuItem(
                                value: _WardrobeMenuAction.edit,
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 18),
                                    const SizedBox(width: 10),
                                    Text(l10n.t('common_edit')),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              PopupMenuItem(
                                value: _WardrobeMenuAction.delete,
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline_rounded,
                                        size: 18),
                                    const SizedBox(width: 10),
                                    Text(l10n.t('common_delete')),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: formatColorLabel(item.color)),
                      _InfoChip(label: formatSeasonLabel(item.season)),
                      if (item.isFavorite)
                        _InfoChip(
                          label: l10n.t('wardrobe_badge_loved'),
                          icon: Icons.favorite_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppTheme.accentDeep),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 118),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppTheme.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceIconButton extends StatelessWidget {
  const _SurfaceIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor = AppTheme.accentDeep,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 20),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
