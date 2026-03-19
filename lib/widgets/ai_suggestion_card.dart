import 'package:flutter/material.dart';

import '../core/app_utils.dart';
import '../l10n/app_localizations.dart';
import '../models/ai_suggestion.dart';
import '../theme/app_theme.dart';
import 'wardrobe_image.dart';

class AiSuggestionCard extends StatelessWidget {
  const AiSuggestionCard({
    required this.suggestion,
    this.onSave,
    super.key,
  });

  final AiSuggestion suggestion;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final heroItems = suggestion.items.take(3).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(suggestion.occasion)),
                          Chip(
                            backgroundColor: AppTheme.surfaceHighlight,
                            label: Text(suggestion.mood),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: Text(context.l10n.t('common_save')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 136,
              child: Row(
                children: heroItems
                    .map(
                      (item) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: item == heroItems.last ? 0 : 10),
                          child: Column(
                            children: [
                              Expanded(
                                child: WardrobeImage(
                                  imageUrl: item.imageUrl,
                                  borderRadius: BorderRadius.circular(18),
                                  iconSize: 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatCategoryLabel(item.category),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            Text(suggestion.reasoning),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestion.items
                  .map((item) => Chip(
                          label: Text(joinWithDot([
                        formatCategoryLabel(item.category),
                        formatWardrobeItemName(item.name),
                      ]))))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
