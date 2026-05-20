import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  AuthRepository({required String baseUrl, required FlutterSecureStorage secureStorage})
      : _baseUrl = baseUrl,
        _storage = secureStorage,
        _dio = Dio(BaseOptions(baseUrl: baseUrl));

  final String _baseUrl;
  final FlutterSecureStorage _storage;
  final Dio _dio;

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyUser = 'user';
  static const _keySchoolId = 'school_id';

  Future<Map<String, dynamic>> loginPassword(String email, String password) async {
    final res = await _dio.post('$_baseUrl/auth/token/', data: {'email': email, 'password': password});
    final access = res.data['access'] as String;
    final refresh = res.data['refresh'] as String;
    final userRes = await _dio.get('$_baseUrl/auth/me/', options: Options(headers: {'Authorization': 'Bearer $access'}));
    final user = userRes.data as Map<String, dynamic>;
    return {'access': access, 'refresh': refresh, 'user': user};
  }

  Future<Map<String, dynamic>> loginOTP(String phone, String code, String schoolId) async {
    final res = await _dio.post('$_baseUrl/parent/verify-otp/', data: {'phone': phone, 'code': code, 'school_id': schoolId});
    return res.data as Map<String, dynamic>;
  }

  Future<void> storeTokens(String access, String refresh) async {
    await _storage.write(key: _keyAccess, value: access);
    await _storage.write(key: _keyRefresh, value: refresh);
  }

  Future<void> storeUser(Map<String, dynamic> user) async {
    await _storage.write(key: _keyUser, value: jsonEncode(user));
  }

  Future<void> storeSchoolId(String schoolId) async {
    await _storage.write(key: _keySchoolId, value: schoolId);
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    final s = await _storage.read(key: _keyUser);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  Future<String?> getStoredSchoolId() async => _storage.read(key: _keySchoolId);
  Future<String?> getStoredAccessToken() async => _storage.read(key: _keyAccess);

  Future<void> clearStorage() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keySchoolId);
  }
}
