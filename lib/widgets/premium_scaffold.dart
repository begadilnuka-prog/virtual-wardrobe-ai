import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
    super.key,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5F8FF),
              Color(0xFFEFF4FB),
            ],
          ),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.65)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentSoft.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -50,
              top: 160,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.premium.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: -50,
              bottom: 80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: -70,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.softSurface.withValues(alpha: 0.07),
                ),
              ),
            ),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
