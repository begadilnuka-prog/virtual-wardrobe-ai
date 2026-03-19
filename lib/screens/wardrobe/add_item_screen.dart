import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_enums.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/clothing_recognition.dart';
import '../../models/wardrobe_item.dart';
import '../../providers/wardrobe_provider.dart';
import '../../services/clothing_recognition_service.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/wardrobe_image.dart';

enum AddItemEntrySource { camera, gallery }

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({
    this.item,
    this.initialSource,
    super.key,
  });

  final WardrobeItem? item;
  final AddItemEntrySource? initialSource;

  bool get isEditing => item != null;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  final ImageService _imageService = ImageService();
  final ClothingRecognitionService _recognitionService =
      ClothingRecognitionService();

  ClothingCategory _category = ClothingCategory.tops;
  SeasonTag _season = SeasonTag.allSeason;
  StyleTag _style = StyleTag.smartCasual;
  String _color = AppConstants.demoColors.first;
  String? _imagePath;
  bool _isFavorite = false;
  bool _saving = false;
  bool _isRecognizing = false;
  double? _recognitionConfidence;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nameController.text = formatWardrobeItemName(item.name);
      _brandController.text = item.brand ?? '';
      _notesController.text = item.notes ?? '';
      _tagsController.text = item.tags.map(formatWardrobeTagLabel).join(', ');
      _category = item.category;
      _season = item.season;
      _style = item.style;
      _color = item.color;
      _imagePath = item.imageUrl;
      _isFavorite = item.isFavorite;
    }

    if (!widget.isEditing && widget.initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (widget.initialSource == AddItemEntrySource.camera) {
          _pickFromCamera();
        } else {
          _pickFromGallery();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> get _parsedTags => _tagsController.text
      .split(',')
      .map((entry) => canonicalWardrobeTag(entry.trim()))
      .where((entry) => entry.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _pickFromGallery() async {
    final result = await _imageService.pickFromGallery();
    if (result == null) {
      return;
    }
    await _applyPickedImage(result.path);
  }

  Future<void> _pickFromCamera() async {
    final result = await _imageService.pickFromCamera();
    if (result == null) {
      return;
    }
    await _applyPickedImage(result.path);
  }

  Future<void> _applyPickedImage(String path) async {
    setState(() {
      _imagePath = path;
      _isRecognizing = true;
    });

    final recognition = await _recognitionService.recognize(path);
    if (!mounted) {
      return;
    }

    _applyRecognition(recognition);
  }

  void _applyRecognition(ClothingRecognition recognition) {
    setState(() {
      _nameController.text = recognition.name;
      _category = recognition.category;
      _color = recognition.color;
      _season = recognition.season;
      _style = recognition.style;
      _tagsController.text =
          recognition.tags.map(formatWardrobeTagLabel).join(', ');
      _recognitionConfidence = recognition.confidence;
      _isRecognizing = false;
    });
  }

  void _toggleSuggestedTag(String tag) {
    final next = _parsedTags.toSet();
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    setState(() => _tagsController.text = next.join(', '));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imagePath == null || _imagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('form_error_add_photo'))),
      );
      return;
    }

    setState(() => _saving = true);
    final wardrobe = context.read<WardrobeProvider>();
    final item = widget.item;

    if (item == null) {
      await wardrobe.addItem(
        name: canonicalWardrobeItemName(_nameController.text.trim()),
        imagePath: _imagePath!,
        category: _category,
        color: _color,
        season: _season,
        style: _style,
        tags: _parsedTags,
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isFavorite: _isFavorite,
      );
    } else {
      await wardrobe.updateItem(
        item: item,
        name: canonicalWardrobeItemName(_nameController.text.trim()),
        imagePath: _imagePath,
        category: _category,
        color: _color,
        season: _season,
        style: _style,
        tags: _parsedTags,
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isFavorite: _isFavorite,
      );
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PremiumScaffold(
      appBar: AppBar(
          title: Text(widget.isEditing
              ? l10n.t('edit_item_title')
              : l10n.t('add_item_title'))),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            widget.isEditing
                ? l10n.t('edit_item_title')
                : l10n.t('add_item_title'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.t('add_item_subtitle'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF4F4F1),
                  Color(0xFFEAF0F4),
                  Color(0xFFE4E4EB),
                ],
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: AppTheme.accentDeep),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.t('add_item_photo_title'),
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            l10n.t('add_item_photo_subtitle'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: Colors.white.withValues(alpha: 0.74),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: WardrobeImage(
                      imageUrl: _imagePath ?? '',
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _UploadActionCard(
                        icon: Icons.camera_alt_outlined,
                        title: l10n.t('wardrobe_scan_camera'),
                        subtitle: l10n.t('common_camera'),
                        onTap: _pickFromCamera,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UploadActionCard(
                        icon: Icons.photo_library_outlined,
                        title: l10n.t('wardrobe_add_gallery'),
                        subtitle: l10n.t('common_gallery'),
                        highlighted: true,
                        onTap: _pickFromGallery,
                      ),
                    ),
                  ],
                ),
                if (_imagePath != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => setState(() => _imagePath = null),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.t('add_item_remove_photo')),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _isRecognizing
                ? Card(
                    key: const ValueKey('recognizing'),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.t('add_item_recognizing_title'),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            l10n.t('add_item_recognizing_subtitle'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(minHeight: 8),
                        ],
                      ),
                    ),
                  )
                : _recognitionConfidence == null
                    ? const SizedBox.shrink()
                    : Card(
                        key: const ValueKey('recognized'),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    color: AppTheme.accent),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  l10n.t(
                                    'add_item_recognition_complete',
                                    args: {
                                      'value':
                                          '${(100 * _recognitionConfidence!).round()}'
                                    },
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.t('form_item_name'),
                        hintText: l10n.t('form_item_name_hint'),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? l10n.t('form_error_enter_name')
                              : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<ClothingCategory>(
                      initialValue: _category,
                      decoration:
                          InputDecoration(labelText: l10n.t('form_category')),
                      items: ClothingCategory.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(formatCategoryLabel(value)),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _category = value!),
                    ),
                    const SizedBox(height: 18),
                    Text(l10n.t('form_color'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.demoColors
                          .map(
                            (color) => _ColorChip(
                              label: formatColorLabel(color),
                              swatch: colorFromName(color),
                              selected: _color == color,
                              onTap: () => setState(() => _color = color),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<SeasonTag>(
                            initialValue: _season,
                            decoration: InputDecoration(
                                labelText: l10n.t('form_season')),
                            items: SeasonTag.values
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(formatSeasonLabel(value)),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _season = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<StyleTag>(
                            initialValue: _style,
                            decoration: InputDecoration(
                                labelText: l10n.t('form_style')),
                            items: StyleTag.values
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(formatStyleTagLabel(value)),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _style = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: l10n.t('form_tags'),
                        hintText: l10n.t('form_tags_hint'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.wardrobeTags.take(8).map((tag) {
                        return FilterChip(
                          label: Text(formatWardrobeTagLabel(tag)),
                          selected: _parsedTags.contains(tag),
                          onSelected: (_) => _toggleSuggestedTag(tag),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _brandController,
                      decoration:
                          InputDecoration(labelText: l10n.t('form_brand')),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration:
                          InputDecoration(labelText: l10n.t('form_notes')),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.t('form_favorite_item')),
                      subtitle: Text(l10n.t('form_favorite_subtitle')),
                      value: _isFavorite,
                      onChanged: (value) => setState(() => _isFavorite = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: Icon(
                widget.isEditing ? Icons.check_rounded : Icons.add_rounded),
            label: Text(
              _saving
                  ? context.l10n.t('profile_saving')
                  : widget.isEditing
                      ? l10n.t('form_save_changes')
                      : l10n.t('form_save_item'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadActionCard extends StatelessWidget {
  const _UploadActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted
              ? AppTheme.accent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: highlighted
                ? AppTheme.accent.withValues(alpha: 0.4)
                : AppTheme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: highlighted ? AppTheme.accentDeep : AppTheme.accent),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = swatch.computeLuminance() > 0.75;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surfaceHighlight : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isLight ? AppTheme.border : Colors.transparent),
              ),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
