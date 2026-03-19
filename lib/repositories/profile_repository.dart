import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/local_image_storage_service.dart';

class ProfileRepository {
  ProfileRepository() : _imageStorageService = LocalImageStorageService();

  final LocalImageStorageService _imageStorageService;

  Future<UserProfile?> fetchProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('profile_$userId');
    if (raw == null) {
      return null;
    }

    return UserProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<UserProfile> saveProfile({
    required UserProfile profile,
    String? newImagePath,
    bool clearImage = false,
  }) async {
    var savedProfile = profile.copyWith(updatedAt: DateTime.now());

    if (clearImage) {
      if ((savedProfile.profilePhotoPath ?? '').isNotEmpty) {
        await _imageStorageService
            .deleteIfOwned(savedProfile.profilePhotoPath!);
      }
      savedProfile = savedProfile.copyWith(clearProfilePhoto: true);
    } else if (newImagePath != null &&
        newImagePath.isNotEmpty &&
        newImagePath != profile.profilePhotoPath) {
      final storedImagePath = await _imageStorageService.persistImage(
        scope: 'profile_images',
        userId: profile.userId,
        entryId: 'avatar',
        sourcePath: newImagePath,
      );
      savedProfile = savedProfile.copyWith(profilePhotoPath: storedImagePath);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'profile_${profile.userId}', jsonEncode(savedProfile.toMap()));
    return savedProfile;
  }
}
