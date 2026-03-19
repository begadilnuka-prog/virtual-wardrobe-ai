import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/wardrobe_item.dart';
import '../../providers/profile_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/wardrobe_image.dart';
import '../../widgets/wardrobe_item_card.dart';
import '../ai/ai_stylist_screen.dart';
import 'add_item_screen.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.watch<ProfileProvider>().profile;
    return PremiumScaffold(
      appBar: AppBar(
        title: Text(l10n.t('wardrobe_title')),
        actions: [
          IconButton.filledTonal(
            tooltip: l10n.t('ai_title'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiStylistScreen()),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddOptions(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.t('wardrobe_add_item')),
      ),
      child: Consumer<WardrobeProvider>(
        builder: (context, wardrobe, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 980
                  ? 4
                  : width >= 700
                      ? 3
                      : 2;
              final childAspectRatio = width >= 980
                  ? 0.82
                  : width >= 700
                      ? 0.76
                      : width >= 420
                          ? 0.68
                          : 0.63;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFF2F5FB),
                                  Color(0xFFE8EEF8),
                                  Color(0xFFDFE8F4),
                                ],
                              ),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentDeep
                                      .withValues(alpha: 0.05),
                                  blurRadius: 26,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t(
                                    'wardrobe_hero_title',
                                    args: {
                                      'name': profile?.name.split(' ').first ??
                                          l10n.t('common_friend')
                                    },
                                  ),
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.t('wardrobe_hero_subtitle'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.text),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _WardrobeStat(
                                        label: l10n.t('wardrobe_stat_items'),
                                        value: '${wardrobe.allItems.length}',
                                        icon: Icons.checkroom_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _WardrobeStat(
                                        label:
                                            l10n.t('wardrobe_stat_favorites'),
                                        value:
                                            '${wardrobe.favoriteItems.length}',
                                        icon: Icons.favorite_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openAddScreen(
                                          context,
                                          source: AddItemEntrySource.camera,
                                        ),
                                        icon: const Icon(
                                            Icons.camera_alt_outlined),
                                        label: Text(
                                            l10n.t('wardrobe_scan_camera')),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _openAddScreen(
                                          context,
                                          source: AddItemEntrySource.gallery,
                                        ),
                                        icon: const Icon(
                                            Icons.photo_library_outlined),
                                        label: Text(
                                            l10n.t('wardrobe_add_gallery')),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: l10n.t('wardrobe_title'),
                                  subtitle: l10n.t('wardrobe_search_hint'),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  onChanged: wardrobe.setSearchQuery,
                                  decoration: InputDecoration(
                                    prefixIcon:
                                        const Icon(Icons.search_rounded),
                                    hintText: l10n.t('wardrobe_search_hint'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                CategorySelector(
                                  selectedCategory: wardrobe.selectedCategory,
                                  onChanged: wardrobe.setCategory,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                  if (wardrobe.isLoading)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverToBoxAdapter(
                        child: LoadingShimmer(itemCount: 6),
                      ),
                    )
                  else if (wardrobe.filteredItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        child: EmptyState(
                          icon: Icons.checkroom_outlined,
                          title: l10n.t('wardrobe_empty_title'),
                          subtitle: wardrobe.allItems.isEmpty
                              ? l10n.t('wardrobe_empty_subtitle_empty')
                              : l10n.t('wardrobe_empty_subtitle_filtered'),
                          action: FilledButton(
                            onPressed: () => _openAddOptions(context),
                            child: Text(l10n.t('wardrobe_add_item')),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = wardrobe.filteredItems[index];
                            return WardrobeItemCard(
                              item: item,
                              onFavorite: () => wardrobe.toggleFavorite(item),
                              onEdit: () => _openEditor(context, item),
                              onDelete: () => _deleteItem(context, item),
                              onTap: () => _showItemDetails(context, item),
                            );
                          },
                          childCount: wardrobe.filteredItems.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WardrobeItem item) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddItemScreen(item: item)),
    );
  }

  Future<void> _openAddScreen(
    BuildContext context, {
    AddItemEntrySource? source,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddItemScreen(initialSource: source)),
    );
  }

  Future<void> _openAddOptions(BuildContext context) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.t('wardrobe_scan_camera')),
                subtitle: Text(l10n.t('add_item_photo_title')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAddScreen(context, source: AddItemEntrySource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.t('wardrobe_add_gallery')),
                subtitle: Text(l10n.t('common_gallery')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAddScreen(context, source: AddItemEntrySource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: Text(l10n.t('wardrobe_add_item')),
                subtitle: Text(l10n.t('add_item_subtitle')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAddScreen(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(BuildContext context, WardrobeItem item) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.t('wardrobe_delete_title')),
            content: Text(l10n.t('wardrobe_delete_content',
                args: {'item': formatWardrobeItemName(item.name)})),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.t('common_cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.t('common_delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<WardrobeProvider>().deleteItem(item.id);
  }

  Future<void> _showItemDetails(BuildContext context, WardrobeItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'wardrobe-item-${item.id}',
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: WardrobeImage(
                    imageUrl: item.imageUrl,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                formatWardrobeItemName(item.name),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                joinWithDot([
                  formatCategoryLabel(item.category),
                  formatColorLabel(item.color),
                  formatStyleTagLabel(item.style),
                  formatSeasonLabel(item.season),
                ]),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.tags
                    .map(
                        (tag) => Chip(label: Text(formatWardrobeTagLabel(tag))))
                    .toList(),
              ),
              if ((item.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(item.notes!, style: Theme.of(context).textTheme.bodyLarge),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openEditor(context, item);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.l10n.t('common_edit')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await _deleteItem(context, item);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(context.l10n.t('common_delete')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WardrobeStat extends StatelessWidget {
  const _WardrobeStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
