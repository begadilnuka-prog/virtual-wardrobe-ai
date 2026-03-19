import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_assets.dart';
import '../../core/app_constants.dart';
import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/daily_plan.dart';
import '../../models/outfit_look.dart';
import '../../models/smart_outfit_recommendation.dart';
import '../../models/wardrobe_item.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/styling_engine_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/marketplace_product_card.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/common/premium_gate_sheet.dart';
import '../../widgets/common/usage_meter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/outfit_card.dart';
import '../../widgets/premium_scaffold.dart';

class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  final StylingEngineService _stylingEngineService = StylingEngineService();
  final WeatherService _weatherService = WeatherService();
  DailyOccasion _selectedOccasion = DailyOccasion.college;
  SmartOutfitRecommendation? _recommendation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final todayPlan = context.read<PlannerProvider>().todayPlan;
    if (todayPlan != null && _recommendation == null) {
      _selectedOccasion = todayPlan.occasionType;
      _recommendation = _recommendationFromPlan(todayPlan);
    }
  }

  Future<void> _generateSmartOutfit() async {
    final l10n = context.l10n;
    final wardrobe = context.read<WardrobeProvider>();
    final subscription = context.read<SubscriptionProvider>();
    final profile = context.read<ProfileProvider>().profile;
    final planner = context.read<PlannerProvider>();
    final weather = context.read<WeatherProvider>().snapshot?.condition ??
        WeatherCondition.cloudy;
    final userId = profile?.userId;

    if (userId == null || wardrobe.allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('generate_add_items_first'))),
      );
      return;
    }

    final allowed = await subscription.consumeSmartPlanRequest();
    if (!allowed) {
      if (!mounted) {
        return;
      }
      await showPremiumGateSheet(
        context,
        featureName: l10n.t('smart_planner_title'),
      );
      return;
    }

    final recommendation = _stylingEngineService.generateSmartRecommendation(
      userId: userId,
      wardrobe: wardrobe.allItems,
      occasion: _selectedOccasion,
      weather: weather,
      premium: subscription.isPremium,
      plus: subscription.isPlus,
      profile: profile,
    );

    if (recommendation == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final existingId = planner.todayPlan?.id;
    await planner.saveDailyPlan(
      recommendation.toDailyPlan(userId: userId, existingId: existingId),
    );

    if (!mounted) {
      return;
    }
    setState(() => _recommendation = recommendation);
  }

  Future<void> _saveToWeeklyPlanner() async {
    final l10n = context.l10n;
    final recommendation = _recommendation;
    if (recommendation == null) {
      return;
    }

    final outfitProvider = context.read<OutfitProvider>();
    final planner = context.read<PlannerProvider>();
    final todayIndex = weekDayIndexForDate(recommendation.date);

    final existingDailyPlan = planner.todayPlan;
    OutfitLook? savedLook;
    if (existingDailyPlan?.savedOutfitId != null) {
      savedLook =
          outfitProvider.findSavedById(existingDailyPlan!.savedOutfitId!);
    }
    savedLook ??= await outfitProvider.saveOutfit(
      title: recommendation.look.title,
      itemIds: recommendation.look.itemIds,
      occasion: recommendation.look.occasion,
      style: recommendation.look.style,
      notes: recommendation.explanation,
      tags: recommendation.look.tags,
      weatherContext: recommendation.look.weatherContext,
      isPremium: recommendation.look.isPremium,
    );

    if (savedLook == null || !mounted) {
      return;
    }

    await planner.assignOutfit(dayIndex: todayIndex, outfitId: savedLook.id);
    await planner.attachSavedOutfitToDate(
      date: recommendation.date,
      outfitId: savedLook.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.t(
              'smart_planner_saved_success',
              args: {'day': formatWeekDayLabel(todayIndex)},
            ),
          ),
        ),
      );
    }
  }

  SmartOutfitRecommendation _recommendationFromPlan(DailyPlan plan) {
    final outfit = OutfitLook(
      id: plan.savedOutfitId ?? plan.id,
      userId: plan.userId,
      title: plan.title,
      itemIds: plan.recommendedItemIds,
      occasion: formatDailyOccasionLabel(plan.occasionType),
      style: plan.styleLabel,
      notes: plan.explanation,
      tags: plan.tags,
      weatherContext: formatWeatherLabel(plan.weatherType),
      createdAt: plan.createdAt,
      isGenerated: true,
      isPremium: true,
    );

    return SmartOutfitRecommendation(
      look: outfit,
      explanation: plan.explanation,
      date: plan.date,
      occasion: plan.occasionType,
      weather: plan.weatherType,
      marketplaceSuggestions: plan.marketplaceSuggestions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subscription = context.watch<SubscriptionProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final wardrobe = context.watch<WardrobeProvider>();
    final snapshot = weatherProvider.snapshot;
    final city = context.watch<ProfileProvider>().profile?.city.trim() ?? '';
    final currentRecommendation = _recommendation;
    final recommendedItems = currentRecommendation == null
        ? <WardrobeItem>[]
        : wardrobe.allItems
            .where(
                (item) => currentRecommendation.look.itemIds.contains(item.id))
            .toList();
    final progress = subscription.isPremium
        ? 0.0
        : 1 -
            (subscription.remainingSmartPlans /
                AppConstants.freeDailySmartPlanLimit);

    return PremiumScaffold(
      appBar: AppBar(title: Text(l10n.t('smart_planner_title'))),
      child: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          UsageMeter(
            title: subscription.isPremium
                ? l10n.t('smart_planner_usage_premium',
                    args: {'plan': subscription.tierLabel})
                : l10n.t('smart_planner_usage_free'),
            subtitle: subscription.isPremium
                ? subscription.isPlus
                    ? l10n.t('smart_planner_usage_plus')
                    : l10n.t('smart_planner_usage_premium_only')
                : friendlyRemainingCount(
                    subscription.remainingSmartPlans, 'smart plan'),
            progress: progress,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEEF3FC),
                  Color(0xFFE5ECF8),
                  Color(0xFFD9E3F4),
                ],
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: snapshot == null
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final refreshButton = FilledButton.tonalIcon(
                            onPressed: () => context
                                .read<WeatherProvider>()
                                .refresh(city: city),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.t('smart_planner_refresh')),
                          );

                          if (constraints.maxWidth < 360) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('smart_planner_weather_title'),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                refreshButton,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.t('smart_planner_weather_title'),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(width: 12),
                              refreshButton,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${formatWeatherLabel(snapshot.condition)} • ${snapshot.temperatureCelsius}°C',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.74),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.t(
                                'weather_feels_like',
                                args: {'value': '${snapshot.feelsLikeCelsius}'},
                              ),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        city.isEmpty
                            ? l10n.t('smart_planner_mock_weather')
                            : l10n.t(
                                'smart_planner_updated_city',
                                args: {
                                  'city': city,
                                  'time': formatTimeOnly(snapshot.updatedAt),
                                },
                              ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                          _weatherService
                              .summaryForCondition(snapshot.condition),
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      Text(
                        _weatherService.styleSuggestionForCondition(
                          snapshot.condition,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          Text(l10n.t('smart_planner_plan_title'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.dailyPlanOccasions.map((occasion) {
              return ChoiceChip(
                label: Text(formatDailyOccasionLabel(occasion)),
                selected: _selectedOccasion == occasion,
                onSelected: (_) => setState(() => _selectedOccasion = occasion),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _generateSmartOutfit,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l10n.t('smart_planner_generate_button')),
          ),
          const SizedBox(height: 20),
          if (currentRecommendation == null)
            EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: l10n.t('smart_planner_empty_title'),
              subtitle: l10n.t('smart_planner_empty_subtitle'),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutfitCard(
                  outfit: currentRecommendation.look,
                  items: recommendedItems,
                  footer: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveToWeeklyPlanner,
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text(l10n.t('smart_planner_save_weekly')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PremiumBadge(label: l10n.t('smart_planner_why')),
                            const Spacer(),
                            Text(
                              '${formatDailyOccasionLabel(currentRecommendation.occasion)} • ${formatWeatherLabel(currentRecommendation.weather)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(currentRecommendation.explanation),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (subscription.isPlus &&
                    currentRecommendation.marketplaceSuggestions.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              PremiumBadge(
                                label: l10n.t('smart_planner_shop_title'),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                  formatSubscriptionTierLabel(
                                      SubscriptionTier.plus),
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.t('smart_planner_shop_subtitle'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 332,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: currentRecommendation
                                  .marketplaceSuggestions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) =>
                                  MarketplaceProductCard(
                                item: currentRecommendation
                                    .marketplaceSuggestions[index],
                                badgeLabel:
                                    l10n.t('smart_planner_partner_badge'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!subscription.isPlus)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              PremiumBadge(
                                label: l10n.t('smart_planner_plus_preview'),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatSubscriptionTierLabel(
                                    SubscriptionTier.plus),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.t('smart_planner_plus_subtitle'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 332,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 2,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) =>
                                  MarketplaceProductCard(
                                item: AppAssets.partnerPreviewItems[index],
                                locked: true,
                                badgeLabel:
                                    l10n.t('smart_planner_plus_preview'),
                                onTap: () => showPremiumGateSheet(
                                  context,
                                  featureName:
                                      l10n.t('smart_planner_shop_title'),
                                  requiredTier: SubscriptionTier.plus,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
