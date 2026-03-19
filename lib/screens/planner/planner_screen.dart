import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/outfit_look.dart';
import '../../models/wardrobe_item.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/common/premium_gate_sheet.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/wardrobe_image.dart';
import '../ai/ai_stylist_screen.dart';
import 'smart_planner_screen.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final planner = context.watch<PlannerProvider>();
    final outfits = context.watch<OutfitProvider>();
    final wardrobe = context.watch<WardrobeProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final todayPlan = planner.todayPlan;
    final plannedDays =
        List.generate(7, (index) => planner.outfitIdForDay(index))
            .whereType<String>()
            .length;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text(l10n.t('planner_title')),
        actions: [
          IconButton.filledTonal(
            tooltip: l10n.t('ai_title'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiStylistScreen()),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F4F0),
                  Color(0xFFE9EDF2),
                  Color(0xFFE6E0E8),
                ],
              ),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentDeep.withValues(alpha: 0.05),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.t('planner_week_title'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (subscription.isPremium)
                      PremiumBadge(
                        label: formatSubscriptionTierLabel(
                          subscription.isPlus
                              ? SubscriptionTier.plus
                              : SubscriptionTier.premium,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(l10n.t('common_free_plan')),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.t('planner_week_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _WeekMetaCard(
                        icon: Icons.calendar_month_rounded,
                        title: l10n.t('planner_week_ready',
                            args: {'count': '$plannedDays'}),
                        subtitle: l10n.t(
                          plannedDays == 0
                              ? 'planner_week_empty'
                              : 'planner_day_preview',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WeekMetaCard(
                        icon: Icons.auto_awesome_rounded,
                        title: todayPlan == null
                            ? l10n.t('planner_open_smart_planner')
                            : formatDailyOccasionLabel(todayPlan.occasionType),
                        subtitle: todayPlan == null
                            ? l10n.t('planner_smart_subtitle_empty')
                            : formatWeatherLabel(todayPlan.weatherType),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _WeekOverviewStrip(planner: planner),
          const SizedBox(height: 18),
          ...List.generate(7, (index) {
            final outfitId = planner.outfitIdForDay(index);
            final savedLook =
                outfitId == null ? null : outfits.findSavedById(outfitId);
            final items = savedLook == null
                ? const <WardrobeItem>[]
                : wardrobe.allItems
                    .where((item) => savedLook.itemIds.contains(item.id))
                    .toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PlannerDayCard(
                dayIndex: index,
                look: savedLook,
                items: items,
                onAssign: () => _openPlannerPicker(context, dayIndex: index),
                onRemove:
                    savedLook == null ? null : () => planner.removePlan(index),
              ),
            );
          }),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l10n.t('planner_smart_title'),
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 10),
                      if (subscription.isPremium)
                        PremiumBadge(
                          label: formatSubscriptionTierLabel(
                            subscription.isPlus
                                ? SubscriptionTier.plus
                                : SubscriptionTier.premium,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todayPlan == null
                        ? l10n.t('planner_smart_subtitle_empty')
                        : l10n.t(
                            'planner_smart_subtitle_today',
                            args: {
                              'occasion': formatDailyOccasionLabel(
                                  todayPlan.occasionType),
                              'weather':
                                  formatWeatherLabel(todayPlan.weatherType),
                            },
                          ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (todayPlan != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      todayPlan.explanation,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SmartPlannerScreen()),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      todayPlan == null
                          ? l10n.t('planner_open_smart_planner')
                          : l10n.t('planner_refine_today'),
                    ),
                  ),
                  if (!subscription.isPremium) ...[
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.t('planner_smart_title')),
                      subtitle: Text(l10n.t('planner_premium_note')),
                      trailing: const Icon(Icons.lock_outline_rounded),
                      onTap: () => showPremiumGateSheet(context,
                          featureName: l10n.t('smart_planner_title')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPlannerPicker(
    BuildContext context, {
    required int dayIndex,
  }) async {
    final l10n = context.l10n;
    final outfitProvider = context.read<OutfitProvider>();
    final options = <OutfitLook>[
      ...outfitProvider.outfits,
      ...outfitProvider.generatedLooks.where(
        (generated) => outfitProvider.findSavedById(generated.id) == null,
      ),
    ];

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('planner_no_outfits_subtitle'))),
      );
      return;
    }

    final selectedLook = await showModalBottomSheet<OutfitLook>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListView.separated(
          shrinkWrap: true,
          itemCount: options.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final look = options[index];
            return ListTile(
              title: Text(look.title),
              subtitle: Text(formatWardrobeTagLabel(look.occasion)),
              trailing: look.isGenerated
                  ? PremiumBadge(label: l10n.t('common_generated'))
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(look),
            );
          },
        );
      },
    );

    if (selectedLook == null || !context.mounted) {
      return;
    }

    final savedLook = outfitProvider.findSavedById(selectedLook.id) ??
        await outfitProvider.saveGeneratedLook(selectedLook);
    if (savedLook == null || !context.mounted) {
      return;
    }

    await context.read<PlannerProvider>().assignOutfit(
          dayIndex: dayIndex,
          outfitId: savedLook.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.t('planner_planned_for',
                args: {'day': formatWeekDayLabel(dayIndex)}))),
      );
    }
  }
}

