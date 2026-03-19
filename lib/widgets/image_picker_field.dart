import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'wardrobe_image.dart';

class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    required this.imagePath,
    required this.onGalleryTap,
    required this.onCameraTap,
    this.onClearTap,
    super.key,
  });

  final String? imagePath;
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;
  final VoidCallback? onClearTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: WardrobeImage(
                    imageUrl: imagePath ?? '',
                    borderRadius: BorderRadius.circular(24),
                    iconSize: 42,
                  ),
                ),
                if (imagePath == null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withValues(alpha: 0.48),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 40),
                          const SizedBox(height: 10),
                          Text(l10n.t('image_picker_upload_title')),
                        ],
                      ),
                    ),
                  ),
                if (imagePath != null && onClearTap != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton.filledTonal(
                      onPressed: onClearTap,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.88),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.t('image_picker_subtitle'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onGalleryTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.surfaceHighlight,
                      foregroundColor: AppTheme.text,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.t('common_gallery')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCameraTap,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l10n.t('common_camera')),
                  ),
                ),
              ],
            ),
            if (imagePath == null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.t('image_picker_formats'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSoft),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
