import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/outfit_look.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../providers/weather_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/common/premium_gate_sheet.dart';
import '../../widgets/common/usage_meter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/outfit_card.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/section_header.dart';
import '../ai/ai_stylist_screen.dart';
import '../looks/saved_looks_screen.dart';

class OutfitGeneratorScreen extends StatefulWidget {
  const OutfitGeneratorScreen({super.key});

  @override
  State<OutfitGeneratorScreen> createState() => _OutfitGeneratorScreenState();
}

class _OutfitGeneratorScreenState extends State<OutfitGeneratorScreen> {
  DailyOccasion _occasion = AppConstants.generatorOccasionValues.first;

  Future<void> _generateLooks(BuildContext context) async {
    final l10n = context.l10n;
    final wardrobe = context.read<WardrobeProvider>();
    final subscription = context.read<SubscriptionProvider>();
    final outfitProvider = context.read<OutfitProvider>();
    final profile = context.read<ProfileProvider>().profile;
    final weather = context.read<WeatherProvider>().snapshot?.condition ??
        WeatherCondition.cloudy;

    if (!wardrobe.hasEnoughForOutfits) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('generate_add_items_first'))),
      );
      return;
    }

    final allowed = await subscription.consumeOutfitGeneration();
    if (!allowed) {
      if (context.mounted) {
        await showPremiumGateSheet(
          context,
          featureName: l10n.t('generate_title'),
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    await outfitProvider.generateLooks(
      wardrobe: wardrobe.allItems,
      occasion: formatDailyOccasionLabel(_occasion),
      weather: weather,
      premium: subscription.isPremium,
      occasionType: _occasion,
      profile: profile,
    );
  }

  Future<void> _saveToPlanner(BuildContext context, OutfitLook look) async {
    final l10n = context.l10n;
    final outfitProvider = context.read<OutfitProvider>();
    final plannerProvider = context.read<PlannerProvider>();

    final savedLook = await outfitProvider.saveGeneratedLook(look);
    if (savedLook == null || !context.mounted) {
      return;
    }

    final selectedDay = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListView.separated(
          shrinkWrap: true,
          itemCount: 7,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(formatWeekDayLabel(index)),
              onTap: () => Navigator.of(sheetContext).pop(index),
            );
          },
        );
      },
    );

    if (selectedDay == null || !context.mounted) {
      return;
    }

    await plannerProvider.assignOutfit(
        dayIndex: selectedDay, outfitId: savedLook.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.t(
              'generate_planned_for',
              args: {'day': formatWeekDayLabel(selectedDay)},
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wardrobe = context.watch<WardrobeProvider>();
    final outfitProvider = context.watch<OutfitProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final weather = context.watch<WeatherProvider>().snapshot;

    final progress = subscription.isPremium
        ? 0.0
        : 1 -
            (subscription.remainingOutfitGenerations /
                AppConstants.freeDailyOutfitLimit);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text(l10n.t('generate_title')),
        actions: [
          IconButton(
            tooltip: l10n.t('generate_saved_looks'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedLooksScreen()),
              );
            },
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          IconButton.filledTonal(
            tooltip: l10n.t('ai_title'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiStylistScreen()),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded),
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
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEEF3FC),
                  Color(0xFFE5ECF8),
                  Color(0xFFD7E3F4),
                ],
              ),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentDeep.withValues(alpha: 0.05),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PremiumBadge(label: l10n.t('generate_ai_badge')),
                    const Spacer(),
                    Text(
                      weather == null
                          ? l10n.t('generate_weather_none')
                          : formatWeatherLabel(weather.condition),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.t('generate_headline'),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(
                  l10n.t('generate_subtitle'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.text),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GeneratorInfoChip(
                      icon: Icons.checkroom_outlined,
                      label: l10n.t('outfit_card_pieces',
                          args: {'count': '${wardrobe.allItems.length}'}),
                    ),
                    _GeneratorInfoChip(
                      icon: Icons.style_outlined,
                      label: formatDailyOccasionLabel(_occasion),
                    ),
                    _GeneratorInfoChip(
                      icon: Icons.workspace_premium_outlined,
                      label: subscription.tierLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: outfitProvider.isGenerating
                      ? null
                      : () => _generateLooks(context),
                  icon: Icon(outfitProvider.isGenerating
                      ? Icons.hourglass_top_rounded
                      : Icons.auto_awesome_rounded),
                  label: Text(outfitProvider.isGenerating
                      ? l10n.t('generate_generating')
                      : l10n.t('generate_generate_button')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          UsageMeter(
            title: subscription.isPremium
                ? l10n.t('generate_usage_title_premium',
                    args: {'plan': subscription.tierLabel})
                : l10n.t('generate_usage_title_free'),
            subtitle: subscription.isPremium
                ? l10n.t('generate_usage_subtitle_premium')
                : friendlyRemainingCount(
                    subscription.remainingOutfitGenerations, 'generation'),
            progress: progress,
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.t('generate_set_mood_title'),
                    subtitle: l10n.t('generate_set_mood_subtitle'),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        AppConstants.generatorOccasionValues.map((occasion) {
                      return ChoiceChip(
                        label: Text(formatDailyOccasionLabel(occasion)),
                        selected: _occasion == occasion,
                        onSelected: (_) => setState(() => _occasion = occasion),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!subscription.isPremium)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: PremiumBadge(label: l10n.t('ai_premium_badge')),
                title: Text(l10n.t('generate_locked_title')),
                subtitle: Text(l10n.t('generate_locked_subtitle')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showPremiumGateSheet(context,
                    featureName: l10n.t('generate_locked_title')),
              ),
            ),
          if (!subscription.isPremium) const SizedBox(height: 20),
          if (wardrobe.allItems.isEmpty)
            EmptyState(
              icon: Icons.checkroom_outlined,
              title: l10n.t('generate_empty_title'),
              subtitle: l10n.t('generate_empty_subtitle'),
            )
          else if (outfitProvider.generatedLooks.isEmpty)
            EmptyState(
              icon: Icons.auto_awesome_mosaic_outlined,
              title: l10n.t('generate_none_title'),
              subtitle: l10n.t('generate_none_subtitle'),
            )
          else ...[
            SectionHeader(
              title: l10n.t('generate_results_title'),
              subtitle: l10n.t('generate_results_subtitle'),
            ),
            const SizedBox(height: 14),
            ...outfitProvider.generatedLooks.map(
              (look) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: OutfitCard(
                  outfit: look,
                  items: wardrobe.allItems
                      .where((item) => look.itemIds.contains(item.id))
                      .toList(),
                  footer: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await context
                                .read<OutfitProvider>()
                                .saveGeneratedLook(look);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(l10n.t('generate_saved_success')),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: Text(l10n.t('generate_save_look')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _saveToPlanner(context, look),
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text(l10n.t('generate_plan_this')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GeneratorInfoChip extends StatelessWidget {
  const _GeneratorInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.accentDeep),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
