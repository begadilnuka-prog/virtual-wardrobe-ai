import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WardrobeImage extends StatelessWidget {
  const WardrobeImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.iconSize = 36,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
      ),
      child: _buildImage(),
    );

    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }

  Widget _buildImage() {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _Fallback(iconSize: iconSize),
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _Fallback(iconSize: iconSize),
      );
    }

    if (imageUrl.isNotEmpty) {
      return Image.file(
        File(imageUrl),
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _Fallback(iconSize: iconSize),
      );
    }

    return _Fallback(iconSize: iconSize);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3F6FB),
            AppTheme.surfaceHighlight,
            AppTheme.softSurface,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: iconSize,
          color: AppTheme.accentSoft,
        ),
      ),
    );
  }
}
