import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/common/subscription_checkout_sheet.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/styled_button.dart';
import '../../widgets/wardrobe_image.dart';
import '../ai/ai_stylist_screen.dart';
import '../looks/saved_looks_screen.dart';
import '../premium/premium_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final ImageService _imageService = ImageService();

  StyleTag _favoriteStyle = StyleTag.smartCasual;
  StylePreference _stylePreference = StylePreference.neutral;
  final Set<String> _preferredColors = {};
  String? _pendingPhotoPath;
  String? _syncedUserId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _sync(UserProfile? profile) {
    if (profile == null || _syncedUserId == profile.userId) {
      return;
    }

    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _cityController.text = profile.city;
    _favoriteStyle = profile.favoriteStyle;
    _stylePreference = profile.stylePreference;
    _preferredColors
      ..clear()
      ..addAll(profile.preferredColors);
    _pendingPhotoPath = null;
    _syncedUserId = profile.userId;
  }

  Future<void> _pickProfilePhoto({required bool fromCamera}) async {
    final file = fromCamera
        ? await _imageService.pickFromCamera()
        : await _imageService.pickFromGallery();
    if (file == null) {
      return;
    }
    setState(() => _pendingPhotoPath = file.path);
  }

  Future<void> _saveProfile(UserProfile profile) async {
    await context.read<ProfileProvider>().saveProfile(
          nextProfile: profile.copyWith(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            city: _cityController.text.trim(),
            favoriteStyle: _favoriteStyle,
            stylePreference: _stylePreference,
            preferredColors: _preferredColors.toList(),
          ),
          newImagePath: _pendingPhotoPath,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('profile_saved_locally'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileProvider = context.watch<ProfileProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final wardrobe = context.watch<WardrobeProvider>();
    final outfits = context.watch<OutfitProvider>();
    final planner = context.watch<PlannerProvider>();
    final auth = context.watch<AuthProvider>();
    final profile = profileProvider.profile;

    _sync(profile);

    return PremiumScaffold(
      appBar: AppBar(
        title: const AppLogo(size: 26, showLabel: true),
        actions: [
          IconButton(
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
      child: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: (_pendingPhotoPath ??
                                            profile.profilePhotoPath) ==
                                        null
                                    ? Container(
                                        color: AppTheme.surfaceHighlight,
                                        alignment: Alignment.center,
                                        child: Text(
                                          initialsForName(profile.name),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                      )
                                    : WardrobeImage(
                                        imageUrl: _pendingPhotoPath ??
                                            profile.profilePhotoPath ??
                                            '',
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: IconButton.filled(
                                onPressed: () => showModalBottomSheet<void>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (sheetContext) {
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          24, 8, 24, 28),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(
                                                Icons.camera_alt_outlined),
                                            title: Text(
                                                l10n.t('profile_take_photo')),
                                            onTap: () {
                                              Navigator.of(sheetContext).pop();
                                              _pickProfilePhoto(
                                                  fromCamera: true);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                                Icons.photo_library_outlined),
                                            title: Text(l10n
                                                .t('profile_choose_gallery')),
                                            onTap: () {
                                              Navigator.of(sheetContext).pop();
                                              _pickProfilePhoto(
                                                  fromCamera: false);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 6),
                              Text(profile.email,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              if (profile.city.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppTheme.textSoft,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      profile.city,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (subscription.isPremium)
                                    PremiumBadge(label: subscription.tierLabel)
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceHighlight,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        l10n.t('common_free_plan'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final itemWidth = width < 380 ? width : (width - 24) / 3;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _ProfileStatCard(
                            label: l10n.t('profile_stat_wardrobe_items'),
                            value: '${wardrobe.allItems.length}',
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _ProfileStatCard(
                            label: l10n.t('profile_stat_saved_looks'),
                            value: '${outfits.outfits.length}',
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _ProfileStatCard(
                            label: l10n.t('profile_stat_planned_days'),
                            value: '${planner.plans.length}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: l10n.t('profile_account_title'),
                  subtitle: l10n.t('profile_account_subtitle'),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration:
                              InputDecoration(labelText: l10n.t('form_name')),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _emailController,
                          decoration:
                              InputDecoration(labelText: l10n.t('form_email')),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _cityController,
                          decoration:
                              InputDecoration(labelText: l10n.t('form_city')),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<StyleTag>(
                          initialValue: _favoriteStyle,
                          decoration: InputDecoration(
                              labelText: l10n.t('form_favorite_style')),
                          items: StyleTag.values
                              .map((style) => DropdownMenuItem(
                                    value: style,
                                    child: Text(formatStyleTagLabel(style)),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _favoriteStyle = value!),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.t('profile_style_preference'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: StylePreference.values.map((preference) {
                            return ChoiceChip(
                              label:
                                  Text(formatStylePreferenceLabel(preference)),
                              selected: _stylePreference == preference,
                              onSelected: (_) =>
                                  setState(() => _stylePreference = preference),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.t('profile_preferred_colors'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.demoColors.map((color) {
                            return FilterChip(
                              label: Text(formatColorLabel(color)),
                              selected: _preferredColors.contains(color),
                              onSelected: (_) {
                                setState(() {
                                  if (_preferredColors.contains(color)) {
                                    _preferredColors.remove(color);
                                  } else {
                                    _preferredColors.add(color);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: profileProvider.isSaving
                      ? null
                      : () => _saveProfile(profile),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(profileProvider.isSaving
                      ? l10n.t('profile_saving')
                      : l10n.t('profile_save_changes')),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('language_title'),
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t('language_subtitle'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<AppLanguage>(
                          initialValue: settings.language,
                          decoration: InputDecoration(
                            labelText: l10n.t('language_current'),
                            prefixIcon: const Icon(Icons.language_rounded),
                          ),
                          items: AppLanguage.values
                              .map(
                                (language) => DropdownMenuItem(
                                  value: language,
                                  child: Text(l10n.languageLabel(language)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              context
                                  .read<AppSettingsProvider>()
                                  .setLanguage(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(l10n.t('profile_subscription_title'),
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(width: 10),
                            if (subscription.isPremium)
                              PremiumBadge(label: subscription.tierLabel),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subscription.isPlus
                              ? l10n.t('profile_subscription_plus')
                              : subscription.isPremium
                                  ? l10n.t('profile_subscription_premium')
                                  : l10n.t('profile_subscription_free'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        _SubscriptionDetailRow(
                          icon: subscription.isPremium
                              ? Icons.verified_rounded
                              : Icons.lock_outline_rounded,
                          label: l10n.t('profile_current_plan_label'),
                          value: subscription.tierLabel,
                        ),
                        if (subscription.isPremium &&
                            subscription.paymentMethodLabel != null) ...[
                          const SizedBox(height: 10),
                          _SubscriptionDetailRow(
                            icon: Icons.credit_card_rounded,
                            label: l10n.t('profile_payment_method_label'),
                            value: subscription.paymentMethodLabel!,
                          ),
                        ],
                        if (subscription.isPremium &&
                            subscription.renewalDate != null) ...[
                          const SizedBox(height: 10),
                          _SubscriptionDetailRow(
                            icon: Icons.event_repeat_rounded,
                            label: l10n.t('profile_next_billing_label'),
                            value: formatShortDate(subscription.renewalDate!),
                          ),
                        ],
                        if (subscription.isPremium &&
                            subscription.lastPaymentAt != null) ...[
                          const SizedBox(height: 10),
                          _SubscriptionDetailRow(
                            icon: Icons.receipt_long_outlined,
                            label: l10n.t('profile_last_payment_label'),
                            value: formatShortDate(subscription.lastPaymentAt!),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            if (subscription.isPremium) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PremiumScreen(),
                                ),
                              );
                              return;
                            }

                            showSubscriptionCheckoutFlow(
                              context,
                              tier: SubscriptionTier.premium,
                            );
                          },
                          icon: Icon(
                            subscription.isPremium
                                ? Icons.settings_outlined
                                : Icons.lock_outline_rounded,
                          ),
                          label: Text(
                            subscription.isPremium
                                ? l10n.t('profile_manage_subscription')
                                : l10n.t('profile_upgrade_premium'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => const PremiumScreen()),
                                  );
                                },
                                icon: const Icon(
                                    Icons.workspace_premium_outlined),
                                label: Text(l10n.t('profile_billing_plans')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SavedLooksScreen()),
                                  );
                                },
                                icon: const Icon(Icons.bookmarks_outlined),
                                label:
                                    Text(l10n.t('profile_saved_looks_button')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                StyledButton(
                  label: l10n.t('profile_logout'),
                  secondary: true,
                  icon: Icons.logout_rounded,
                  onPressed: auth.logout,
                ),
              ],
            ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionDetailRow extends StatelessWidget {
  const _SubscriptionDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accentDeep),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}
