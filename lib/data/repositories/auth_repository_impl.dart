/// Implémentation du repository d'authentification
library;

import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    void Function(String)? onTokenUpdated,
  }) : _remote = remote,
       _local = local,
       _onTokenUpdated = onTokenUpdated;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final void Function(String)? _onTokenUpdated;

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final result = await _remote.login(username: username, password: password);
    await _local.setAccessToken(result.tokens.accessToken);
    await _local.setRefreshToken(result.tokens.refreshToken);
    if (result.user != null) await _local.setUser(result.user!);
    _onTokenUpdated?.call(result.tokens.accessToken);
    return AuthResult(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
      user:
          result.user?.toEntity() ??
          UserEntity(id: '', email: '', role: UserRole.parent),
    );
  }

  @override
  Future<void> logout() async {
    await _local.clearAll();
    _onTokenUpdated?.call('');
  }

  @override
  Future<AuthResult> refreshToken() async {
    final refresh = await _local.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw AuthException(message: 'Aucun refresh token');
    }
    final tokens = await _remote.refresh(refresh);
    await _local.setAccessToken(tokens.accessToken);
    await _local.setRefreshToken(tokens.refreshToken);
    _onTokenUpdated?.call(tokens.accessToken);
    final user = _local.getUser();
    if (user == null) throw AuthException(message: 'Utilisateur non trouvé');
    return AuthResult(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: user.toEntity(),
    );
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _local.getUser();
    return user?.toEntity();
  }

  @override
  Future<String?> getAccessToken() => _local.getAccessToken();

  @override
  Future<bool> isLoggedIn() async {
    final token = await _local.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
