import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/outfit_card.dart';
import '../../widgets/premium_scaffold.dart';
import 'outfit_details_screen.dart';

class SavedLooksScreen extends StatelessWidget {
  const SavedLooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PremiumScaffold(
      appBar: AppBar(),
      child: Consumer2<OutfitProvider, WardrobeProvider>(
        builder: (context, outfits, wardrobe, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(l10n.t('looks_saved_title'),
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                l10n.t('looks_saved_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (outfits.outfits.isEmpty)
                EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: l10n.t('looks_empty_title'),
                  subtitle: l10n.t('looks_empty_subtitle'),
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
          );
        },
      ),
    );
  }
}
