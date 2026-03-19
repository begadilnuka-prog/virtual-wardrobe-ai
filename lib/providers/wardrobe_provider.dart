import 'package:flutter/foundation.dart';

import '../core/app_enums.dart';
import '../core/app_utils.dart';
import '../models/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';
import 'auth_provider.dart';

class WardrobeProvider extends ChangeNotifier {
  WardrobeProvider({
    required AuthProvider authProvider,
    required WardrobeRepository repository,
  })  : _authProvider = authProvider,
        _repository = repository;

  AuthProvider _authProvider;
  WardrobeRepository _repository;

  final List<WardrobeItem> _items = [];
  bool isLoading = false;
  String searchQuery = '';
  ClothingCategory? selectedCategory;

  List<WardrobeItem> get allItems => List.unmodifiable(_items);

  List<WardrobeItem> get favoriteItems =>
      _items.where((item) => item.isFavorite).toList(growable: false);

  List<WardrobeItem> get filteredItems {
    return _items.where((item) {
      final matchesCategory =
          selectedCategory == null || item.category == selectedCategory;
      final query = searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          formatWardrobeItemName(item.name).toLowerCase().contains(query) ||
          formatColorLabel(item.color).toLowerCase().contains(query) ||
          formatStyleTagLabel(item.style).toLowerCase().contains(query) ||
          item.tags.any(
            (tag) => formatWardrobeTagLabel(tag).toLowerCase().contains(query),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int countForCategory(ClothingCategory category) {
    return _items.where((item) => item.category == category).length;
  }

  bool get hasEnoughForOutfits {
    return countForCategory(ClothingCategory.shoes) > 0 &&
        (countForCategory(ClothingCategory.dresses) > 0 ||
            (countForCategory(ClothingCategory.tops) > 0 &&
                countForCategory(ClothingCategory.bottoms) > 0));
  }

  void updateDependencies(
      AuthProvider authProvider, WardrobeRepository repository) {
    final previousUserId = _authProvider.currentUser?.id;
    _authProvider = authProvider;
    _repository = repository;
    if (previousUserId != _authProvider.currentUser?.id) {
      loadItems();
    }
  }

  Future<void> loadItems() async {
    final user = _authProvider.currentUser;
    if (user == null) {
      _items.clear();
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    final result = await _repository.fetchItems(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
    );
    _items
      ..clear()
      ..addAll(result);
    isLoading = false;
    notifyListeners();
  }

  Future<void> addItem({
    required String name,
    required String imagePath,
    required ClothingCategory category,
    required String color,
    required SeasonTag season,
    required StyleTag style,
    List<String> tags = const [],
    String? brand,
    String? notes,
    bool isFavorite = false,
  }) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    final saved = await _repository.addItem(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
      name: name,
      imagePath: imagePath,
      category: category,
      color: color,
      season: season,
      style: style,
      tags: tags,
      brand: brand,
      notes: notes,
      isFavorite: isFavorite,
    );
    _items.insert(0, saved);
    notifyListeners();
  }

  Future<void> updateItem({
    required WardrobeItem item,
    required String name,
    required ClothingCategory category,
    required String color,
    required SeasonTag season,
    required StyleTag style,
    List<String> tags = const [],
    String? brand,
    String? notes,
    String? imagePath,
    bool? isFavorite,
  }) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    final saved = await _repository.updateItem(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
      item: item,
      name: name,
      imagePath: imagePath,
      category: category,
      color: color,
      season: season,
      style: style,
      tags: tags,
      brand: brand,
      notes: notes,
      isFavorite: isFavorite,
    );

    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      _items.insert(0, saved);
    } else {
      _items[index] = saved;
    }
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> toggleFavorite(WardrobeItem item) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    await _repository.toggleFavorite(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
      item: item,
    );
    await loadItems();
  }

  Future<void> deleteItem(String itemId) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    await _repository.deleteItem(
      firebaseEnabled: _authProvider.firebaseEnabled,
      userId: user.id,
      itemId: itemId,
    );
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setCategory(ClothingCategory? value) {
    selectedCategory = value;
    notifyListeners();
  }
}
