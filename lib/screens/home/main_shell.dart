import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../providers/weather_provider.dart';
import '../../theme/app_theme.dart';
import 'home_dashboard_screen.dart';
import '../planner/planner_screen.dart';
import '../profile/profile_screen.dart';
import '../wardrobe/wardrobe_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeProvider>().loadItems();
      context.read<OutfitProvider>().loadOutfits();
      context.read<ProfileProvider>().loadProfile();
      context.read<SubscriptionProvider>().loadState();
      context.read<PlannerProvider>().loadPlans();
      final city = context.read<ProfileProvider>().profile?.city.trim() ?? '';
      context.read<WeatherProvider>().loadWeather(city: city);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      HomeDashboardScreen(
          onNavigate: (value) => setState(() => _index = value)),
      const WardrobeScreen(),
      const PlannerScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: AppTheme.border.withValues(alpha: 0.7))),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.t('nav_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.checkroom_outlined),
              selectedIcon: const Icon(Icons.checkroom_rounded),
              label: l10n.t('nav_wardrobe'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month_rounded),
              label: l10n.t('nav_planner'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: l10n.t('nav_profile'),
            ),
          ],
        ),
      ),
    );
  }
}
