import 'package:flutter/material.dart';

import '../../core/app_assets.dart';
import '../../theme/app_theme.dart';

/// A small reusable branding widget for the app logo.
///
/// This widget uses an asset image to keep branding consistent across the app.
/// It defaults to the `assets/images/logo.png` asset and constrains it to a
/// fixed size to avoid layout shifts.
class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 32,
    this.label,
    this.showLabel = false,
    super.key,
  });

  /// The width/height used to constrain the logo.
  final double size;

  /// Optional label displayed next to the logo when [showLabel] is true.
  final String? label;

  /// If true, the widget shows the logo + text.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final image = SizedBox.square(
      dimension: size,
      child: Image.asset(
        AppAssets.logo,
        fit: BoxFit.contain,
        semanticLabel: 'I Closet logo',
        errorBuilder: (context, error, stack) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              borderRadius: BorderRadius.circular(size * 0.25),
            ),
            child: Center(
              child: Icon(
                Icons.checkroom_rounded,
                size: size * 0.55,
                color: AppTheme.accentDeep,
              ),
            ),
          );
        },
      ),
    );

    if (!showLabel) return image;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        image,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label ?? 'I Closet',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
