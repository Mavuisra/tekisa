import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/env_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/local_db.dart';
import '../../data/repositories/auth_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(
    baseUrl: EnvConfig.apiBaseUrl,
    secureStorage: storage,
  );
});

class AuthState {
  const AuthState({this.user, this.schoolId, this.accessToken, this.isLoading = false});
  final Map<String, dynamic>? user;
  final String? schoolId;
  final String? accessToken;
  final bool isLoading;
  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState(isLoading: true)) {
    _loadStored();
  }
  final AuthRepository _repo;

  Future<void> _loadStored() async {
    final user = await _repo.getStoredUser();
    final schoolId = await _repo.getStoredSchoolId();
    final token = await _repo.getStoredAccessToken();
    state = AuthState(user: user, schoolId: schoolId, accessToken: token, isLoading: false);
  }

  Future<bool> loginWithPassword(String email, String password, String schoolId) async {
    state = AuthState(user: state.user, schoolId: state.schoolId, accessToken: state.accessToken, isLoading: true);
    try {
      final res = await _repo.loginPassword(email, password);
      await _repo.storeTokens(res['access'] as String, res['refresh'] as String);
      await _repo.storeUser(res['user'] as Map<String, dynamic>);
      await _repo.storeSchoolId(schoolId);
      final access = res['access'] as String;
      state = AuthState(user: res['user'] as Map<String, dynamic>, schoolId: schoolId, accessToken: access, isLoading: false);
      return true;
    } catch (_) {
      state = AuthState(user: state.user, schoolId: state.schoolId, accessToken: state.accessToken, isLoading: false);
      return false;
    }
  }

  Future<bool> loginWithOTP(String phone, String code, String schoolId) async {
    state = AuthState(user: state.user, schoolId: state.schoolId, isLoading: true);
    try {
      final res = await _repo.loginOTP(phone, code, schoolId);
      await _repo.storeTokens(res['access'] as String, res['refresh'] as String);
      await _repo.storeUser(res['user'] as Map<String, dynamic>);
      await _repo.storeSchoolId(schoolId);
      final access = res['access'] as String;
      state = AuthState(user: res['user'] as Map<String, dynamic>, schoolId: schoolId, accessToken: access, isLoading: false);
      return true;
    } catch (_) {
      state = AuthState(user: state.user, schoolId: state.schoolId, accessToken: state.accessToken, isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.clearStorage();
    state = const AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final dioClientProvider = Provider<DioClient>((ref) {
  final auth = ref.watch(authNotifierProvider);
  return DioClient(baseUrl: EnvConfig.apiBaseUrl, accessToken: auth.accessToken);
});
