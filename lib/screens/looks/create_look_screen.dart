import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/wardrobe_item.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/outfit_card.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/styled_button.dart';
import 'outfit_details_screen.dart';

class CreateLookScreen extends StatefulWidget {
  const CreateLookScreen({super.key});

  @override
  State<CreateLookScreen> createState() => _CreateLookScreenState();
}

class _CreateLookScreenState extends State<CreateLookScreen> {
  final _titleController = TextEditingController();
  final _occasionController = TextEditingController();
  final _styleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _defaultsInitialized = false;

  final Map<ClothingCategory, WardrobeItem?> _selected = {
    ClothingCategory.tops: null,
    ClothingCategory.bottoms: null,
    ClothingCategory.outerwear: null,
    ClothingCategory.dresses: null,
    ClothingCategory.shoes: null,
    ClothingCategory.bags: null,
    ClothingCategory.accessories: null,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _occasionController.dispose();
    _styleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsInitialized) {
      return;
    }

    final l10n = context.l10n;
    _occasionController.text = l10n.t('create_look_default_occasion');
    _styleController.text = l10n.t('create_look_default_style');
    _defaultsInitialized = true;
  }

  Future<void> _saveLook() async {
    final items = _selected.values.whereType<WardrobeItem>().toList();
    if (_titleController.text.trim().isEmpty || items.isEmpty) {
      return;
    }
    await context.read<OutfitProvider>().saveOutfit(
          title: _titleController.text.trim(),
          itemIds: items.map((item) => item.id).toList(),
          occasion: _occasionController.text.trim(),
          style: _styleController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? context.l10n.t('create_look_default_notes')
              : _notesController.text.trim(),
        );
    if (!mounted) {
      return;
    }
    _titleController.clear();
    _notesController.clear();
    setState(() {
      for (final key in _selected.keys) {
        _selected[key] = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wardrobe = context.watch<WardrobeProvider>();
    final outfits = context.watch<OutfitProvider>();

    return PremiumScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.t('create_look_title'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            l10n.t('create_look_subtitle'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (wardrobe.allItems.isEmpty)
            EmptyState(
              icon: Icons.auto_awesome_mosaic_outlined,
              title: l10n.t('create_look_empty_title'),
              subtitle: l10n.t('create_look_empty_subtitle'),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: l10n.t('create_look_field_title'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _occasionController,
                      decoration: InputDecoration(
                        labelText: l10n.t('create_look_field_occasion'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _styleController,
                      decoration: InputDecoration(
                        labelText: l10n.t('create_look_field_style'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.t('create_look_field_why'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...ClothingCategory.values.map((category) {
              final options = wardrobe.allItems
                  .where((item) => item.category == category)
                  .toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatCategoryLabel(category),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<WardrobeItem?>(
                          initialValue: _selected[category],
                          decoration: InputDecoration(
                            hintText: l10n.t('create_look_select_item'),
                          ),
                          items: [
                            DropdownMenuItem<WardrobeItem?>(
                              value: null,
                              child: Text(l10n.t('common_none')),
                            ),
                            ...options.map(
                              (item) => DropdownMenuItem<WardrobeItem?>(
                                value: item,
                                child: Text(formatWardrobeItemName(item.name)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selected[category] = value;
                              if (category == ClothingCategory.dresses &&
                                  value != null) {
                                _selected[ClothingCategory.tops] = null;
                                _selected[ClothingCategory.bottoms] = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            StyledButton(
              label: l10n.t('create_look_save'),
              icon: Icons.bookmark_add_outlined,
              onPressed: _saveLook,
            ),
          ],
          const SizedBox(height: 28),
          SectionHeader(
            title: l10n.t('looks_saved_title'),
            subtitle: l10n.t('create_look_saved_subtitle'),
          ),
          const SizedBox(height: 14),
          if (outfits.outfits.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.t('create_look_saved_placeholder'),
                ),
              ),
            )
          else
            ...outfits.outfits.map(
              (outfit) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: OutfitCard(
                  outfit: outfit,
                  items: wardrobe.allItems
                      .where((item) => outfit.itemIds.contains(item.id))
                      .toList(),
                  onFavorite: () => outfits.toggleFavorite(outfit),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OutfitDetailsScreen(outfit: outfit),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
