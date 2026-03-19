import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/styled_button.dart';
import 'auth_screen_scaffold.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScreenScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeaderCard(
            eyebrow: l10n.t('welcome_tagline'),
            title: l10n.t('welcome_title'),
            subtitle: l10n.t('welcome_subline'),
            centered: true,
          ),
          const SizedBox(height: 24),
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _FeaturePill(
                  icon: Icons.checkroom_rounded,
                  label: l10n.t('nav_wardrobe'),
                ),
                _FeaturePill(
                  icon: Icons.cloud_rounded,
                  label: l10n.t('nav_weather'),
                ),
                _FeaturePill(
                  icon: Icons.auto_awesome_rounded,
                  label: l10n.t('ai_title'),
                ),
                _FeaturePill(
                  icon: Icons.calendar_month_rounded,
                  label: l10n.t('nav_planner'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          StyledButton(
            label: l10n.t('welcome_create_account'),
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          StyledButton(
            label: l10n.t('welcome_login'),
            secondary: true,
            icon: Icons.login_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
