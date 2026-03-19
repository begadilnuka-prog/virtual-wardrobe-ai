import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/styled_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onFinish,
    super.key,
  });

  final Future<void> Function() onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index == 3) {
      setState(() => _isSubmitting = true);
      await widget.onFinish();
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      return;
    }

    await _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      _OnboardingPageData(
        icon: Icons.checkroom_rounded,
        title: l10n.t('onboarding_page_wardrobe_title'),
        subtitle: l10n.t('onboarding_page_wardrobe_subtitle'),
      ),
      _OnboardingPageData(
        icon: Icons.cloud_rounded,
        title: l10n.t('onboarding_page_weather_title'),
        subtitle: l10n.t('onboarding_page_weather_subtitle'),
      ),
      _OnboardingPageData(
        icon: Icons.auto_awesome_rounded,
        title: l10n.t('onboarding_page_ai_title'),
        subtitle: l10n.t('onboarding_page_ai_subtitle'),
      ),
      _OnboardingPageData(
        icon: Icons.calendar_month_rounded,
        title: l10n.t('onboarding_page_planner_title'),
        subtitle: l10n.t('onboarding_page_planner_subtitle'),
      ),
    ];

    return PremiumScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              Row(
                children: [
                  const AppLogo(size: 34, showLabel: true),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            await widget.onFinish();
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                            }
                          },
                    child: Text(l10n.t('common_skip')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemCount: pages.length,
                  itemBuilder: (context, index) => _OnboardingPage(
                    data: pages[index],
                    isActive: index == _index,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (dotIndex) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: dotIndex == _index ? 28 : 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: dotIndex == _index
                          ? AppTheme.accent
                          : AppTheme.accentSoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              StyledButton(
                label: _isSubmitting
                    ? l10n.t('city_saving')
                    : _index == pages.length - 1
                        ? l10n.t('onboarding_start')
                        : l10n.t('common_next'),
                icon: _isSubmitting ? null : Icons.arrow_forward_rounded,
                onPressed: _isSubmitting ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.isActive,
  });

  final _OnboardingPageData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isActive ? 1 : 0.72,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF3F8FF),
                    Color(0xFFE6F0FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentDeep.withValues(alpha: 0.06),
                    blurRadius: 26,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                data.icon,
                size: 48,
                color: AppTheme.accentDeep,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
