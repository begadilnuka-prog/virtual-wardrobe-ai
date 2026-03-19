import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class UsageMeter extends StatelessWidget {
  const UsageMeter({
    required this.title,
    required this.subtitle,
    required this.progress,
    super.key,
  });

  final String title;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 9,
                backgroundColor: AppTheme.surfaceHighlight,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
