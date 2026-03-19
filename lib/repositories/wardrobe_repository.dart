import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/app_assets.dart';
import '../core/app_enums.dart';
import '../models/wardrobe_item.dart';
import '../services/local_image_storage_service.dart';

class WardrobeRepository {
  WardrobeRepository() : _imageStorageService = LocalImageStorageService();

  static const _uuid = Uuid();
  final LocalImageStorageService _imageStorageService;

  Future<List<WardrobeItem>> fetchItems({
    required bool firebaseEnabled,
    required String userId,
  }) async {
    if (firebaseEnabled) {
      final collection = FirebaseFirestore.instance.collection('wardrobeItems');
      final snapshot =
          await collection.where('userId', isEqualTo: userId).get();
      final items = snapshot.docs
          .map((doc) => WardrobeItem.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (items.isEmpty || _looksLikeLegacyDemoSet(items)) {
        final demoItems = _demoItems(userId);
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        for (final item in demoItems) {
          batch.set(collection.doc(item.id), item.toMap());
        }
        await batch.commit();
        return demoItems;
      }

      return items;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wardrobe_$userId');
    if (raw == null) {
      final demoItems = _demoItems(userId);
      await prefs.setString(
        'wardrobe_$userId',
        jsonEncode(demoItems.map((entry) => entry.toMap()).toList()),
      );
      return demoItems;
    }

    final data =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
    final items = data.map(WardrobeItem.fromMap).toList();
    if (_looksLikeLegacyDemoSet(items)) {
      final demoItems = _demoItems(userId);
      await prefs.setString(
        'wardrobe_$userId',
        jsonEncode(demoItems.map((entry) => entry.toMap()).toList()),
      );
      return demoItems;
    }

    return items..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<WardrobeItem> addItem({
    required bool firebaseEnabled,
    required String userId,
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
    final baseItem = WardrobeItem(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      imageUrl: '',
      category: category,
      color: color,
      season: season,
      style: style,
      tags: tags,
      brand: brand,
      notes: notes,
      isFavorite: isFavorite,
      createdAt: DateTime.now(),
    );

    final storedImagePath = await _imageStorageService.persistImage(
      scope: 'wardrobe_images',
      userId: userId,
      entryId: baseItem.id,
      sourcePath: imagePath,
    );

    final savedItem = baseItem.copyWith(
      imageUrl: firebaseEnabled
          ? await _uploadImage(userId, baseItem.id, storedImagePath)
          : storedImagePath,
    );

    if (firebaseEnabled) {
      await FirebaseFirestore.instance
          .collection('wardrobeItems')
          .doc(savedItem.id)
          .set(savedItem.toMap());
      return savedItem;
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchItems(firebaseEnabled: false, userId: userId);
    await prefs.setString(
      'wardrobe_$userId',
      jsonEncode(
          [savedItem, ...existing].map((entry) => entry.toMap()).toList()),
    );
    return savedItem;
  }

  Future<WardrobeItem> updateItem({
    required bool firebaseEnabled,
    required String userId,
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
    var updated = item.copyWith(
      name: name,
      category: category,
      color: color,
      season: season,
      style: style,
      tags: tags,
      brand: brand,
      notes: notes,
      isFavorite: isFavorite ?? item.isFavorite,
    );

    if (imagePath != null &&
        imagePath.isNotEmpty &&
        imagePath != item.imageUrl) {
      final storedImagePath = await _imageStorageService.persistImage(
        scope: 'wardrobe_images',
        userId: userId,
        entryId: item.id,
        sourcePath: imagePath,
      );
      updated = updated.copyWith(
        imageUrl: firebaseEnabled
            ? await _uploadImage(userId, item.id, storedImagePath)
            : storedImagePath,
      );
    }

    if (firebaseEnabled) {
      await FirebaseFirestore.instance
          .collection('wardrobeItems')
          .doc(updated.id)
          .set(updated.toMap());
      return updated;
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchItems(firebaseEnabled: false, userId: userId);
    final next = [
      updated,
      ...existing.where((entry) => entry.id != updated.id),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await prefs.setString(
      'wardrobe_$userId',
      jsonEncode(next.map((entry) => entry.toMap()).toList()),
    );
    return updated;
  }

  Future<void> toggleFavorite({
    required bool firebaseEnabled,
    required String userId,
    required WardrobeItem item,
  }) async {
    final updated = item.copyWith(isFavorite: !item.isFavorite);

    if (firebaseEnabled) {
      await FirebaseFirestore.instance
          .collection('wardrobeItems')
          .doc(item.id)
          .update({
        'isFavorite': updated.isFavorite,
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchItems(firebaseEnabled: false, userId: userId);
    final next =
        existing.map((entry) => entry.id == item.id ? updated : entry).toList();
    await prefs.setString(
      'wardrobe_$userId',
      jsonEncode(next.map((entry) => entry.toMap()).toList()),
    );
  }

  Future<void> deleteItem({
    required bool firebaseEnabled,
    required String userId,
    required String itemId,
  }) async {
    final existing =
        await fetchItems(firebaseEnabled: firebaseEnabled, userId: userId);
    final item = existing.where((entry) => entry.id == itemId).firstOrNull;

    if (firebaseEnabled) {
      await FirebaseFirestore.instance
          .collection('wardrobeItems')
          .doc(itemId)
          .delete();
      await FirebaseStorage.instance
          .ref('users/$userId/wardrobe/$itemId.jpg')
          .delete()
          .catchError((_) {});
      if (item != null) {
        await _imageStorageService.deleteIfOwned(item.imageUrl);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final next = existing.where((entry) => entry.id != itemId).toList();
    await prefs.setString(
      'wardrobe_$userId',
      jsonEncode(next.map((entry) => entry.toMap()).toList()),
    );
    if (item != null) {
      await _imageStorageService.deleteIfOwned(item.imageUrl);
    }
  }

  Future<String> _uploadImage(
      String userId, String itemId, String imagePath) async {
    final ref =
        FirebaseStorage.instance.ref('users/$userId/wardrobe/$itemId.jpg');
    await ref.putFile(File(imagePath));
    return ref.getDownloadURL();
  }

  bool _looksLikeLegacyDemoSet(List<WardrobeItem> items) {
    const legacyDemoNames = {
      'Soft Navy Knit Top',
      'Cool Gray Wide-Leg Pants',
      'Muted Blue Cropped Jacket',
      'Warm White Midi Dress',
      'White Leather Sneakers',
      'Powder Blue Mini Bag',
    };
    if (items.isEmpty || items.length > legacyDemoNames.length + 1) {
      return false;
    }

    return items.every(
        (item) => item.imageUrl.isEmpty && legacyDemoNames.contains(item.name));
  }

  List<WardrobeItem> _demoItems(String userId) {
    final now = DateTime.now();
    return [
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Ivory Soft Blazer',
        imageUrl: AppAssets.ivoryBlazer,
        category: ClothingCategory.outerwear,
        color: 'Warm Ivory',
        season: SeasonTag.allSeason,
        style: StyleTag.smartCasual,
        tags: const ['work', 'meeting', 'smart casual'],
        brand: 'Studio Edit',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Jet Black Fitted Top',
        imageUrl: AppAssets.blackFittedTop,
        category: ClothingCategory.tops,
        color: 'Jet Black',
        season: SeasonTag.summer,
        style: StyleTag.chic,
        tags: const ['date', 'night out'],
        brand: 'City Line',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'White Weekend Tee',
        imageUrl: AppAssets.weekendTee,
        category: ClothingCategory.tops,
        color: 'Soft White',
        season: SeasonTag.summer,
        style: StyleTag.casual,
        tags: const ['college', 'weekend', 'casual'],
        brand: 'Jordan',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'White Tailored Pants',
        imageUrl: AppAssets.whiteTailoredPants,
        category: ClothingCategory.bottoms,
        color: 'White',
        season: SeasonTag.allSeason,
        style: StyleTag.minimal,
        tags: const ['work', 'clean look'],
        brand: 'Soft Studio',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Charcoal Column Trousers',
        imageUrl: AppAssets.charcoalTrousers,
        category: ClothingCategory.bottoms,
        color: 'Charcoal',
        season: SeasonTag.allSeason,
        style: StyleTag.chic,
        tags: const ['meeting', 'date', 'evening'],
        brand: 'Paris Week',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'City Leather Jacket',
        imageUrl: AppAssets.cityLeatherJacket,
        category: ClothingCategory.outerwear,
        color: 'Black',
        season: SeasonTag.autumn,
        style: StyleTag.streetwear,
        tags: const ['weekend', 'travel', 'layering'],
        brand: 'Street Atelier',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Sculptural Taupe Jacket',
        imageUrl: AppAssets.sculpturalJacket,
        category: ClothingCategory.outerwear,
        color: 'Taupe',
        season: SeasonTag.spring,
        style: StyleTag.chic,
        tags: const ['editorial', 'statement'],
        brand: 'Archive Edit',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Emerald Statement Dress',
        imageUrl: AppAssets.emeraldDress,
        category: ClothingCategory.dresses,
        color: 'Emerald',
        season: SeasonTag.summer,
        style: StyleTag.chic,
        tags: const ['date', 'party', 'event'],
        brand: 'Evening Muse',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'White Platform Sneakers',
        imageUrl: AppAssets.whiteSneakers,
        category: ClothingCategory.shoes,
        color: 'White',
        season: SeasonTag.allSeason,
        style: StyleTag.casual,
        tags: const ['college', 'travel', 'rainy day'],
        brand: 'Super Step',
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Olive Mini Kelly Bag',
        imageUrl: AppAssets.oliveBag,
        category: ClothingCategory.bags,
        color: 'Olive',
        season: SeasonTag.allSeason,
        style: StyleTag.chic,
        tags: const ['dinner', 'meeting', 'premium'],
        brand: 'Heritage House',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Minimal Black Sunglasses',
        imageUrl: AppAssets.blackSunglasses,
        category: ClothingCategory.accessories,
        color: 'Black',
        season: SeasonTag.summer,
        style: StyleTag.minimal,
        tags: const ['sunny', 'travel', 'weekend'],
        brand: 'Sunline',
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Gold Chain Necklace',
        imageUrl: AppAssets.goldNecklace,
        category: ClothingCategory.accessories,
        color: 'Gold',
        season: SeasonTag.allSeason,
        style: StyleTag.chic,
        tags: const ['date', 'event', 'premium'],
        brand: 'Atelier Gold',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Tailored Camel Blazer',
        imageUrl: AppAssets.partnerBlazer,
        category: ClothingCategory.outerwear,
        color: 'Camel',
        season: SeasonTag.allSeason,
        style: StyleTag.formal,
        tags: const ['work', 'meeting', 'formal'],
        brand: 'COS',
        createdAt: now.subtract(const Duration(days: 13)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Soft Satin Slip Dress',
        imageUrl: AppAssets.partnerDress,
        category: ClothingCategory.dresses,
        color: 'Blush',
        season: SeasonTag.summer,
        style: StyleTag.chic,
        tags: const ['date', 'dinner', 'formal'],
        brand: 'Reformation',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Studio Mini Bag',
        imageUrl: AppAssets.partnerBag,
        category: ClothingCategory.bags,
        color: 'Black',
        season: SeasonTag.allSeason,
        style: StyleTag.minimal,
        tags: const ['work', 'weekend', 'minimal'],
        brand: 'Charles & Keith',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Rain-Ready Sneakers',
        imageUrl: AppAssets.partnerSneakers,
        category: ClothingCategory.shoes,
        color: 'White',
        season: SeasonTag.allSeason,
        style: StyleTag.streetwear,
        tags: const ['rainy day', 'sporty', 'travel'],
        brand: 'Veja',
        createdAt: now.subtract(const Duration(days: 16)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Everyday Gold Necklace',
        imageUrl: AppAssets.partnerNecklace,
        category: ClothingCategory.accessories,
        color: 'Gold',
        season: SeasonTag.allSeason,
        style: StyleTag.chic,
        tags: const ['minimal', 'event', 'premium'],
        brand: 'Mejuri',
        createdAt: now.subtract(const Duration(days: 17)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Utility Layer Jacket',
        imageUrl: AppAssets.partnerLayer,
        category: ClothingCategory.outerwear,
        color: 'Olive',
        season: SeasonTag.autumn,
        style: StyleTag.casual,
        tags: const ['travel', 'cozy', 'layering'],
        brand: 'Massimo Dutti',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Everyday Cotton Shirt',
        imageUrl: AppAssets.partnerTop,
        category: ClothingCategory.tops,
        color: 'Warm White',
        season: SeasonTag.spring,
        style: StyleTag.smartCasual,
        tags: const ['smart casual', 'minimal', 'weekend'],
        brand: 'Everlane',
        createdAt: now.subtract(const Duration(days: 19)),
      ),
      WardrobeItem(
        id: _uuid.v4(),
        userId: userId,
        name: 'Breathable Linen Trousers',
        imageUrl: AppAssets.partnerTrousers,
        category: ClothingCategory.bottoms,
        color: 'Warm White',
        season: SeasonTag.summer,
        style: StyleTag.minimal,
        tags: const ['hot weather', 'minimal', 'cozy'],
        brand: 'Linen House',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    ];
  }
}
