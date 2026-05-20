/// Modèle tokens JWT (réponse login/register)
library;

class AuthTokensModel {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int? expiresIn;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken:
          json['access'] as String? ??
          json['access_token'] as String? ??
          json['accessToken'] as String? ??
          '',
      refreshToken:
          json['refresh'] as String? ??
          json['refresh_token'] as String? ??
          json['refreshToken'] as String? ??
          '',
      expiresIn: json['expires_in'] as int? ?? json['expiresIn'] as int?,
    );
  }
}
