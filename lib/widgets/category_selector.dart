import 'package:flutter/material.dart';

import '../core/app_enums.dart';
import '../core/app_utils.dart';
import '../l10n/app_localizations.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    required this.selectedCategory,
    required this.onChanged,
    super.key,
  });

  final ClothingCategory? selectedCategory;
  final ValueChanged<ClothingCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(context.l10n.t('common_all')),
              selected: selectedCategory == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          ...ClothingCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(formatCategoryLabel(category)),
                selected: selectedCategory == category,
                onSelected: (_) => onChanged(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