class _WeekMetaCard extends StatelessWidget {
  const _WeekMetaCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accentDeep),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _WeekOverviewStrip extends StatelessWidget {
  const _WeekOverviewStrip({required this.planner});

  final PlannerProvider planner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final todayIndex = weekDayIndexForDate(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.t('planner_title'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final hasPlan = planner.outfitIdForDay(index) != null;
                final isToday = index == todayIndex;
                return Padding(
                  padding: EdgeInsets.only(right: index == 6 ? 0 : 10),
                  child: _WeekDayPill(
                    label: formatShortWeekDayLabel(index),
                    hasPlan: hasPlan,
                    isToday: isToday,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayPill extends StatelessWidget {
  const _WeekDayPill({
    required this.label,
    required this.hasPlan,
    required this.isToday,
  });

  final String label;
  final bool hasPlan;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.softSurface.withValues(alpha: 0.94)
            : hasPlan
                ? AppTheme.surfaceHighlight.withValues(alpha: 0.84)
                : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday
              ? AppTheme.accent
              : hasPlan
                  ? AppTheme.accent.withValues(alpha: 0.26)
                  : AppTheme.border,
          width: isToday ? 1.4 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.text,
                ),
          ),
          const SizedBox(height: 10),
          Icon(
            hasPlan ? Icons.check_circle_rounded : Icons.remove_rounded,
            size: 18,
            color: hasPlan ? AppTheme.accentDeep : AppTheme.textSoft,
          ),
        ],
      ),
    );
  }
}

class _PlannerDayCard extends StatelessWidget {
  const _PlannerDayCard({
    required this.dayIndex,
    required this.look,
    required this.items,
    required this.onAssign,
    this.onRemove,
  });

  final int dayIndex;
  final OutfitLook? look;
  final List<WardrobeItem> items;
  final VoidCallback onAssign;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPlan = look != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentDeep.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: hasPlan
                      ? AppTheme.softSurface.withValues(alpha: 0.76)
                      : AppTheme.surfaceHighlight.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  hasPlan
                      ? Icons.checkroom_rounded
                      : Icons.calendar_today_rounded,
                  color: hasPlan ? AppTheme.accentDeep : AppTheme.textSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatWeekDayLabel(dayIndex),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      hasPlan
                          ? l10n.t('planner_day_preview')
                          : l10n.t('planner_day_empty'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (hasPlan)
                TextButton(
                  onPressed: onRemove,
                  child: Text(l10n.t('common_remove')),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasPlan)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined,
                      color: AppTheme.textSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.t('planner_day_empty'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlannedLookPreview(items: items),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(look!.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        look!.notes,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssign,
                  icon: Icon(
                      hasPlan ? Icons.swap_horiz_rounded : Icons.add_rounded),
                  label: Text(hasPlan
                      ? l10n.t('common_change')
                      : l10n.t('planner_assign_outfit')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlannedLookPreview extends StatelessWidget {
  const _PlannedLookPreview({required this.items});

  final List<WardrobeItem> items;

  @override
  Widget build(BuildContext context) {
    final previewItems = items.take(3).toList();

    if (previewItems.isEmpty) {
      return const SizedBox(
        width: 92,
        height: 92,
        child: WardrobeImage(
          imageUrl: '',
          borderRadius: BorderRadius.all(Radius.circular(20)),
          iconSize: 24,
        ),
      );
    }

    return SizedBox(
      width: 96,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < previewItems.length; index++)
            Positioned(
              left: index * 18,
              child: Container(
                width: 54,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: WardrobeImage(
                  imageUrl: previewItems[index].imageUrl,
                  borderRadius: BorderRadius.circular(18),
                  iconSize: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
