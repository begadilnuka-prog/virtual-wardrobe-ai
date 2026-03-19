import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/outfit_look.dart';
import '../../models/wardrobe_item.dart';
import '../../models/weather_snapshot.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/styling_engine_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/common/premium_gate_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/outfit_card.dart';
import '../../widgets/premium_scaffold.dart';
import '../ai/ai_stylist_screen.dart';
import '../planner/smart_planner_screen.dart';

class WeatherScreen extends StatefulWidget {
  WeatherScreen({super.key})
      : _stylingEngineService = StylingEngineService(),
        _weatherService = WeatherService();

  final StylingEngineService _stylingEngineService;
  final WeatherService _weatherService;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String? _lastCity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final city = context.read<ProfileProvider>().profile?.city.trim() ?? '';
    if (_lastCity != city) {
      _lastCity = city;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<WeatherProvider>().loadWeather(city: city);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weatherProvider = context.watch<WeatherProvider>();
    final wardrobe = context.watch<WardrobeProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final planner = context.watch<PlannerProvider>();
    final snapshot = weatherProvider.snapshot;
    final city = profile?.city.trim() ?? '';
    final todayPlan = planner.todayPlan;

    OutfitLook? recommendedLook;
    String? explanation;
    if (snapshot != null && profile != null && wardrobe.allItems.isNotEmpty) {
      if (todayPlan != null) {
        final smart = widget._stylingEngineService.generateSmartRecommendation(
          userId: profile.userId,
          wardrobe: wardrobe.allItems,
          occasion: todayPlan.occasionType,
          weather: snapshot.condition,
          premium: subscription.isPremium,
          plus: subscription.isPlus,
          profile: profile,
          date: todayPlan.date,
        );
        recommendedLook = smart?.look.copyWith(
          title: l10n.t('home_today_outfit_title'),
          notes: smart.explanation,
        );
        explanation = smart?.explanation ??
            widget._weatherService.buildGuidance(
              snapshot: snapshot,
              occasion: todayPlan.occasionType,
            );
      } else {
        final weatherLook = widget._stylingEngineService.buildWeatherLook(
          userId: profile.userId,
          wardrobe: wardrobe.allItems,
          weather: snapshot.condition,
          premium: subscription.isPremium,
          profile: profile,
        );
        explanation = widget._weatherService.buildGuidance(snapshot: snapshot);
        recommendedLook = weatherLook?.copyWith(
          title: l10n.t('home_today_outfit_title'),
          notes: explanation,
        );
      }
    }

    final items = recommendedLook == null
        ? <WardrobeItem>[]
        : wardrobe.allItems
            .where((item) => recommendedLook!.itemIds.contains(item.id))
            .toList();

    return PremiumScaffold(
      appBar: AppBar(
        title: const AppLogo(size: 24, showLabel: true),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: l10n.t('weather_refresh'),
            onPressed: () =>
                context.read<WeatherProvider>().refresh(city: city),
            icon: weatherProvider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
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
          _WeatherSummaryCard(
            snapshot: snapshot,
            city: city,
            isLoading: weatherProvider.isLoading,
            onRefresh: () =>
                context.read<WeatherProvider>().refresh(city: city),
          ),
          const SizedBox(height: 18),
          if (wardrobe.allItems.isEmpty)
            EmptyState(
              icon: Icons.cloud_outlined,
              title: l10n.t('weather_empty_title'),
              subtitle: l10n.t('weather_empty_subtitle'),
            )
          else if (recommendedLook == null)
            EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: l10n.t('weather_loading_title'),
              subtitle: l10n.t('weather_loading_subtitle'),
            )
          else
            OutfitCard(
              outfit: recommendedLook,
              items: items,
              footer: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<OutfitProvider>().saveOutfit(
                              title: recommendedLook!.title,
                              itemIds: recommendedLook.itemIds,
                              occasion: recommendedLook.occasion,
                              style: recommendedLook.style,
                              notes: recommendedLook.notes,
                              tags: recommendedLook.tags,
                              weatherContext: recommendedLook.weatherContext,
                              isPremium: recommendedLook.isPremium,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.t('weather_saved_outfit'))),
                          );
                        }
                      },
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: Text(l10n.t('weather_save_outfit')),
                    ),
                  ),
                ],
              ),
            ),
          if (snapshot != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PremiumBadge(label: l10n.t('weather_why')),
                        const Spacer(),
                        if (todayPlan != null)
                          Text(
                            formatDailyOccasionLabel(todayPlan.occasionType),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      explanation ??
                          widget._weatherService
                              .buildGuidance(snapshot: snapshot),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (subscription.isPremium)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumBadge(
                        label: subscription.isPlus
                            ? formatSubscriptionTierLabel(SubscriptionTier.plus)
                            : l10n.t('outfit_badge_premium')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        todayPlan == null
                            ? l10n.t('weather_premium_message')
                            : l10n.t('weather_plus_message'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: PremiumBadge(label: l10n.t('outfit_badge_premium')),
                title: Text(l10n.t('weather_smarter_title')),
                subtitle: Text(l10n.t('weather_smarter_subtitle')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showPremiumGateSheet(context,
                    featureName: l10n.t('weather_gate_feature')),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SmartPlannerScreen()),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l10n.t('weather_plan_cta')),
          ),
        ],
      ),
    );
  }
}

class _WeatherSummaryCard extends StatelessWidget {
  const _WeatherSummaryCard({
    required this.snapshot,
    required this.city,
    required this.isLoading,
    required this.onRefresh,
  });

  final WeatherSnapshot? snapshot;
  final String city;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentSnapshot = snapshot;
    final weatherService = WeatherService();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF3F5F7),
            Color(0xFFE9EDF2),
            Color(0xFFE4E7EE),
          ],
        ),
        border: Border.all(color: AppTheme.border),
      ),
      child: currentSnapshot == null
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final refreshButton = FilledButton.tonalIcon(
                      onPressed: isLoading ? null : onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.t('common_refresh')),
                    );

                    final summary = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.74),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            _iconForCondition(currentSnapshot.condition),
                            color: AppTheme.accentDeep,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('common_today'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formatWeatherLabel(currentSnapshot.condition)}, ${currentSnapshot.temperatureCelsius}°C',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 380) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          summary,
                          const SizedBox(height: 14),
                          refreshButton,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 12),
                        refreshButton,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  city.isEmpty
                      ? (currentSnapshot.city.isEmpty
                          ? l10n.t('weather_mock_local')
                          : currentSnapshot.city)
                      : city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                    weatherService
                        .summaryForCondition(currentSnapshot.condition),
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(
                      label: l10n.t('weather_feels_like', args: {
                        'value': '${currentSnapshot.feelsLikeCelsius}'
                      }),
                    ),
                    _InfoPill(
                        label: l10n.t('weather_wind',
                            args: {'value': '${currentSnapshot.windKph}'})),
                    _InfoPill(
                      label: l10n.t('weather_updated', args: {
                        'time': formatTimeOnly(currentSnapshot.updatedAt)
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  weatherService
                      .styleSuggestionForCondition(currentSnapshot.condition),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
    );
  }

  IconData _iconForCondition(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.cloudy:
        return Icons.cloud_rounded;
      case WeatherCondition.rainy:
        return Icons.grain_rounded;
      case WeatherCondition.cold:
        return Icons.ac_unit_rounded;
      case WeatherCondition.hot:
        return Icons.thermostat_rounded;
      case WeatherCondition.windy:
        return Icons.air_rounded;
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
