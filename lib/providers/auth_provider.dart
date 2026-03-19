import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import 'app_bootstrap_provider.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AppBootstrapProvider bootstrapProvider,
    required AuthRepository repository,
  })  : _bootstrapProvider = bootstrapProvider,
        _repository = repository;

  AppBootstrapProvider _bootstrapProvider;
  AuthRepository _repository;
  bool _bootstrappedInitializationComplete = false;

  AppUser? currentUser;
  bool isInitializing = true;
  bool isSubmitting = false;
  String? errorMessage;

  bool get firebaseEnabled => _bootstrapProvider.firebaseEnabled;

  void updateDependencies(
    AppBootstrapProvider bootstrapProvider,
    AuthRepository repository,
  ) {
    _bootstrapProvider = bootstrapProvider;
    _repository = repository;
    if (!bootstrapProvider.isInitializing &&
        !_bootstrappedInitializationComplete) {
      _bootstrappedInitializationComplete = true;
      initialize();
    }
  }

  Future<void> initialize() async {
    currentUser =
        await _repository.getCurrentUser(firebaseEnabled: firebaseEnabled);
    isInitializing = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _run(() async {
      currentUser = await _repository.signUp(
        firebaseEnabled: firebaseEnabled,
        email: email,
        password: password,
        displayName: displayName,
      );
    });
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _run(() async {
      currentUser = await _repository.login(
        firebaseEnabled: firebaseEnabled,
        email: email,
        password: password,
      );
    });
  }

  Future<void> logout() async {
    await _repository.logout(firebaseEnabled: firebaseEnabled);
    currentUser = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();
      await action();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
