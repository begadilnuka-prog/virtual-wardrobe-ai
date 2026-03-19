import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/styled_button.dart';
import '../home/main_shell.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final _cityController = TextEditingController();
  bool _isSaving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveCity() async {
    final l10n = context.l10n;
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.profile == null) {
        await profileProvider.loadProfile();
      }
      final currentProfile = profileProvider.profile;
      if (currentProfile != null) {
        await profileProvider.saveProfile(
          nextProfile: currentProfile.copyWith(city: city),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('city_error_save'))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.watch<ProfileProvider>().profile;
    if (!_prefilled && (profile?.city.trim().isNotEmpty ?? false)) {
      _prefilled = true;
      _cityController.text = profile!.city;
    }

    return PremiumScaffold(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        children: [
          const SizedBox(height: 42),
          const Center(child: AppLogo(size: 110)),
          const SizedBox(height: 26),
          Text(
            l10n.t('city_title'),
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t('city_subtitle'),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: l10n.t('city_label'),
              hintText: l10n.t('city_hint'),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _saveCity(),
          ),
          const SizedBox(height: 24),
          StyledButton(
            label: _isSaving ? l10n.t('city_saving') : l10n.t('city_continue'),
            icon: _isSaving ? null : Icons.arrow_forward_rounded,
            onPressed: _isSaving ? null : _saveCity,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
