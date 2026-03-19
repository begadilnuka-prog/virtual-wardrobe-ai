import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/app_logo.dart';

class AuthScreenScaffold extends StatelessWidget {
  const AuthScreenScaffold({
    required this.child,
    this.appBar,
    super.key,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;

  static const _backgroundColor = Color(0xFFF7F8FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: appBar,
      body: ColoredBox(
        color: _backgroundColor,
        child: SafeArea(
          top: appBar == null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
              final padding = EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset);
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - padding.vertical,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: SizedBox(
                        width: double.infinity,
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AuthHeaderCard extends StatelessWidget {
  const AuthHeaderCard({
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.centered = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentDeep.withValues(alpha: 0.045),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: centered
          ? Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const AppLogo(size: 62),
                ),
                const SizedBox(height: 18),
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppTheme.accentDeep,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    color: AppTheme.accentDeep,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.45,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const AppLogo(size: 54),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        Text(
                          eyebrow!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppTheme.accentDeep,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 28,
                          color: AppTheme.accentDeep,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSoft,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
