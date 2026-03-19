import 'package:flutter/foundation.dart';

import '../core/app_enums.dart';
import '../models/outfit_look.dart';
import '../models/user_profile.dart';
import '../models/wardrobe_item.dart';
import '../repositories/outfit_repository.dart';
import '../services/styling_engine_service.dart';
import 'auth_provider.dart';

class OutfitProvider extends ChangeNotifier {
  OutfitProvider({
    required AuthProvider authProvider,
    required OutfitRepository repository,
  })  : _authProvider = authProvider,
        _repository = repository,
        _stylingEngineService = StylingEngineService();

  AuthProvider _authProvider;
  OutfitRepository _repository;
  final StylingEngineService _stylingEngineService;

  final List<OutfitLook> _savedOutfits = [];
  final List<OutfitLook> _generatedLooks = [];
  bool isLoading = false;
  bool isGenerating = false;

  List<OutfitLook> get outfits => List.unmodifiable(_savedOutfits);
  List<OutfitLook> get generatedLooks => List.unmodifiable(_generatedLooks);

  void updateDependencies(
      AuthProvider authProvider, OutfitRepository repository) {
    final previousUserId = _authProvider.currentUser?.id;
    _authProvider = authProvider;
    _repository = repository;
    if (previousUserId != _authProvider.currentUser?.id) {
      loadOutfits();
    }
  }

  Future<void> loadOutfits() async {
    final user = _authProvider.currentUser;
    if (user == null) {
      _savedOutfits.clear();
      _generatedLooks.clear();
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    final saved = await _repository.fetchOutfits(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
    );
    final generated = await _repository.fetchGeneratedLooks(user.id);
    _savedOutfits
      ..clear()
      ..addAll(saved);
    _generatedLooks
      ..clear()
      ..addAll(generated);
    isLoading = false;
    notifyListeners();
  }

  Future<List<OutfitLook>> generateLooks({
    required List<WardrobeItem> wardrobe,
    required String occasion,
    required WeatherCondition weather,
    required bool premium,
    DailyOccasion? occasionType,
    UserProfile? profile,
  }) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return [];
    }

    isGenerating = true;
    notifyListeners();
    final looks = _stylingEngineService.generateLooks(
      userId: user.id,
      wardrobe: wardrobe,
      occasion: occasion,
      weather: weather,
      premium: premium,
      occasionType: occasionType,
      profile: profile,
    );
    _generatedLooks
      ..clear()
      ..addAll(looks);
    await _repository.cacheGeneratedLooks(userId: user.id, looks: looks);
    isGenerating = false;
    notifyListeners();
    return looks;
  }

  Future<OutfitLook?> saveGeneratedLook(OutfitLook look) async {
    return saveOutfit(
      title: look.title,
      itemIds: look.itemIds,
      occasion: look.occasion,
      style: look.style,
      notes: look.notes,
      tags: look.tags,
      weatherContext: look.weatherContext,
      isPremium: look.isPremium,
    );
  }

  Future<OutfitLook?> saveOutfit({
    required String title,
    required List<String> itemIds,
    required String occasion,
    required String style,
    required String notes,
    List<String> tags = const [],
    String? weatherContext,
    bool isPremium = false,
  }) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return null;
    }

    final saved = await _repository.saveOutfit(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
      title: title,
      itemIds: itemIds,
      occasion: occasion,
      style: style,
      notes: notes,
      tags: tags,
      weatherContext: weatherContext,
      isGenerated: false,
      isPremium: isPremium,
    );
    _savedOutfits.insert(0, saved);
    notifyListeners();
    return saved;
  }

  OutfitLook? findSavedById(String outfitId) {
    return _savedOutfits.where((outfit) => outfit.id == outfitId).firstOrNull;
  }

  Future<void> deleteOutfit(String outfitId) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    await _repository.deleteOutfit(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
      outfitId: outfitId,
    );
    _savedOutfits.removeWhere((outfit) => outfit.id == outfitId);
    notifyListeners();
  }

  Future<void> toggleFavorite(OutfitLook outfit) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    await _repository.toggleFavorite(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
      outfit: outfit,
    );
    await loadOutfits();
  }

  Future<void> clearGeneratedLooks() async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    _generatedLooks.clear();
    await _repository.cacheGeneratedLooks(userId: user.id, looks: const []);
    notifyListeners();
  }
}
