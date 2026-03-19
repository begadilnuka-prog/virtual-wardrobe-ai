import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/outfit_look.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/styled_button.dart';
import '../../widgets/wardrobe_image.dart';

class OutfitDetailsScreen extends StatelessWidget {
  const OutfitDetailsScreen({
    required this.outfit,
    super.key,
  });

  final OutfitLook outfit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wardrobe = context.watch<WardrobeProvider>();
    final includedItems = wardrobe.allItems
        .where((item) => outfit.itemIds.contains(item.id))
        .toList();

    return PremiumScaffold(
      appBar: AppBar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(outfit.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            joinWithDot([
              formatWardrobeTagLabel(outfit.occasion),
              formatWardrobeTagLabel(outfit.style),
              if ((outfit.weatherContext ?? '').isNotEmpty)
                outfit.weatherContext!,
            ]),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('look_details_why'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(outfit.notes),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('look_details_items'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...includedItems.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(formatWardrobeItemName(item.name)),
                      subtitle: Text(joinWithDot(
                        [
                          formatColorLabel(item.color),
                          formatCategoryLabel(item.category),
                        ],
                      )),
                      leading: SizedBox(
                        width: 52,
                        height: 52,
                        child: WardrobeImage(
                          imageUrl: item.imageUrl,
                          borderRadius: BorderRadius.circular(14),
                          iconSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          StyledButton(
            label: l10n.t('look_details_save_planner'),
            icon: Icons.calendar_month_rounded,
            onPressed: () => _pickDay(context),
          ),
          const SizedBox(height: 12),
          StyledButton(
            label: l10n.t('look_details_toggle_favorite'),
            icon: Icons.favorite_border_rounded,
            onPressed: () =>
                context.read<OutfitProvider>().toggleFavorite(outfit),
          ),
          const SizedBox(height: 12),
          StyledButton(
            label: l10n.t('look_details_delete'),
            secondary: true,
            icon: Icons.delete_outline_rounded,
            onPressed: () async {
              await context.read<OutfitProvider>().deleteOutfit(outfit.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickDay(BuildContext context) async {
    final selectedDay = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListView.separated(
          shrinkWrap: true,
          itemCount: AppConstants.weekDays.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(formatWeekDayLabel(index)),
              onTap: () => Navigator.of(sheetContext).pop(index),
            );
          },
        );
      },
    );

    if (selectedDay == null || !context.mounted) {
      return;
    }

    await context.read<PlannerProvider>().assignOutfit(
          dayIndex: selectedDay,
          outfitId: outfit.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.t(
              'look_details_saved_to',
              args: {'day': formatWeekDayLabel(selectedDay)},
            ),
          ),
        ),
      );
    }
  }
}
