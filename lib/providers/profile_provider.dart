import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import 'auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    required AuthProvider authProvider,
    required ProfileRepository repository,
  })  : _authProvider = authProvider,
        _repository = repository;

  AuthProvider _authProvider;
  ProfileRepository _repository;

  UserProfile? profile;
  bool isLoading = false;
  bool isSaving = false;

  void updateDependencies(
      AuthProvider authProvider, ProfileRepository repository) {
    final previousUserId = _authProvider.currentUser?.id;
    _authProvider = authProvider;
    _repository = repository;
    if (previousUserId != _authProvider.currentUser?.id) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    final user = _authProvider.currentUser;
    if (user == null) {
      profile = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    profile = await _repository.fetchProfile(user.id) ??
        UserProfile.fallback(
          userId: user.id,
          name: user.displayName,
          email: user.email,
        );
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfile({
    required UserProfile nextProfile,
    String? newImagePath,
    bool clearImage = false,
  }) async {
    isSaving = true;
    notifyListeners();
    profile = await _repository.saveProfile(
      profile: nextProfile,
      newImagePath: newImagePath,
      clearImage: clearImage,
    );
    isSaving = false;
    notifyListeners();
  }
}
