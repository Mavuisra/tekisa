/// Contrat du repository d'authentification (domain)
library;

import '../entities/user_entity.dart';

/// Résultat de connexion / inscription
class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserEntity user;
}

/// Repository d'authentification : login Django (username/password), logout, session
abstract class AuthRepository {
  /// Connexion Django (username + mot de passe)
  Future<AuthResult> login({
    required String username,
    required String password,
  });

  /// Déconnexion et suppression du stockage local
  Future<void> logout();

  /// Rafraîchir le token (JWT)
  Future<AuthResult> refreshToken();

  /// Utilisateur courant (depuis cache local ou null si non connecté)
  Future<UserEntity?> getCurrentUser();

  /// Token d'accès (pour les appels API)
  Future<String?> getAccessToken();

  /// Vérifie si la session est valide (token non expiré)
  Future<bool> isLoggedIn();
}
