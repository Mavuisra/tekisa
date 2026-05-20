/// Source de données authentification (stockage local sécurisé)
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../datasources/local_auth_datasource.dart';
import '../models/user_model.dart';

/// Stockage sécurisé : JWT + données utilisateur (Hive + FlutterSecureStorage)
class AuthLocalDataSource {
  AuthLocalDataSource({
    FlutterSecureStorage? secureStorage,
    Box<String>? userBox,
  }) : _secure =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock,
             ),
           ),
       _userBox =
           userBox ??
           (Hive.isBoxOpen(StorageKeys.userBox)
               ? Hive.box<String>(StorageKeys.userBox)
               : null);

  final FlutterSecureStorage _secure;
  final Box<String>? _userBox;
  final LocalAuthDataSource _localAuth = LocalAuthDataSource();

  /// Token d'accès (sensible) → secure storage
  Future<void> setAccessToken(String token) =>
      _secure.write(key: StorageKeys.accessToken, value: token);
  Future<String?> getAccessToken() =>
      _secure.read(key: StorageKeys.accessToken);
  Future<void> deleteAccessToken() =>
      _secure.delete(key: StorageKeys.accessToken);

  Future<void> setRefreshToken(String token) =>
      _secure.write(key: StorageKeys.refreshToken, value: token);
  Future<String?> getRefreshToken() =>
      _secure.read(key: StorageKeys.refreshToken);
  Future<void> deleteRefreshToken() =>
      _secure.delete(key: StorageKeys.refreshToken);

  /// Utilisateur (cache) → Hive (JSON string)
  Future<void> setUser(UserModel user) async {
    _userBox?.put(StorageKeys.userData, jsonEncode(user.toJson()));
    try {
      await _localAuth.updateUserSnapshot(user);
    } catch (_) {
      // Le cache principal ne doit pas échouer à cause d'une synchro snapshot.
    }
  }

  UserModel? getUser() {
    final raw = _userBox?.get(StorageKeys.userData);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    _userBox?.delete(StorageKeys.userData);
  }

  /// Nettoyage complet (logout)
  Future<void> clearAll() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    clearUser();
  }
}
