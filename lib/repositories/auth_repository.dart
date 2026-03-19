import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';

class AuthRepository {
  static const _legacyDemoUserKey = 'demo_user';
  static const _accountsKey = 'local_accounts';
  static const _currentUserIdKey = 'local_current_user_id';

  Future<AppUser?> getCurrentUser({required bool firebaseEnabled}) async {
    if (firebaseEnabled) {
      final user = firebase.FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'I Closet User',
        createdAt: DateTime.now(),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyDemoUser(prefs);

    final currentUserId = prefs.getString(_currentUserIdKey);
    if (currentUserId == null) {
      return null;
    }

    final account = (await _loadAccounts(prefs))
        .where((entry) => entry.user.id == currentUserId)
        .firstOrNull;
    return account?.user;
  }

  Future<AppUser> signUp({
    required bool firebaseEnabled,
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (firebaseEnabled) {
      try {
        final credential = await firebase.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await credential.user?.updateDisplayName(displayName);

        final user = credential.user;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }

        return AppUser(
          id: credential.user!.uid,
          email: credential.user!.email ?? email,
          displayName: displayName,
          createdAt: DateTime.now(),
        );
      } on firebase.FirebaseAuthException catch (error) {
        if (error.code == 'email-already-in-use') {
          throw Exception('auth_error_account_exists');
        }
        throw Exception('auth_error_generic');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyDemoUser(prefs);
    final accounts = await _loadAccounts(prefs);

    final emailExists = accounts
        .any((entry) => entry.user.email.toLowerCase() == email.toLowerCase());
    if (emailExists) {
      throw Exception('auth_error_account_exists');
    }

    final user = AppUser(
      id: const Uuid().v4(),
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    accounts.add(_LocalAccount(user: user, password: password));
    await _saveAccounts(prefs, accounts);
    await prefs.setString(_currentUserIdKey, user.id);
    return user;
  }

  Future<AppUser> login({
    required bool firebaseEnabled,
    required String email,
    required String password,
  }) async {
    if (firebaseEnabled) {
      try {
        final credential = await firebase.FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        return AppUser(
          id: credential.user!.uid,
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName ?? 'I Closet User',
          createdAt: DateTime.now(),
        );
      } on firebase.FirebaseAuthException catch (error) {
        if (error.code == 'user-not-found') {
          throw Exception('auth_error_no_account');
        }
        if (error.code == 'wrong-password' ||
            error.code == 'invalid-credential') {
          throw Exception('auth_error_password_mismatch');
        }
        throw Exception('auth_error_generic');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyDemoUser(prefs);
    final accounts = await _loadAccounts(prefs);

    final account = accounts
        .where((entry) => entry.user.email.toLowerCase() == email.toLowerCase())
        .firstOrNull;

    if (account == null) {
      throw Exception('auth_error_no_account');
    }

    if (account.password.isNotEmpty && account.password != password) {
      throw Exception('auth_error_password_mismatch');
    }

    await prefs.setString(_currentUserIdKey, account.user.id);
    return account.user;
  }

  Future<void> logout({required bool firebaseEnabled}) async {
    if (firebaseEnabled) {
      await firebase.FirebaseAuth.instance.signOut();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  Future<void> _migrateLegacyDemoUser(SharedPreferences prefs) async {
    if (prefs.getString(_legacyDemoUserKey) == null) {
      return;
    }

    final existingAccounts = await _loadAccounts(prefs);
    if (existingAccounts.isNotEmpty) {
      await prefs.remove(_legacyDemoUserKey);
      return;
    }

    final user = AppUser.fromMap(
      jsonDecode(prefs.getString(_legacyDemoUserKey)!) as Map<String, dynamic>,
    );

    final migrated = _LocalAccount(user: user, password: '');
    await _saveAccounts(prefs, [migrated]);
    await prefs.setString(_currentUserIdKey, user.id);
    await prefs.remove(_legacyDemoUserKey);
  }

  Future<List<_LocalAccount>> _loadAccounts(SharedPreferences prefs) async {
    final raw = prefs.getString(_accountsKey);
    if (raw == null) {
      return [];
    }

    final data =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
    return data.map(_LocalAccount.fromMap).toList();
  }

  Future<void> _saveAccounts(
    SharedPreferences prefs,
    List<_LocalAccount> accounts,
  ) async {
    await prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((entry) => entry.toMap()).toList()),
    );
  }
}

class _LocalAccount {
  const _LocalAccount({
    required this.user,
    required this.password,
  });

  final AppUser user;
  final String password;

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'password': password,
    };
  }

  factory _LocalAccount.fromMap(Map<String, dynamic> map) {
    return _LocalAccount(
      user: AppUser.fromMap(map['user'] as Map<String, dynamic>),
      password: map['password'] as String? ?? '',
    );
  }
}
