import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/outfit_look.dart';

class OutfitRepository {
  Future<List<OutfitLook>> fetchOutfits({
    required bool firebaseEnabled,
    required String userId,
  }) async {
    if (firebaseEnabled) {
      final snapshot = await FirebaseFirestore.instance
          .collection('outfitLooks')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => OutfitLook.fromMap(doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('outfits_$userId');
    if (raw == null) {
      return [];
    }

    final data =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
    return data.map(OutfitLook.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<OutfitLook>> fetchGeneratedLooks(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('generated_outfits_$userId');
    if (raw == null) {
      return [];
    }

    final data =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
    return data.map(OutfitLook.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> cacheGeneratedLooks({
    required String userId,
    required List<OutfitLook> looks,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'generated_outfits_$userId',
      jsonEncode(looks.map((entry) => entry.toMap()).toList()),
    );
  }

  Future<OutfitLook> saveOutfit({
    required bool firebaseEnabled,
    required String userId,
    required String title,
    required List<String> itemIds,
    required String occasion,
    required String style,
    required String notes,
    List<String> tags = const [],
    String? weatherContext,
    String? existingId,
    bool isFavorite = false,
    bool isGenerated = false,
    bool isPremium = false,
  }) async {
    final outfit = OutfitLook(
      id: existingId ?? const Uuid().v4(),
      userId: userId,
      title: title,
      itemIds: itemIds,
      occasion: occasion,
      style: style,
      notes: notes,
      tags: tags,
      weatherContext: weatherContext,
      isFavorite: isFavorite,
      isGenerated: isGenerated,
      isPremium: isPremium,
      createdAt: DateTime.now(),
    );

    if (firebaseEnabled) {
      await FirebaseFirestore.instance
          .collection('outfitLooks')
          .doc(outfit.id)
          .set(outfit.toMap());
      return outfit;
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchOutfits(firebaseEnabled: false, userId: userId);
    final next = [outfit, ...existing.where((entry) => entry.id != outfit.id)];
    await prefs.setString(
      'outfits_$userId',
      jsonEncode(next.map((entry) => entry.toMap()).toList()),
    );
    return outfit;
  }

  Future<void> deleteOutfit({
    required bool firebaseEnabled,
    required String userId,
    required String outfitId,
  }) async {
    if (firebaseEnabled) {
      await FirebaseFirestore.instance
          .collection('outfitLooks')
          .doc(outfitId)
          .delete();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchOutfits(firebaseEnabled: false, userId: userId);
    final next = existing.where((entry) => entry.id != outfitId).toList();
    await prefs.setString(
      'outfits_$userId',
      jsonEncode(next.map((entry) => entry.toMap()).toList()),
    );
  }

  Future<void> toggleFavorite({
    required bool firebaseEnabled,
    required String userId,
    required OutfitLook outfit,
  }) async {
    await saveOutfit(
      firebaseEnabled: firebaseEnabled,
      userId: userId,
      title: outfit.title,
      itemIds: outfit.itemIds,
      occasion: outfit.occasion,
      style: outfit.style,
      notes: outfit.notes,
      tags: outfit.tags,
      weatherContext: outfit.weatherContext,
      existingId: outfit.id,
      isFavorite: !outfit.isFavorite,
      isGenerated: outfit.isGenerated,
      isPremium: outfit.isPremium,
    );
  }
}
