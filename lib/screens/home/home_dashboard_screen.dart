import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/outfit_look.dart';
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
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/common/premium_gate_sheet.dart';
import '../../widgets/outfit_card.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/wardrobe_image.dart';
import '../ai/ai_stylist_screen.dart';
import '../generate/outfit_generator_screen.dart';
import '../weather/weather_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    required this.onNavigate,
    super.key,
  });

  final ValueChanged<int> onNavigate;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final StylingEngineService _stylingEngineService = StylingEngineService();
  final WeatherService _weatherService = WeatherService();
  String? _lastWeatherCity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final city = context.read<ProfileProvider>().profile?.city.trim() ?? '';
    if (_lastWeatherCity != city) {
      _lastWeatherCity = city;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<WeatherProvider>().loadWeather(city: city);
        }
      });
    }
  }

  Future<void> _refreshDashboard(String city) async {
    final wardrobeProvider = context.read<WardrobeProvider>();
    final outfitProvider = context.read<OutfitProvider>();
    final plannerProvider = context.read<PlannerProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final weatherProvider = context.read<WeatherProvider>();

    await wardrobeProvider.loadItems();
    await outfitProvider.loadOutfits();
    await plannerProvider.loadPlans();
    await profileProvider.loadProfile();
    await subscriptionProvider.loadState();
    await weatherProvider.refresh(city: city);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.watch<ProfileProvider>().profile;
    final wardrobe = context.watch<WardrobeProvider>();
    final outfits = context.watch<OutfitProvider>();
    final planner = context.watch<PlannerProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final snapshot = weatherProvider.snapshot;
    final todayPlan = planner.todayPlan;
    final city = profile?.city.trim() ?? '';
    final profileName = profile?.name.trim() ?? '';
    final nameParts = profileName.isEmpty
        ? const <String>[]
        : profileName
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
    final firstName =
        nameParts.isEmpty ? l10n.t('common_friend') : nameParts.first;
    final heroGreeting = '${_greetingForHour()} $firstName'.trim();

    OutfitLook? todayLook;
    String? explanation;
    if (profile != null && snapshot != null && wardrobe.allItems.isNotEmpty) {
      if (todayPlan != null) {
        final smart = _stylingEngineService.generateSmartRecommendation(
          userId: profile.userId,
          wardrobe: wardrobe.allItems,
          occasion: todayPlan.occasionType,
          weather: snapshot.condition,
          premium: subscription.isPremium,
          plus: subscription.isPlus,
          profile: profile,
          date: todayPlan.date,
        );
        todayLook = smart?.look.copyWith(
            title: l10n.t('home_today_outfit_title'), notes: smart.explanation);
        explanation = smart?.explanation;
      } else {
        final weatherLook = _stylingEngineService.buildWeatherLook(
          userId: profile.userId,
          wardrobe: wardrobe.allItems,
          weather: snapshot.condition,
          premium: subscription.isPremium,
          profile: profile,
        );
        explanation = _weatherService.buildGuidance(snapshot: snapshot);
        todayLook = weatherLook?.copyWith(
          title: l10n.t('home_today_outfit_title'),
          occasion: l10n.t('nav_weather'),
          notes: explanation,
        );
      }
    }

    final todayItems = todayLook == null
        ? const <WardrobeItem>[]
        : wardrobe.allItems
            .where((item) => todayLook!.itemIds.contains(item.id))
            .toList();

    return PremiumScaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const AppLogo(size: 28, showLabel: true),
        actions: [
          IconButton(
            tooltip: l10n.t('common_refresh'),
            onPressed: () => _refreshDashboard(city),
            icon: const Icon(Icons.refresh_rounded),
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
      child: RefreshIndicator(
        onRefresh: () => _refreshDashboard(city),
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEEF6FF),
                    Color(0xFFF9FBFF),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final textTheme = Theme.of(context).textTheme;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: compact ? 64 : 72,
                            height: compact ? 64 : 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: AppLogo(size: compact ? 54 : 60),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'I Closet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: compact ? 22 : 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.accentDeep,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.t('brand_personal_ai_stylist'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSoft,
                                    fontWeight: FontWeight.w600,
                                    height: 1.32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeaderInfoPill(
                            icon: subscription.isPremium
                                ? Icons.workspace_premium_rounded
                                : Icons.stars_rounded,
                            label: subscription.isPremium
                                ? subscription.tierLabel
                                : l10n.t('common_free_plan'),
                          ),
                          if (todayPlan != null)
                            _HeaderInfoPill(
                              icon: Icons.calendar_month_rounded,
                              label: formatDailyOccasionLabel(
                                  todayPlan.occasionType),
                            ),
                          _HeaderInfoPill(
                            icon: Icons.location_on_outlined,
                            label: city.isEmpty
                                ? l10n.t('home_weather_no_city')
                                : city,
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 18 : 20),
                      Text(
                        heroGreeting,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: compact ? 24 : 28,
                          height: 1.08,
                          letterSpacing: -0.35,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentDeep,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: compact ? constraints.maxWidth : 420,
                        ),
                        child: Text(
                          l10n.t('home_subtitle'),
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSoft,
                            height: 1.38,
                            fontSize: compact ? 15 : 16,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final itemWidth = width < 380 ? width : (width - 24) / 3;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _DashboardStatCard(
                        label: l10n.t('home_stat_wardrobe'),
                        value: '${wardrobe.allItems.length}',
                        icon: Icons.checkroom_rounded,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _DashboardStatCard(
                        label: l10n.t('home_stat_saved_looks'),
                        value: '${outfits.outfits.length}',
                        icon: Icons.auto_awesome_mosaic_rounded,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _DashboardStatCard(
                        label: l10n.t('home_stat_planned'),
                        value: '${planner.plans.length}',
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: l10n.t('home_today_title'),
              subtitle: l10n.t('home_today_subtitle'),
            ),
            const SizedBox(height: 14),
            _HomeWeatherCard(
              city: city,
              snapshotCondition: snapshot?.condition,
              temperature: snapshot?.temperatureCelsius,
              updatedAt: snapshot?.updatedAt,
              styleSuggestion: snapshot?.styleSuggestion,
              onRefresh: () =>
                  context.read<WeatherProvider>().refresh(city: city),
            ),
            const SizedBox(height: 18),
            if (todayLook != null)
              OutfitCard(
                outfit: todayLook,
                items: todayItems,
                onTap: () => widget.onNavigate(2),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.t('home_today_outfit_title'),
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(
                        wardrobe.allItems.isEmpty
                            ? l10n.t('home_today_outfit_empty')
                            : l10n.t('home_today_outfit_loading'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            if (explanation != null) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(explanation),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SectionHeader(
              title: l10n.t('home_quick_actions_title'),
              subtitle: l10n.t('home_quick_actions_subtitle'),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionCard(
                  icon: Icons.checkroom_rounded,
                  title: l10n.t('home_action_wardrobe_title'),
                  subtitle: l10n.t('home_action_wardrobe_subtitle'),
                  onTap: () => widget.onNavigate(1),
                ),
                _QuickActionCard(
                  icon: Icons.auto_awesome_mosaic_rounded,
                  title: l10n.t('home_action_generate_title'),
                  subtitle: l10n.t('home_action_generate_subtitle'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const OutfitGeneratorScreen()),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.cloud_rounded,
                  title: l10n.t('home_action_weather_title'),
                  subtitle: l10n.t('home_action_weather_subtitle'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => WeatherScreen()),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.calendar_month_rounded,
                  title: l10n.t('home_action_planner_title'),
                  subtitle: l10n.t('home_action_planner_subtitle'),
                  onTap: () => widget.onNavigate(2),
                ),
              ],
            ),
            if (wardrobe.favoriteItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionHeader(
                title: l10n.t('home_closet_highlights_title'),
                subtitle: l10n.t('home_closet_highlights_subtitle'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: wardrobe.favoriteItems.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = wardrobe.favoriteItems[index];
                    return SizedBox(
                      width: 150,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: WardrobeImage(
                                imageUrl: item.imageUrl,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(30)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatWardrobeItemName(item.name),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(formatColorLabel(item.color),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (!subscription.isPremium) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumBadge(label: l10n.t('home_upgrade_badge')),
                      const SizedBox(height: 12),
                      Text(l10n.t('home_upgrade_title'),
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        l10n.t('home_upgrade_subtitle'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => showPremiumGateSheet(
                          context,
                          featureName: l10n.t('ai_unlimited_feature'),
                        ),
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: Text(l10n.t('home_upgrade_cta')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _greetingForHour() {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.t('home_greeting_morning', args: {'name': ''}).replaceAll(
          RegExp(r',?\s*$'), '');
    }
    if (hour < 18) {
      return l10n.t('home_greeting_afternoon', args: {'name': ''}).replaceAll(
          RegExp(r',?\s*$'), '');
    }
    return l10n.t('home_greeting_evening', args: {'name': ''}).replaceAll(
        RegExp(r',?\s*$'), '');
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accentDeep),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _HomeWeatherCard extends StatelessWidget {
  const _HomeWeatherCard({
    required this.city,
    required this.snapshotCondition,
    required this.temperature,
    required this.updatedAt,
    required this.styleSuggestion,
    required this.onRefresh,
  });

  final String city;
  final WeatherCondition? snapshotCondition;
  final int? temperature;
  final DateTime? updatedAt;
  final String? styleSuggestion;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasCity = city.trim().isNotEmpty;
    final updatedLabel = updatedAt == null
        ? null
        : l10n.t('home_weather_updated',
            args: {'time': formatTimeOnly(updatedAt!)});

    final headline = hasCity
        ? '$city — ${snapshotCondition != null ? formatWeatherLabel(snapshotCondition!) : l10n.t('home_weather_loading')}${temperature != null ? ', $temperature°C' : ''}'
        : l10n.t('home_weather_no_city');

    final recommendation = hasCity
        ? (styleSuggestion ?? l10n.t('home_weather_summary_fallback'))
        : l10n.t('home_weather_set_city');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.softSurface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _iconForCondition(snapshotCondition),
                    color: AppTheme.accentDeep,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recommendation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (updatedLabel != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          updatedLabel,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
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
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.t('common_refresh')),
                  ),
                ),
                if (!hasCity) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => WeatherScreen()),
                      );
                    },
                    child: Text(l10n.t('common_change')),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCondition(WeatherCondition? condition) {
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
      case null:
        return Icons.cloud_queue_rounded;
    }
  }
}

class _HeaderInfoPill extends StatelessWidget {
  const _HeaderInfoPill({
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
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.accentDeep),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 52) / 2;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppTheme.accentDeep),
                ),
                const SizedBox(height: 14),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
