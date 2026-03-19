import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_copy.dart';
import 'l10n/app_localizations.dart';
import 'providers/ai_stylist_provider.dart';
import 'providers/app_bootstrap_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/outfit_provider.dart';
import 'providers/planner_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/wardrobe_provider.dart';
import 'providers/weather_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/outfit_repository.dart';
import 'repositories/planner_repository.dart';
import 'repositories/preferences_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/wardrobe_repository.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/onboarding/city_selection_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/main_shell.dart';
import 'services/payment_service.dart';
import 'services/subscription_service.dart';
import 'theme/app_theme.dart';

class VirtualWardrobeApp extends StatelessWidget {
  const VirtualWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppBootstrapProvider()..initialize(),
        ),
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => WardrobeRepository()),
        Provider(create: (_) => OutfitRepository()),
        Provider(create: (_) => ProfileRepository()),
        Provider(create: (_) => PlannerRepository()),
        Provider(create: (_) => PreferencesRepository()),
        Provider(create: (_) => SubscriptionService()),
        Provider(create: (_) => PaymentService()),
        ChangeNotifierProvider(
          create: (context) => AppSettingsProvider(
            repository: context.read<PreferencesRepository>(),
          )..loadLanguage(),
        ),
        ChangeNotifierProxyProvider2<AppBootstrapProvider, AuthRepository,
            AuthProvider>(
          create: (context) => AuthProvider(
            bootstrapProvider: context.read<AppBootstrapProvider>(),
            repository: context.read<AuthRepository>(),
          ),
          update: (context, bootstrap, repository, provider) =>
              provider!..updateDependencies(bootstrap, repository),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, WardrobeRepository,
            WardrobeProvider>(
          create: (context) => WardrobeProvider(
            authProvider: context.read<AuthProvider>(),
            repository: context.read<WardrobeRepository>(),
          ),
          update: (context, auth, repository, provider) =>
              provider!..updateDependencies(auth, repository),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, OutfitRepository,
            OutfitProvider>(
          create: (context) => OutfitProvider(
            authProvider: context.read<AuthProvider>(),
            repository: context.read<OutfitRepository>(),
          ),
          update: (context, auth, repository, provider) =>
              provider!..updateDependencies(auth, repository),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, ProfileRepository,
            ProfileProvider>(
          create: (context) => ProfileProvider(
            authProvider: context.read<AuthProvider>(),
            repository: context.read<ProfileRepository>(),
          ),
          update: (context, auth, repository, provider) =>
              provider!..updateDependencies(auth, repository),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, PlannerRepository,
            PlannerProvider>(
          create: (context) => PlannerProvider(
            authProvider: context.read<AuthProvider>(),
            repository: context.read<PlannerRepository>(),
          ),
          update: (context, auth, repository, provider) =>
              provider!..updateDependencies(auth, repository),
        ),
        ChangeNotifierProxyProvider3<AuthProvider, PreferencesRepository,
            SubscriptionService, SubscriptionProvider>(
          create: (context) => SubscriptionProvider(
            authProvider: context.read<AuthProvider>(),
            repository: context.read<PreferencesRepository>(),
            service: context.read<SubscriptionService>(),
          ),
          update: (context, auth, repository, service, provider) =>
              provider!..updateDependencies(auth, repository, service),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, PreferencesRepository,
            WeatherProvider>(
          create: (context) => WeatherProvider(
            authProvider: context.read<AuthProvider>(),
            repository: context.read<PreferencesRepository>(),
          ),
          update: (context, auth, repository, provider) =>
              provider!..updateDependencies(auth, repository),
        ),
        ChangeNotifierProxyProvider6<
            AuthProvider,
            WardrobeProvider,
            ProfileProvider,
            WeatherProvider,
            SubscriptionProvider,
            PreferencesRepository,
            AiStylistProvider>(
          create: (context) => AiStylistProvider(
            authProvider: context.read<AuthProvider>(),
            wardrobeProvider: context.read<WardrobeProvider>(),
            profileProvider: context.read<ProfileProvider>(),
            weatherProvider: context.read<WeatherProvider>(),
            subscriptionProvider: context.read<SubscriptionProvider>(),
            repository: context.read<PreferencesRepository>(),
          ),
          update: (context, auth, wardrobe, profile, weather, subscription,
                  repository, provider) =>
              provider!
                ..updateDependencies(
                    auth, wardrobe, profile, weather, subscription, repository),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppCopy.appName,
            theme: AppTheme.lightTheme,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  static const _splashDuration = Duration(seconds: 2);

  bool _splashCompleted = false;
  bool _hasSeenOnboarding = false;
  bool _isLoadingEntryState = true;
  bool _entryStateRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryStateRequested) {
      return;
    }
    _entryStateRequested = true;
    _loadEntryState();
  }

  Future<void> _loadEntryState() async {
    final seen =
        await context.read<PreferencesRepository>().fetchHasSeenOnboarding();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasSeenOnboarding = seen;
      _isLoadingEntryState = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppBootstrapProvider, AuthProvider, ProfileProvider>(
      builder: (context, bootstrap, auth, profile, _) {
        final isInitializing = bootstrap.isInitializing || auth.isInitializing;
        final showSplash =
            !_splashCompleted || isInitializing || _isLoadingEntryState;

        if (showSplash) {
          return SplashScreen(
            duration: _splashDuration,
            onFinished: () {
              if (!mounted || _splashCompleted) return;
              setState(() => _splashCompleted = true);
            },
          );
        }

        if (auth.currentUser != null) {
          if ((profile.profile?.city ?? '').isEmpty) {
            return const CitySelectionScreen();
          }
          return const MainShell();
        }

        if (!_hasSeenOnboarding) {
          return OnboardingScreen(
            onFinish: () async {
              await context
                  .read<PreferencesRepository>()
                  .saveHasSeenOnboarding(true);
              if (!mounted) {
                return;
              }
              setState(() => _hasSeenOnboarding = true);
            },
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}
